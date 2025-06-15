#!/bin/bash
set -euo pipefail

# --- Configuration Loading ---

# Function to load a value from config.toml under the [backup] section
load_config() {
    local key="$1"
    # The BASH_SOURCE variable gives the path to the script itself.
    # We find the script's directory, go up one level to the project root, and find config.toml.
    local SCRIPT_DIR
    SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
    local ROOT_DIR
    ROOT_DIR=$(realpath "$SCRIPT_DIR/..")
    local CONFIG_FILE="$ROOT_DIR/config.toml"

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Configuration file not found at $CONFIG_FILE" >&2
        exit 1
    fi

    # Use awk for robust parsing: find [backup] section, then find the key.
    local value
    value=$(awk -F'=' '/^\[backup\]/{in_section=1} /^\[/{if(!/^\[backup\]/) in_section=0} in_section && /^\s*'"$key"'\s*=/{gsub(/[ \t"]/, "", $2); print $2; exit}' "$CONFIG_FILE")

    if [ -z "$value" ]; then
        echo "Error: Key '$key' not found under [backup] section in $CONFIG_FILE" >&2
        exit 1
    fi

    # Manually expand the tilde (~) to the user's home directory for safety.
    value="${value/\~/$HOME}"
    
    echo "$value"
}

# Load configuration into variables
USB_MOUNT_POINT=$(load_config "mount_point")
LOG_FILE=$(load_config "log_file")
BACKUP_SOURCE=$(load_config "source_directory")

# --- Script Globals ---
BACKUP_DEST=""
DATE_FORMAT=$(date "+%Y-%m-%d_%H-%M-%S")

# --- Main Functions ---

# Function to detect and let user select USB
detect_usb() {
    mapfile -t USB_DEVICES < <(lsblk -d -n -o NAME,TRAN | grep 'usb' | awk '{print $1}')
    if [ ${#USB_DEVICES[@]} -eq 0 ]; then
        echo "No USB drives detected."
        exit 1
    fi
    echo "Available USB devices:"
    for i in "${!USB_DEVICES[@]}"; do
        echo "$((i + 1)). /dev/${USB_DEVICES[$i]}"
    done
    read -p "Select a USB device (enter number): " CHOICE
    if ! [[ "$CHOICE" =~ ^[1-9][0-9]*$ && "$CHOICE" -le "${#USB_DEVICES[@]}" ]]; then
        echo "Invalid choice."
        exit 1
    fi
    local USB_DEVICE="/dev/${USB_DEVICES[$((CHOICE - 1))]}"
    echo "Selected USB device: $USB_DEVICE"
    if ! mount | grep -q "$USB_MOUNT_POINT"; then
        echo "Mounting requires root privileges."
        sudo mkdir -p "$USB_MOUNT_POINT"
        sudo mount "$USB_DEVICE" "$USB_MOUNT_POINT"
        echo "Mounted $USB_DEVICE to $USB_MOUNT_POINT"
    fi
}

# Function to check USB contents and prompt for deletion
check_usb_contents() {
    if [ "$(ls -A "$USB_MOUNT_POINT")" ]; then
        echo "The USB drive contains files:"
        ls -lh "$USB_MOUNT_POINT"
        read -p "Do you want to delete all files before backup? (y/n): " DELETE_CONFIRM
        if [[ "$DELETE_CONFIRM" == "y" || "$DELETE_CONFIRM" == "Y" ]]; then
            echo "Clearing the mount point requires root privileges."
            sudo rm -rf "$USB_MOUNT_POINT"/*
            echo "USB drive cleared."
        else
            echo "Proceeding without deletion."
        fi
    else
        echo "USB drive is empty."
    fi
}

# Function to perform the backup
backup_files() {
    BACKUP_DEST="$USB_MOUNT_POINT/backup_$DATE_FORMAT"
    mkdir -p "$BACKUP_DEST"

    # Collect non-hidden directories in HOME and .xinitrc
    local -a DIRECTORIES=()
    while IFS= read -r -d '' dir; do
        DIRECTORIES+=("$(basename "$dir")")
    done < <(find "$BACKUP_SOURCE" -maxdepth 1 -mindepth 1 -type d -not -name '.*' -print0)
    
    if [ -f "$BACKUP_SOURCE/.xinitrc" ]; then
        DIRECTORIES+=(".xinitrc")
    fi

    # Confirm with the user before proceeding
    echo "The following directories and files will be backed up:"
    printf -- "- %s\n" "${DIRECTORIES[@]}"

    read -p "Do you want to proceed with the backup? (y/n): " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo "Backup cancelled."
        exit 0
    fi

    echo "Starting backup... (This may take a while)"
    
    # Perform backup with progress indicator
    for DIR in "${DIRECTORIES[@]}"; do
        echo "Backing up: $DIR"
        rsync -ah --info=progress2 "$BACKUP_SOURCE/$DIR" "$BACKUP_DEST/"
    done

    echo "Backup completed: $BACKUP_DEST"
}

# Function to log the backup
log_backup() {
    echo "$(date) - Backup completed to $BACKUP_DEST" >> "$LOG_FILE"
}

# --- Execution ---
detect_usb
check_usb_contents
backup_files
log_backup
