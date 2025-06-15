#!/bin/bash
set -euo pipefail

# --- Configuration Loading ---

# Function to load a value from config.toml under the [screen_recorder] section
load_config() {
    local key="$1"
    local SCRIPT_DIR
    SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
    local ROOT_DIR
    ROOT_DIR=$(realpath "$SCRIPT_DIR/..")
    local CONFIG_FILE="$ROOT_DIR/config.toml"

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Configuration file not found at $CONFIG_FILE" >&2
        exit 1
    fi

    # Use awk for robust parsing: find [screen_recorder] section, then find the key.
    local value
    value=$(awk -F'=' '/^\[screen_recorder\]/{in_section=1} /^\[/{if(!/^\[screen_recorder\]/) in_section=0} in_section && /^\s*'"$key"'\s*=/{gsub(/[ \t"]/, "", $2); print $2; exit}' "$CONFIG_FILE")

    if [ -z "$value" ]; then
        echo "Error: Key '$key' not found under [screen_recorder] section in $CONFIG_FILE" >&2
        exit 1
    fi

    # Manually expand the tilde (~) to the user's home directory.
    value="${value/\~/$HOME}"
    
    echo "$value"
}

# Load configuration into variables
OUTPUT_DIR=$(load_config "output_directory")
FRAMERATE=$(load_config "framerate")
DISPLAY=$(load_config "display")
AUDIO_SOURCE=$(load_config "audio_source")
VIDEO_PRESET=$(load_config "video_preset")
CRF=$(load_config "crf")
AUDIO_BITRATE=$(load_config "audio_bitrate")

# --- Main Logic ---

# Ensure the output directory exists
mkdir -p "$OUTPUT_DIR"

# Generate a timestamped filename
FILENAME="recording_$(date "+%Y-%m-%d_%H-%M-%S").mp4"
OUTPUT_FILE="$OUTPUT_DIR/$FILENAME"

echo "Starting screen recording..."
echo "Display:      $DISPLAY"
echo "Audio Source: $AUDIO_SOURCE"
echo "Output File:  $OUTPUT_FILE"
echo "Press Ctrl+C to stop."

# Execute the ffmpeg command with loaded configuration
ffmpeg -f x11grab -framerate "$FRAMERATE" -i "$DISPLAY" \
       -f pulse -i "$AUDIO_SOURCE" \
       -c:v libx264 -preset "$VIDEO_PRESET" -crf "$CRF" \
       -c:a aac -b:a "$AUDIO_BITRATE" \
       "$OUTPUT_FILE"

echo "Recording saved to $OUTPUT_FILE"
