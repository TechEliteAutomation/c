#!/bin/bash
#
# A script to clean specified user-level directories based on the config.toml file.
# It calculates and reports the total disk space reclaimed.
#

# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error.
# The return value of a pipeline is the status of the last command to exit with a non-zero status.
set -euo pipefail

# --- Configuration Loading ---

# Robustly find the repository's root directory.
find_repo_root() {
    local dir
    dir=$(pwd)
    while [ "$dir" != "/" ]; do
        [ -d "$dir/.git" ] && echo "$dir" && return
        dir=$(dirname "$dir")
    done
    echo "Error: Not a git repository." >&2
    exit 1
}

ROOT_DIR=$(find_repo_root)
CONFIG_FILE="$ROOT_DIR/config.toml"

# Log function that prints to stdout.
log() {
    local level="$1"
    local message="$2"
    echo "[$level] $(date "+%Y-%m-%d %H:%M:%S"): $message"
}

# Function to safely load an array of strings from config.toml.
load_config_array() {
    local section="$1"
    local key="$2"

    if [ ! -f "$CONFIG_FILE" ]; then
        log "ERROR" "Configuration file not found at $CONFIG_FILE"
        exit 1
    fi

    local raw_values
    raw_values=$(awk -v section="$section" -v key="$key" '
        BEGIN { in_section=0 }
        $0 ~ "\\[" section "\\]" { in_section=1; next }
        /^\[/ { in_section=0 }
        in_section && $0 ~ key {
            in_array=1
            next
        }
        in_array {
            if ($0 ~ /\]/) { exit }
            gsub(/[",]/, "");
            gsub(/^[ \t]+|[ \t]+$/, "");
            if (length($0) > 0) { print $0 }
        }
    ' "$CONFIG_FILE")

    if [ -z "$raw_values" ]; then
        log "WARN" "Key '$key' not found or empty under [$section] in $CONFIG_FILE. Nothing to clean."
        return
    fi

    readarray -t CLEANUP_DIRECTORIES < <(echo "$raw_values")
}

# Helper function to convert bytes to a human-readable format (KB, MB, GB).
bytes_to_human() {
    local bytes=$1
    if [ -z "$bytes" ] || [ "$bytes" -eq 0 ]; then
        echo "0B"
        return
    fi
    echo "$bytes" | awk '
        function human(x) {
            s=" B  K  M  G  T  P";
            while (x >= 1024 && length(s) > 1) {
                x /= 1024;
                s = substr(s, 4);
            }
            return sprintf("%.1f%s", x, substr(s, 1, 2));
        }
        { print human($1) }' | sed 's/ //g'
}


# --- Main Logic ---

log "INFO" "Starting user-level system cleanup process..."

# Load the directories to be cleaned from the config file.
load_config_array "system_paths" "cleanup_directories"

if [ ${#CLEANUP_DIRECTORIES[@]} -eq 0 ]; then
    log "INFO" "Cleanup process finished. No directories were configured for cleaning."
    exit 0
fi

log "INFO" "--- Processing configured directories for cleanup ---"

total_space_freed_bytes=0

for dir_path in "${CLEANUP_DIRECTORIES[@]}"; do
    # Manually expand the tilde (~) to the user's home directory.
    expanded_path="${dir_path/\~/$HOME}"

    if [ -d "$expanded_path" ]; then
        # Get size in bytes for calculation.
        size_before_bytes=$(du -sb "$expanded_path" 2>/dev/null | awk '{print $1}')
        size_before_bytes=${size_before_bytes:-0}

        log "INFO" "Cleaning contents of: $expanded_path (Size: $(bytes_to_human "$size_before_bytes"))"
        
        # Find and delete all files and subdirectories within the target directory.
        find "$expanded_path" -mindepth 1 -delete || true
        
        # Get size after cleaning.
        size_after_bytes=$(du -sb "$expanded_path" 2>/dev/null | awk '{print $1}')
        size_after_bytes=${size_after_bytes:-0}

        # Calculate space freed for this directory and add to total.
        space_freed_this_dir=$((size_before_bytes - size_after_bytes))
        total_space_freed_bytes=$((total_space_freed_bytes + space_freed_this_dir))

    else
        log "WARN" "Directory not found, skipping: $expanded_path"
    fi
done

log "INFO" "Directory content cleanup phase completed."
log "INFO" "--- Cleanup Summary ---"
log "INFO" "Total space liberated by this cleanup: $(bytes_to_human "$total_space_freed_bytes")."
log "INFO" "User-level cleanup process finished."
