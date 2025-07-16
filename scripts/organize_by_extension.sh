#!/bin/bash

TARGET_DIR="$HOME/0"

# Check if the target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory $TARGET_DIR does not exist."
    exit 1
fi

cd "$TARGET_DIR" || exit 1

# Loop through all files in the current directory
for file in *; do
    # Skip if it's a directory
    if [ -d "$file" ]; then
        continue
    fi

    # Extract the file extension
    extension="${file##*.}"

    # If the file has no extension (e.g., "Makefile", ".bashrc"),
    # or if the extension is the same as the filename (e.g., ".profile"),
    # treat it as "no_extension" or similar.
    # For simplicity, we'll assume files always have an extension for this task.
    # If the file name is exactly the extension (e.g., ".bashrc"),
    # the above `##*.` will return the full filename.
    # Let's refine to handle dotfiles without extensions more robustly.
    if [[ "$file" == *.* ]]; then
        extension="${file##*.}"
    else
        extension="no_extension" # Or handle as desired, e.g., "other"
    fi

    # Create the directory if it doesn't exist
    mkdir -p "$extension"

    # Move the file into the extension directory
    mv "$file" "$extension/"
done
