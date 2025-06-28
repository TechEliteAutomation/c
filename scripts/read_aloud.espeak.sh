#!/bin/bash

# ==============================================================================
# read-aloud-espeak.sh
#
# A script to read a Markdown file aloud using pandoc and espeak-ng.
# It interactively prompts the user for the file, speech speed, and start line.
#
# Dependencies:
#   - pandoc: For converting Markdown to plain text.
#   - espeak-ng: For speech synthesis and playback.
# ==============================================================================

# --- CONFIGURATION ---
# You can set a default voice for espeak-ng.
# To see available voices, run: espeak-ng --voices
#ESPEAK_VOICE="en-us" #English male
#ESPEAK_VOICE="en-us-nyc" #English male from NYC (funny)
#ESPEAK_VOICE="en+m5" #English male
ESPEAK_VOICE="en+f3" #English female

# --- COLORS (for pretty output) ---
C_BLUE=$(tput setaf 4)
C_GREEN=$(tput setaf 2)
C_RED=$(tput setaf 1)
C_BOLD=$(tput bold)
C_RESET=$(tput sgr0)

# --- DEPENDENCY CHECK ---
# Check if all required programs are installed before we start.
for cmd in pandoc espeak-ng tail; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "${C_RED}${C_BOLD}Error: Required command '$cmd' is not installed.${C_RESET}"
        echo "Please install it and try again."
        exit 1
    fi
done

# --- USER PROMPTS ---
echo "${C_BLUE}${C_BOLD}--- Text-to-Speech Launcher (eSpeak Edition) ---${C_RESET}"

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

# 2. Prompt for the speech speed (Words Per Minute).
read -p "Enter speech speed in Words Per Minute (e.g., 130-200) [default: 160]: " SPEECH_SPEED
# If the user just presses Enter, default to 160.
SPEECH_SPEED=${SPEECH_SPEED:-160}

# 3. Prompt for the starting line number.
read -p "Enter line number to start from [default: 1]: " START_LINE
# If the user just presses Enter, default to 1.
START_LINE=${START_LINE:-1}

# --- EXECUTION ---
echo
echo "${C_GREEN}Configuration complete. Preparing to read...${C_RESET}"
echo "  ${C_BOLD}File:${C_RESET}  $FILE_PATH"
echo "  ${C_BOLD}Speed:${C_RESET} $SPEECH_SPEED WPM"
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

# Stage 2: Convert to text.
PANDOC_CMD="pandoc -t plain"

# Stage 3: Synthesize and play audio with espeak-ng.
# The '--stdin' flag tells espeak-ng to read the text from the pipeline.
ESPEAK_CMD="espeak-ng -v \"$ESPEAK_VOICE\" -s $SPEECH_SPEED --stdin"

# Execute the full pipeline.
# We use 'eval' here to correctly handle the command string with pipes.
eval "$INPUT_CMD | $PANDOC_CMD | $ESPEAK_CMD"

echo
echo "${C_GREEN}${C_BOLD}Playback finished.${C_RESET}"
