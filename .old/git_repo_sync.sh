#!/bin/bash
set -euo pipefail

# --- Configuration Loading ---

# Function to load a value from config.toml under the [git_sync] section
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

    # Use awk for robust parsing: find [git_sync] section, then find the key.
    local value
    value=$(awk -F'=' '/^\[git_sync\]/{in_section=1} /^\[/{if(!/^\[git_sync\]/) in_section=0} in_section && /^\s*'"$key"'\s*=/{gsub(/[ \t"]/, "", $2); print $2; exit}' "$CONFIG_FILE")

    if [ -z "$value" ]; then
        echo "Error: Key '$key' not found under [git_sync] section in $CONFIG_FILE" >&2
        exit 1
    fi

    # Manually expand the tilde (~) to the user's home directory.
    value="${value/\~/$HOME}"
    
    echo "$value"
}

# Load configuration into variables
BASE_DIR=$(load_config "base_directory")
LOG_FILE=$(load_config "log_file")
GIT_EMAIL=$(load_config "git_email")
GIT_NAME=$(load_config "git_name")

# --- Main Logic ---

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Log function
log() {
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1" | tee -a "$LOG_FILE"
}

log "Starting git sync process"

# Ensure GitHub's SSH key is trusted
ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null

for dir in "$BASE_DIR"/*; do
    [ -d "$dir/.git" ] || continue
    
    if ! cd "$dir"; then
        log "ERROR: Could not cd into $dir"
        continue
    fi
    
    repo_name=$(basename "$dir")
    log "Processing repository: $repo_name"
    
    # Use config variables for Git config
    git config user.email "$GIT_EMAIL"
    git config user.name "$GIT_NAME"
    
    # Check for changes before committing
    if git status --porcelain | grep -q .; then
        log "Changes detected in $repo_name"
        
        git add -A
        git commit -m "Auto-sync: $(date "+%Y-%m-%d %H:%M:%S")"
        
        if git push origin "$(git rev-parse --abbrev-ref HEAD)"; then
            log "Successfully pushed changes for $repo_name"
        else
            log "ERROR: Failed to push changes for $repo_name"
        fi
    else
        log "No changes detected in $repo_name"
    fi
done

log "Git sync process completed"
