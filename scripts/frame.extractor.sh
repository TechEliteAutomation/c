#!/bin/bash
#
# Iterates over all .mp4 files in the current directory,
# creating a subdirectory for each and extracting its frames into it.
#

# Loop through all files ending in .mp4
for file in *.mp4; do
  # Create a directory name by removing the '.mp4' extension from the filename
  dir_name="${file%.mp4}"

  # Create the directory, -p ensures it doesn't error if it already exists
  mkdir -p -- "$dir_name"

  # Execute ffmpeg, quoting variables to handle spaces or special characters
  # The output is directed into the newly created subdirectory
  echo "Processing '$file' -> '$dir_name/'"
  ffmpeg -i "$file" "$dir_name/frame_%04d.png"
done

echo "Batch processing complete."