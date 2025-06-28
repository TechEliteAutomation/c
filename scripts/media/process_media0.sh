#!/bin/bash
# Script Name: process_media_refactored.sh
# Description: A simplified and robust media processing pipeline.
# Version: 3.1 (Dependency check removed by user request)

# --- Strict Mode & Setup ---
set -euo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# --- Configuration Loading ---
CONFIG_FILE="$SCRIPT_DIR/config.sh"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[ERROR] Configuration file not found at: $CONFIG_FILE" >&2
    exit 1
fi
# Source the config file to load all variables
source "$CONFIG_FILE"

# --- Logging Functions ---
_log_generic() {
    local type="$1"; shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$type] $1"
}
log_step() { _log_generic "STEP" "$1"; }
log_info() { _log_generic "INFO" "    $1"; }
log_warn() { _log_generic "WARN" "    $1"; }
log_error() { _log_generic "ERROR" "   $1" >&2; }

# --- Core Task Runner ---
# This single function handles finding files and running parallel operations on them.
run_parallel_task() {
    local task_name="$1"
    local find_args="$2"
    local action_command="$3"

    log_info "Starting task: $task_name"

    # Build the full find command safely
    local find_cmd="find . -maxdepth 10 -type f $find_args"

    # Check if there are any files to process before starting
    if ! eval "$find_cmd -print -quit 2>/dev/null" | grep -q .; then
        log_info "No files found for task '$task_name'. Skipping."
        return
    fi

    log_info "Processing files in parallel (max $PARALLEL_JOBS jobs)..."
    eval "$find_cmd -print0" | xargs -0 -r -P "$PARALLEL_JOBS" -I{} bash -c "$action_command" -- {}
    log_info "Task '$task_name' complete."
}

# --- Processing Functions ---

_create_backup() {
    log_step "Creating backup of current directory"
    # Manually expand tilde for the backup directory
    local backup_dir="${BACKUP_BASE_DIR/\~/$HOME}"
    mkdir -p "$backup_dir"

    local backup_filename="$(basename "$(pwd)")_backup_$(date +%Y%m%d_%H%M%S).zip"
    local backup_filepath="$backup_dir/$backup_filename"

    log_info "Backup target: $backup_filepath"
    if zip -r -q "$backup_filepath" .; then
        log_info "Backup created successfully."
    else
        log_error "Backup failed. Check permissions and disk space for $backup_dir."
        exit 1
    fi
}

_remove_duplicates() {
    log_step "Removing duplicate files with rmlint"
    rm -f ./rmlint.*
    rmlint --progress --types=duplicates ./ >/dev/null
    if [ -s "./rmlint.sh" ]; then
        log_info "Found duplicates. Executing rmlint.sh to remove them..."
        bash "./rmlint.sh" -d
    else
        log_info "No duplicates found."
    fi
    rm -f ./rmlint.*
}

_process_archives() {
    local find_args='-iname "*.zip"'
    local action='
        file="$1"
        echo "    [UNZIP] Unpacking '\''$(basename "$file")'\''..."
        unzip -q -o "$file" -d "$(dirname "$file")" && rm "$file"
    '
    run_parallel_task "Unzip Archives" "$find_args" "$action"
}

_delete_small_files() {
    if (( MIN_FILE_SIZE_TO_DELETE_KIB <= 0 )); then
        log_info "Small file deletion is disabled (size set to 0)."
        return
    fi
    log_step "Deleting files smaller than ${MIN_FILE_SIZE_TO_DELETE_KIB}KB"
    local find_args="-size -${MIN_FILE_SIZE_TO_DELETE_KIB}k"
    local action='
        file="$1"
        echo "    [DELETE] Removing small file '\''$(basename "$file")'\''..."
        rm "$file"
    '
    run_parallel_task "Delete Small Files" "$find_args" "$action"
}

_rename_files_external() {
    local renamer_script="$SCRIPT_DIR/rename_files.sh"
    log_step "Running external renamer script: $renamer_script"
    if [ ! -x "$renamer_script" ]; then
        log_warn "Renamer script not found or not executable. Skipping."
        return
    fi
    "$renamer_script"
    log_info "External renaming complete."
}

_convert_jpegs_to_png() {
    log_step "Converting JPEGs between ${JPEG_TO_PNG_MIN_KIB}k and ${JPEG_TO_PNG_MAX_KIB}k to PNG"
    # Logic: size > (min-1) AND size < (max+1) correctly captures the inclusive range.
    local find_args="\( -iname '*.jpg' -o -iname '*.jpeg' \) -size +$((${JPEG_TO_PNG_MIN_KIB}-1))k -size -$((${JPEG_TO_PNG_MAX_KIB}+1))k"
    local action='
        file="$1"
        echo "    [CONVERT-JPG] Converting '\''$(basename "$file")'\'' to PNG..."
        mogrify -format png "$file" && rm "$file"
    '
    run_parallel_task "Convert JPEGs to PNGs" "$find_args" "$action"
}

_convert_webps_to_png() {
    log_step "Converting all WebP files to PNG"
    local find_args="-iname '*.webp'"
    local action='
        file="$1"
        echo "    [CONVERT-WEBP] Converting '\''$(basename "$file")'\'' to PNG..."
        mogrify -format png "$file" && rm "$file"
    '
    run_parallel_task "Convert WebPs to PNGs" "$find_args" "$action"
}

_remove_exif_data() {
    log_step "Removing all EXIF metadata from files"
    # exiftool can run on all files at once; no need for parallelization here.
    log_info "Processing files with exiftool..."
    exiftool -all= -overwrite_original -r -q -q .
    log_info "EXIF data removal complete."
}

# --- Main Execution Workflow ---
main() {
    log_step "Media Processing Pipeline Initialized"
    local start_time=$SECONDS

    # NOTE: Dependency check was removed by user request.
    # The script will fail if required tools are not installed.
    _create_backup
    _remove_duplicates # Pre-unzip check
    _process_archives
    _delete_small_files
    _remove_duplicates # Post-unzip check
    _rename_files_external
    _convert_jpegs_to_png
    _convert_webps_to_png
    _remove_exif_data
    _remove_duplicates # Final check

    local duration=$((SECONDS - start_time))
    log_step "Pipeline finished in $duration seconds."
}

# --- Script Entry Point ---
main