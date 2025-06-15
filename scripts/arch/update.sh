#!/bin/bash
#
# arch-update.sh
#
# A script to manage Arch Linux system and AUR package updates.
# Reads configuration from the project's central config.toml.

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Pipestatus: the return value of a pipeline is the status of the last command to exit with a non-zero status,
# or zero if no command exited with a non-zero status.
set -o pipefail

# --- Configuration ---
# This will be set by load_config() and can be overridden by command-line flags.
NON_INTERACTIVE_UPDATES=false

# --- Helper Functions ---
log_message() {
    echo "[INFO] $(date +'%Y-%m-%d %H:%M:%S'): $1"
}

log_warning() {
    echo "[WARN] $(date +'%Y-%m-%d %H:%M:%S'): $1" >&2
}

log_error() {
    echo "[ERROR] $(date +'%Y-%m-%d %H:%M:%S'): $1" >&2
}

_ensure_sudo_available() {
    if ! sudo -n true 2>/dev/null; then
        log_message "Sudo requires a password. Please enter it when prompted."
    fi
}

# --- Configuration Loading ---
load_config() {
    local SCRIPT_DIR
    SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
    local ROOT_DIR
    ROOT_DIR=$(realpath "$SCRIPT_DIR/../..") # Go up two levels from scripts/arch/
    local CONFIG_FILE="$ROOT_DIR/config.toml"

    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file not found at $CONFIG_FILE"
        exit 1
    fi

    # Use awk to find [update] section, then find the key.
    local value
    value=$(awk -F'=' '/^\[update\]/{in_section=1} /^\[/{if(!/^\[update\]/) in_section=0} in_section && /^\s*non_interactive\s*=/{gsub(/[ \t"]/, "", $2); print $2; exit}' "$CONFIG_FILE")

    # Default to false if not found or empty
    if [ -z "$value" ]; then
        log_warning "Key 'non_interactive' not found in config.toml, defaulting to 'false'."
        NON_INTERACTIVE_UPDATES=false
    else
        NON_INTERACTIVE_UPDATES="$value"
    fi
}

# --- Update Module ---
perform_system_update() {
    log_message "Starting system package update (pacman)..."
    _ensure_sudo_available
    local pacman_args=("-Syu")
    if [ "$NON_INTERACTIVE_UPDATES" = true ]; then
        pacman_args+=("--noconfirm")
    fi

    if ! sudo pacman "${pacman_args[@]}"; then
        log_error "System package update (pacman) failed."
        return 1
    fi
    log_message "System package update (pacman) completed successfully."
    return 0
}

perform_aur_update() {
    if ! command -v yay >/dev/null 2>&1; then
        log_message "yay AUR helper not found. Skipping AUR package update."
        return 0 # Not an error if yay is not installed, just a skip.
    fi

    log_message "Starting AUR package update (yay)..."
    local yay_args=("-Syu")
     if [ "$NON_INTERACTIVE_UPDATES" = true ]; then
        yay_args+=("--noconfirm")
    fi

    if ! yay "${yay_args[@]}"; then
        log_error "AUR package update (yay) failed."
        return 1
    fi
    log_message "AUR package update (yay) completed successfully."
    return 0
}

run_updates() {
    log_message "Initiating system update process..."
    if ! perform_system_update; then
        return 1
    fi
    if ! perform_aur_update; then
        return 1
    fi
    log_message "System update process finished successfully."
    return 0
}

# --- Main Execution Logic ---
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Manages Arch Linux system and AUR package updates."
    echo ""
    echo "Options:"
    echo "  -h, --help            Show this help message and exit."
    echo "  -n, --non-interactive Run updates without interactive prompts (uses --noconfirm)."
    echo "                        This overrides the setting in config.toml."
    echo "                        Default from config: $NON_INTERACTIVE_UPDATES"
    echo ""
}

main() {
    # Load the default from config.toml first.
    load_config

    # Parse command-line options, which can override the config.
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--non-interactive)
                NON_INTERACTIVE_UPDATES=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    run_updates
    log_message "arch-update.sh finished execution."
}

# Script entry point
if [[ $EUID -eq 0 ]]; then
   log_warning "This script is designed to be run as a regular user."
   log_warning "It will use 'sudo' internally for privileged operations."
fi

main "$@"

if [ -t 1 ]; then
    echo
    read -r -p "Script finished. Press Enter to exit..."
fi
