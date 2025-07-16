#!/bin/bash
set -euo pipefail

echo "Starting recording and voice command session..."

# 1. Start the screen recorder in the background.
# It will use the microphone configuration from config.toml.
# We redirect its output to a log file to keep the terminal clean.
./record_screen.sh > /tmp/screen_recorder.log 2>&1 &
RECORDER_PID=$!
echo "Screen recorder started in background (PID: $RECORDER_PID)."

# 2. Define the audio source for the voice commander.
# This should be your REAL microphone source name.
MIC_SOURCE="alsa_input.pci-0000_03_00.6.analog-stereo"

# 3. Create the ffmpeg -> python pipeline.
# This command runs in the foreground. When you press Ctrl+C, it will stop.
echo "Starting voice commander pipeline. Press Ctrl+C here to end the session."

# Explanation of ffmpeg flags:
# -f pulse -i "$MIC_SOURCE":  Capture from the real mic via PulseAudio.
# -ar 16000:                  Resample audio to the 16kHz Vosk needs.
# -ac 1:                      Convert to mono.
# -f s16le:                   Output raw 16-bit signed little-endian PCM audio.
# -:                           Pipe output to stdout.
ffmpeg -loglevel quiet -f pulse -i "$MIC_SOURCE" -ar 16000 -ac 1 -f s16le - | \
    /home/u/c/experimental/.venv/bin/python /home/u/c/experimental/voice_commander.py

# 4. Cleanup
# This part runs after you press Ctrl+C in the pipeline.
echo "Voice commander stopped. Stopping screen recorder..."
kill "$RECORDER_PID"
echo "Session ended."
