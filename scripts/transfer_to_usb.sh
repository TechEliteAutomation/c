#!/bin/bash
#
# Script Name: transfer_to_usb.sh
# Description: Automates moving files from a source directory to a USB drive,
#              including mounting, syncing, and cleanup.
#

# --- Configuration ---
# The directory on your computer where files are staged for transfer.
SOURCE_DIR="$HOME/1"

# The block device representing your USB drive (e.g., /dev/sda, /dev/sdb).
# IMPORTANT: Double-check this with 'lsblk' before running!
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
    echo -e "${GREEN}--- USB Transfer Script Initialized ---${NC}"

    # 1. Pre-flight Checks
    log_step "Performing pre-flight checks..."

    if [ ! -d "$SOURCE_DIR" ] || [ -z "$(ls -A "$SOURCE_DIR")" ]; then
        log_error "Source directory '$SOURCE_DIR' does not exist or is empty. Nothing to do."
        exit 1
    fi

    if [ ! -b "$DEVICE" ]; then
        log_error "Device '$DEVICE' not found. Please check 'lsblk' and update the script."
        exit 1
    fi

    if mountpoint -q "$MOUNT_POINT"; then
        log_error "Mount point '$MOUNT_POINT' is already in use. Please unmount it first."
        exit 1
    fi
    log_info "All checks passed."

    # 2. User Confirmation
    echo
    log_warn "You are about to perform the following actions:"
    log_warn "  1. MOVE all files from '$SOURCE_DIR' to the USB drive ('$DEVICE')."
    log_warn "  2. DELETE the source directory '$SOURCE_DIR' after the transfer."
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

    log_step "Transferring files with rsync..."
    # Using the exact robust command from your log
    rsync -avP --remove-source-files "$SOURCE_DIR/" "$MOUNT_POINT/"
    log_info "File transfer complete."

    log_step "Forcing data sync to USB drive..."
    sync
    log_info "Cache flushed. Data is physically written to the drive."

    log_step "Cleaning up source directory..."
    if rm -r "$SOURCE_DIR"; then
        log_info "Source directory '$SOURCE_DIR' has been deleted."
    else
        log_warn "Could not remove source directory. It may have already been deleted by rsync."
    fi

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
    echo -e "${GREEN}*            ${YELLOW}PROCESS COMPLETE. IT IS NOW SAFE TO PROCEED.${NC}         *${NC}"
    echo -e "${GREEN}*                                                          *${NC}"
    echo -e "${GREEN}*  1. Physically unplug the USB drive from this computer.  *${NC}"
    echo -e "${GREEN}*  2. Insert the USB drive into the target system.         *${NC}"
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