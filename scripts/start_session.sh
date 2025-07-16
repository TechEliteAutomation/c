#!/bin/bash
set -euo pipefail

# --- Configuration ---
OUTPUT_DIR="/home/u/0"
MIC_SOURCE="alsa_input.pci-0000_03_00.6.analog-stereo"
PYTHON_CMD="/home/u/c/experimental/.venv/bin/python /home/u/c/experimental/voice_commander.py"

# --- Main Logic ---
mkdir -p "$OUTPUT_DIR"
FILENAME="session_$(date "+%Y-%m-%d_%H-%M-%S").mp4"
OUTPUT_FILE="$OUTPUT_DIR/$FILENAME"

trap 'kill $(jobs -p) 2>/dev/null' SIGINT SIGTERM

echo "Starting unified session..."
echo "Recording screen and mic to: $OUTPUT_FILE"
echo "Voice commands are active. Press Ctrl+C to end."
echo "----------------------------------------------------"

# CORRECTED FFMPEG COMMAND:
# The key change is the format of the tee argument.
# We now use two separate mapping flags. One for the file, one for the pipe.
ffmpeg \
    -loglevel error \
    -f x11grab -framerate 30 -video_size 1920x1080 -i :0.0 \
    -f pulse -i "$MIC_SOURCE" \
    -f tee \
    -map 0:v -map 1:a -c:v libx264 -preset ultrafast -c:a aac -b:a 128k "'$OUTPUT_FILE'" \
    -map 1:a -f s16le -ar 16000 -ac 1 "pipe:1" | $PYTHON_CMD

echo "----------------------------------------------------"
echo "Session ended. Recording saved."
