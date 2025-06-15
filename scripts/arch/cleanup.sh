#!/bin/bash
#
# arch-cleanup-user.sh
#
# A script to manage user-specific cleanup tasks on Arch Linux.
# Reports total space liberated. This version does NOT use sudo.
# Reads configuration from the project's central config.toml.

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Pipestatus: the return value of a pipeline is the status of the last command to exit with a non-zero status,
# or zero if no command exited with a non-zero status.
set -o pipefail

# --- Configuration ---
# This array will be populated by the load_cleanup_directories function.
CLEANUP_DIRECTORIES=()

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

human_readable_size() {
    local size_in_bytes="$1"
    numfmt --to=iec-i --suffix=B "$size_in_bytes" 2>/dev/null || echo "${size_in_bytes}B"
}

# --- Configuration Loading ---
load_cleanup_directories() {
    local SCRIPT_DIR
    SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
    local ROOT_DIR
    ROOT_DIR=$(realpath "$SCRIPT_DIR/../..") # Go up two levels from scripts/arch/
    local CONFIG_FILE="$ROOT_DIR/config.toml"

    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Configuration file not found at $CONFIG_FILE"
        exit 1
    fi

    # Use awk to parse the TOML array under the [cleanup] section.
    local raw_dirs
    raw_dirs=$(awk '
        /^\[cleanup\]/ { in_section=1 }
        /^\[/ && !/^\[cleanup\]/ { in_section=0 }
        in_section && /^\s*directories\s*=\s*\[/ { in_array=1; next }
        in_array {
            if (/\]/) { exit }
            gsub(/[",]/, "");
            gsub(/^[ \t]+|[ \t]+$/, "");
            if ($0) print $0;
        }
    ' "$CONFIG_FILE")

    if [ -z "$raw_dirs" ]; then
        log_warning "No directories found under [cleanup] in $CONFIG_FILE. Nothing to clean."
        return
    fi

    # Read the processed lines into the CLEANUP_DIRECTORIES array
    # and expand the tilde (~) for each directory path.
    while IFS= read -r dir; do
        CLEANUP_DIRECTORIES+=("${dir/\~/$HOME}")
    done <<< "$raw_dirs"
}


# --- Cleanup Module ---
calculate_directory_size() {
    local dir="$1"
    if [ -d "$dir" ]; then
        # Calculate size as current user. `du` might output errors for unreadable subdirs.
        # timeout prevents `du` from hanging. Errors from du are suppressed.
        timeout 10s du -sb "$dir" 2>/dev/null | awk '{print $1}' || echo 0
    else
        echo 0
    fi
}

delete_directory_contents() {
    local dir_to_clean="$1"

    if [ ! -d "$dir_to_clean" ]; then
        log_message "Directory '$dir_to_clean' does not exist. Skipping."
        return 0
    fi

    log_message "Processing directory for cleanup: '$dir_to_clean' (as current user)"

    if [ ! -w "$dir_to_clean" ]; then
        log_warning "No write permission for directory '$dir_to_clean'. Skipping deletion of its contents."
        return 1 # Indicate failure due to permissions
    fi

    local subshell_status=0
    (
        # shellcheck disable=SC2164 # We check -d and -w above, cd should be safe enough
        cd "$dir_to_clean" || { log_error "Could not cd into '$dir_to_clean'. Skipping deletion for this directory."; exit 1; }
        if ! rm -rf ./* ./.[!.]* ./..?* 2>/dev/null; then
            if [ -n "$(ls -A . 2>/dev/null)" ]; then
                log_error "Failed to delete some contents of '$dir_to_clean'."
                exit 1 # Indicates failure in subshell
            fi
        fi
    )
    subshell_status=$?

    if [ "$subshell_status" -ne 0 ]; then
        if [ -n "$(ls -A "$dir_to_clean" 2>/dev/null)" ]; then
             log_warning "Deletion of '$dir_to_clean' may be incomplete. Some files might remain."
             return 1 # Indicate actual failure
        else
            log_message "Contents of '$dir_to_clean' successfully processed."
        fi
    else
        log_message "Contents of '$dir_to_clean' have been processed for deletion."
    fi
    return 0
}


run_cleanup() {
    log_message "Starting user-level system cleanup process..."
    local total_space_liberated=0
    local cleanup_failed_count=0

    if [ ${#CLEANUP_DIRECTORIES[@]} -eq 0 ]; then
        log_warning "CLEANUP_DIRECTORIES array is empty. No directories to process."
    fi

    log_message "--- Processing general directories for cleanup (user-level permissions) ---"
    for dir_path in "${CLEANUP_DIRECTORIES[@]}"; do
        local initial_size
        local final_size
        local liberated_this_dir

        initial_size=$(calculate_directory_size "$dir_path")
        log_message "Initial size of '$dir_path': $(human_readable_size "$initial_size")"

        if delete_directory_contents "$dir_path"; then
            final_size=$(calculate_directory_size "$dir_path")
            liberated_this_dir=$((initial_size - final_size > 0 ? initial_size - final_size : 0))

            if [ "$liberated_this_dir" -gt 0 ]; then
                total_space_liberated=$((total_space_liberated + liberated_this_dir))
                log_message "Liberated $(human_readable_size "$liberated_this_dir") from '$dir_path'."
            else
                log_message "'$dir_path' was already empty or no space was gained."
            fi
        else
            cleanup_failed_count=$((cleanup_failed_count + 1))
            log_warning "Failed to fully clean '$dir_path'."
        fi
        echo
    done

    if [ "$cleanup_failed_count" -gt 0 ]; then
        log_warning "Directory content cleanup phase completed with $cleanup_failed_count directory/directories having issues."
    else
        log_message "Directory content cleanup phase completed."
    fi
    
    echo

    log_message "--- Cleanup Summary ---"
    log_message "Total space liberated by this user-level cleanup: $(human_readable_size "$total_space_liberated")."
    
    log_message "User-level cleanup process finished."
    if [ "$cleanup_failed_count" -gt 0 ]; then
        return 1
    fi
    return 0 
}

# --- Main Execution Logic ---
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Manages user-level Arch Linux system cleanup and reports space liberated."
    echo "Reads configuration from config.toml at the project root."
    echo ""
    echo "Configured CLEANUP_DIRECTORIES (from config.toml):"
    if [ ${#CLEANUP_DIRECTORIES[@]} -gt 0 ]; then
        for dir in "${CLEANUP_DIRECTORIES[@]}"; do
            echo "  - $dir"
        done
    else
        echo "  (No directories configured in config.toml)"
    fi
    echo ""
    echo "Options:"
    echo "  -h, --help            Show this help message and exit."
}

main() {
    # Load configuration first so other functions (like usage) have access to it.
    load_cleanup_directories

    while [[ $# -gt 0 ]]; do
        case "$1" in
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

    run_cleanup
    log_message "arch-cleanup-user.sh finished execution."
}

# Script entry point
if [[ $EUID -eq 0 ]]; then
   log_warning "This script is designed to be run as a regular user."
fi

main "$@"

if [ -t 1 ]; then
    echo
    read -r -p "Script finished. Press Enter to exit..."
fi
