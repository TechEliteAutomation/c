#!/bin/bash
#
# Script Name: receive_from_usb.sh
# Description: Automates moving files from a mounted USB drive to a local
#              directory, effectively clearing the USB drive in the process.
#

# --- Configuration ---
# The local directory where files will be moved to.
DEST_DIR="$HOME/0"

# The block device representing your USB drive.
DEVICE="/dev/sda"

# The temporary mount point for the USB drive.
MOUNT_POINT="/mnt/usb"

# --- Colors for Logging ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Main Logic ---
main() {
    echo -e "${GREEN}--- USB Receive Script Initialized ---${NC}"

    # 1. Pre-flight Checks
    log_step "Performing pre-flight checks..."

    if [ ! -b "$DEVICE" ]; then
        log_error "Device '$DEVICE' not found. Please check 'lsblk' and update the script."
        exit 1
    fi

    if mountpoint -q "$MOUNT_POINT"; then
        log_error "Mount point '$MOUNT_POINT' is already in use. Please unmount it first."
        exit 1
    fi

    # Create the destination directory if it doesn't exist
    mkdir -p "$DEST_DIR"
    log_info "Destination directory '$DEST_DIR' is ready."
    log_info "All checks passed."

    # 2. User Confirmation
    echo
    log_warn "You are about to perform the following actions:"
    log_warn "  1. MOVE all files from the USB drive ('$DEVICE') to '$DEST_DIR'."
    log_warn "  2. This will WIPE the contents of the USB drive."
    echo
    read -p "Are you sure you want to continue? (y/N): " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log_error "User aborted. No changes were made."
        exit 0
    fi

    # 3. Execution
    log_step "Mounting USB drive..."
    if ! sudo mount "$DEVICE" "$MOUNT_POINT"; then
        log_error "Failed to mount '$DEVICE'. Check permissions or if the drive is formatted correctly."
        exit 1
    fi
    log_info "Device mounted successfully at '$MOUNT_POINT'."

    # Check if the USB drive is empty before proceeding
    if [ -z "$(ls -A "$MOUNT_POINT")" ]; then
        log_warn "USB drive at '$MOUNT_POINT' is empty. Nothing to transfer."
        sudo umount "$DEVICE"
        exit 0
    fi

    log_step "Moving files with rsync (this will clear the USB drive)..."
    # This is the key command that moves files and deletes them from the source
    rsync -avP --remove-source-files "$MOUNT_POINT/" "$DEST_DIR/"
    log_info "File transfer complete."

    log_step "Forcing data sync to disk..."
    sync
    log_info "Cache flushed. Data is physically written."

    log_step "Unmounting USB drive..."
    if ! sudo umount "$DEVICE"; then
        log_error "Failed to unmount '$DEVICE'. The drive may be busy."
        exit 1
    fi
    log_info "Device unmounted successfully."

    # 4. Final Instructions
    echo
    echo -e "${GREEN}************************************************************${NC}"
    echo -e "${GREEN}*                                                          *${NC}"
    echo -e "${GREEN}*                   ${YELLOW}PROCESS COMPLETE${NC}                      *${NC}"
    echo -e "${GREEN}*                                                          *${NC}"
    echo -e "${GREEN}*  All files have been moved to '$DEST_DIR'.         *${NC}"
    echo -e "${GREEN}*  The USB drive is now empty and safe to remove.          *${NC}"
    echo -e "${GREEN}*                                                          *${NC}"
    echo -e "${GREEN}************************************************************${NC}"
}

# --- Helper Functions ---
log_step() { echo -e "\n${GREEN}==> $1${NC}"; }
log_info() { echo -e "    ${NC}$1${NC}"; }
log_warn() { echo -e "    ${YELLOW}$1${NC}"; }
log_error() { echo -e "    ${RED}$1${NC}"; }

# --- Script Entry Point ---
main
