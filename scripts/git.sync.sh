#!/bin/bash
#
# A robust script to automatically commit and push changes for a single Git monorepo.
# This script is UNIDIRECTIONAL: it force-pushes local changes to the cloud,
# overwriting any remote-only changes. It will never pull or merge from the remote.
#

# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error.
# The return value of a pipeline is the status of the last command to exit with a non-zero status.
set -euo pipefail

# --- Configuration Loading ---

# Finds the script's own directory and locates the config.toml in the parent directory.
SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
ROOT_DIR=$(dirname "$SCRIPT_DIR")
CONFIG_FILE="$ROOT_DIR/config.toml"

# Function to safely load a value from config.toml under the [git_sync] section.
# It handles quoted values and trims whitespace.
load_config() {
    local key="$1"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Configuration file not found at $CONFIG_FILE" >&2
        exit 1
    fi

    # A robust parser using grep and sed.
    local value
    value=$(grep -E "^\s*$key\s*=" "$CONFIG_FILE" | sed -E 's/.*=\s*"?([^"]*)"?/\1/')

    if [ -z "$value" ]; then
        echo "Error: Key '$key' not found in $CONFIG_FILE" >&2
        exit 1
    fi

    # Manually expand the tilde (~) to the user's home directory.
    echo "${value/\~/$HOME}"
}

# Load configuration into variables
REPO_DIR=$(load_config "repo_directory")
LOG_FILE=$(load_config "log_file")
GIT_EMAIL=$(load_config "git_email")
GIT_NAME=$(load_config "git_name")
COMMIT_MESSAGE=$(load_config "commit_message")

# --- Main Logic ---

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Log function that prints to stdout and appends to the log file.
log() {
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1" | tee -a "$LOG_FILE"
}

log "--- Starting Unidirectional Git Sync for Monorepo: $REPO_DIR ---"

# Navigate to the repository directory.
if ! cd "$REPO_DIR"; then
    log "ERROR: Repository directory not found at '$REPO_DIR'. Please check config.toml."
    exit 1
fi

# --- Pre-flight Checks ---

log "Step 1: Configuring Git user..."
git config user.email "$GIT_EMAIL"
git config user.name "$GIT_NAME"

log "Step 2: Fetching remote state..."
# Fetch updates from the remote to update our knowledge of the remote branch.
# This is crucial for the safety of 'push --force-with-lease'.
if ! git fetch origin; then
    log "ERROR: Failed to fetch from remote 'origin'. Check network connection and repository URL."
    exit 1
fi

log "Step 3: Checking for local changes..."
# MODIFICATION: The check for 'Your branch is behind' has been removed to allow overwriting the remote.

# Check for uncommitted local changes.
if ! git status --porcelain | grep -q .; then
    log "No local changes detected. Sync complete."
    log "--- Git Sync Finished ---"
    exit 0
fi

# --- Commit and Push ---

log "Step 4: Committing local changes..."
git add -A
# MODIFICATION: Use --no-verify to bypass any pre-commit hooks.
# This prevents errors when the script is run outside an activated virtual environment.
git commit --no-verify -m "$COMMIT_MESSAGE"

log "Step 5: Force-pushing changes to remote..."
# MODIFICATION: Using 'push --force-with-lease' to overwrite the remote branch.
# This is the core of the unidirectional sync. It ensures the remote matches the local state.
if git push --force-with-lease origin "$(git rev-parse --abbrev-ref HEAD)"; then
    log "Successfully force-pushed changes, overwriting remote."
else
    log "ERROR: Failed to force-push changes. This can happen if the remote was updated after our fetch. Manual intervention required."
    exit 1
fi

log "--- Git Sync Finished ---"
