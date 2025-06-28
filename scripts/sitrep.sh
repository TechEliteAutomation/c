#!/bin/bash

# ==============================================================================
# sitrep.sh
#
# A comprehensive startup greeting and situation report.
#
# Dependencies:
#   - espeak-ng: For speech synthesis.
#   - curl: For fetching weather data.
#   - pacman-contrib: For the 'checkupdates' utility (optional).
# ==============================================================================

# --- CONFIGURATION ---
LOCATION="NewYork" # Replace with your city/ZIP for accurate weather, or leave blank for auto-detection.
ESPEAK_VOICE="en+m3" # A deeper, more commanding male voice.
ESPEAK_SPEED="150"   # Words per minute.

# --- GREETING SELECTION ---
# The script will randomly choose one of these greetings.
GREETINGS=(
    "Greetings, my master."
    "Greetings, Darth Sidious."
    "Welcome back, Lord Vader."
    "The system is yours, my lord."
    "Your command is my will, Emperor."
    "All systems await your direction, Darth Plagueis."
)
RANDOM_GREETING=${GREETINGS[$(( RANDOM % ${#GREETINGS[@]} ))]}

# --- DATA GATHERING FUNCTIONS ---

get_datetime() {
    date +"It is currently %A, %B %d. The time is %I:%M %p."
}

get_weather() {
    # Use a custom format for a more narrative feel.
    curl -s "https://wttr.in/$LOCATION?format=The local weather is %C, with a temperature of %t."
}

get_battery() {
    # This path might be BAT0 or BAT1 on your system. Check /sys/class/power_supply/
    local BATTERY_PATH="/sys/class/power_supply/BAT0"

    if [ ! -d "$BATTERY_PATH" ]; then
        # Don't say anything if it's a desktop with no battery.
        return
    fi

    local CAPACITY=$(cat "$BATTERY_PATH/capacity")
    local STATUS=$(cat "$BATTERY_PATH/status")

    if [ "$STATUS" = "Full" ]; then
        echo "The power core is at maximum capacity."
    elif [ "$STATUS" = "Charging" ]; then
        echo "System power is at $CAPACITY percent and charging."
    else
        echo "System power is at $CAPACITY percent and discharging."
    fi
}

get_system_updates() {
    # Check if the 'checkupdates' command is available.
    if ! command -v checkupdates &> /dev/null; then
        return
    fi

    local NUM_UPDATES=$(checkupdates | wc -l)

    if [ "$NUM_UPDATES" -gt 0 ]; then
        echo "There are $NUM_UPDATES system updates requiring your attention."
    else
        echo "All system packages are up to date."
    fi
}


# --- SCRIPT EXECUTION ---

# 1. Assemble the full message.
FINAL_MESSAGE="$RANDOM_GREETING. "
FINAL_MESSAGE+=$(get_datetime)
FINAL_MESSAGE+=". "
FINAL_MESSAGE+=$(get_weather)
FINAL_MESSAGE+=". "
FINAL_MESSAGE+=$(get_battery)
FINAL_MESSAGE+=". "
FINAL_MESSAGE+=$(get_system_updates)

# 2. Speak the final message.
# The '-q' flag makes espeak quieter about its own processing.
espeak-ng -v "$ESPEAK_VOICE" -s "$ESPEAK_SPEED" -q "$FINAL_MESSAGE"