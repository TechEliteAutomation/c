# File: config.sh
# Description: Configuration for the media processing script.

# --- Directory for backups ---
# The script will expand the tilde (~) to your home directory.
BACKUP_BASE_DIR="~/.bak"

# --- Performance ---
# Number of parallel jobs to run for tasks like conversion and unzipping.
# Set this to the number of CPU cores you have for best performance.
PARALLEL_JOBS=4

# --- JPEG to PNG Conversion ---
# Convert JPEGs within this size range (in Kilobytes) to PNG.
# This will convert files from 100k up to and including 999k.
JPEG_TO_PNG_MIN_KIB=100
JPEG_TO_PNG_MAX_KIB=999

# --- Small File Deletion ---
# After unzipping, delete all files smaller than this size (in Kilobytes).
# Set to 0 to disable this feature.
MIN_FILE_SIZE_TO_DELETE_KIB=100
