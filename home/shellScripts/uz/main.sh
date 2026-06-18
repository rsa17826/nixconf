#!/usr/bin/env bash

# Exit on error
set -e

TARGET_DIR="${2:-.}"
ARCHIVE="$1"

# 1. Create a unique temporary reference file before extraction
NEWER_THAN=$(mktemp)

# Ensure the temp file is cleaned up even if the script crashes
trap 'rm -f "$NEWER_THAN"' EXIT

# 2. Extract the first layer
7zz x "$ARCHIVE" -o"$TARGET_DIR"

# 3. Find any .tar files created *after* our timestamp file
TAR_FILES=$(find "$TARGET_DIR" -mindepth 1 -newer "$NEWER_THAN" -name "*.tar")

# 4. If a .tar was found, extract it and clean it up
if [ -n "$TAR_FILES" ]; then
  echo "$TAR_FILES" | while IFS= read -r tar_file; do
    echo "Detected extracted tarball: $tar_file. Extracting..."
    7zz x "$tar_file" -o"$TARGET_DIR" -y
    rm "$tar_file"
  done
fi
