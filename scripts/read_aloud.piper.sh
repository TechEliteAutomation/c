#!/bin/bash

# ==============================================================================
# read_aloud.sh
#
# A script to read a Markdown file aloud using pandoc, piper-tts, and mpv.
# It interactively prompts the user for the file, speech rate, and start line.
#
# Dependencies:
#   - pandoc: For converting Markdown to plain text.
#   - piper-tts: The AUR version, for speech synthesis.
#   - mpv: For audio playback.
#
# Usage:
#   1. Save this file as 'read-aloud.sh'.
#   2. Make it executable: chmod +x read-aloud.sh
#   3. Run it: ./read-aloud.sh
# ==============================================================================

# --- CONFIGURATION ---

# Set the full path to your voice model file here for easy editing.
VOICE_MODEL="/home/u/c/speech_models/voices/en_US-hfc_male-medium.onnx"
#VOICE_MODEL="/home/u/c/speech_models/voices/en_GB-alan-medium.onnx"
#VOICE_MODEL="/home/u/c/speech_models/voices/en_GB-northern_english_male-medium.onnx"
#VOICE_MODEL="/home/u/c/speech_models/voices/en_GB-aru-medium.onnx"

# Set the audio format for your model.
SAMPLE_RATE="22050"
AUDIO_FORMAT="s16"
CHANNELS="1"

# --- COLORS (for pretty output) ---
C_BLUE=$(tput setaf 4)
C_GREEN=$(tput setaf 2)
C_RED=$(tput setaf 1)
C_BOLD=$(tput bold)
C_RESET=$(tput sgr0)

# --- DEPENDENCY CHECK ---
# Check if all required programs are installed before we start.
for cmd in pandoc piper-tts mpv tail; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "${C_RED}${C_BOLD}Error: Required command '$cmd' is not installed.${C_RESET}"
        echo "Please install it and try again."
        exit 1
    fi
done

# --- USER PROMPTS ---
echo "${C_BLUE}${C_BOLD}--- Text-to-Speech Launcher ---${C_RESET}"

# 1. Prompt for the file path.
read -p "Enter the path to the Markdown file: " FILE_PATH

# Validate that the file exists and is not empty.
if [ -z "$FILE_PATH" ]; then
    echo "${C_RED}Error: No file provided. Exiting.${C_RESET}"
    exit 1
fi
if [ ! -f "$FILE_PATH" ]; then
    echo "${C_RED}Error: File not found at '$FILE_PATH'. Exiting.${C_RESET}"
    exit 1
fi

# 2. Prompt for the speech rate.
read -p "Enter speech rate (e.g., 0.8 for faster, 1.2 for slower) [default: 1.0]: " SPEECH_RATE
# If the user just presses Enter, default to 1.0.
SPEECH_RATE=${SPEECH_RATE:-1.0}

# 3. Prompt for the starting line number.
read -p "Enter line number to start from [default: 1]: " START_LINE
# If the user just presses Enter, default to 1.
START_LINE=${START_LINE:-1}

# --- EXECUTION ---
echo
echo "${C_GREEN}Configuration complete. Preparing to read...${C_RESET}"
echo "  ${C_BOLD}File:${C_RESET}  $FILE_PATH"
echo "  ${C_BOLD}Speed:${C_RESET} $SPEECH_RATE"
echo "  ${C_BOLD}Start:${C_RESET} Line $START_LINE"
echo

# The core pipeline logic.
# We build the command in stages to handle the optional 'tail' command.

# Stage 1: Select the lines from the file.
# If the start line is greater than 1, use 'tail'. Otherwise, just use 'cat'.
if [ "$START_LINE" -gt 1 ]; then
    INPUT_CMD="tail -n +$START_LINE \"$FILE_PATH\""
else
    INPUT_CMD="cat \"$FILE_PATH\""
fi

# Stage 2 & 3: Convert to text and synthesize speech.
PANDOC_CMD="pandoc -t plain"
PIPER_CMD="piper-tts --model \"$VOICE_MODEL\" --length_scale $SPEECH_RATE --output-raw"

# Stage 4: Play the audio with mpv.
MPV_CMD="mpv --demuxer=rawaudio --demuxer-rawaudio-rate=$SAMPLE_RATE --demuxer-rawaudio-format=$AUDIO_FORMAT --demuxer-rawaudio-channels=$CHANNELS -"

# Execute the full pipeline.
# We use 'eval' here to correctly handle the command string with pipes.
eval "$INPUT_CMD | $PANDOC_CMD | $PIPER_CMD | $MPV_CMD"

echo
echo "${C_GREEN}${C_BOLD}Playback finished.${C_RESET}"
