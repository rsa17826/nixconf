#!/usr/bin/env bash

# Exit on error
set -e

ARCHIVE="$1"
TARGET_DIR="${2:-.}"

# Ensure target directory exists
mkdir -p "$TARGET_DIR"

# Convert filename to lowercase to make the extension check case-insensitive
ARCHIVE_LOWER=$(echo "$ARCHIVE" | tr '[:upper:]' '[:lower:]')

# Check if the file extension matches tar or compressed tar formats
if [[ "$ARCHIVE_LOWER" == *.tar || "$ARCHIVE_LOWER" == *.tgz || "$ARCHIVE_LOWER" == *.tar.gz ]]; then
  echo "Tar archive detected. Extracting with 'tar'..."

  # Check if it's compressed (.tgz/.tar.gz) or raw (.tar)
  if [[ "$ARCHIVE_LOWER" == *.tar ]]; then
    tar -xf "$ARCHIVE" -C "$TARGET_DIR"
  else
    tar -xzf "$ARCHIVE" -C "$TARGET_DIR"
  fi

else
  echo "Non-tar archive detected. Extracting with '7zz'..."
  7zz x "$ARCHIVE" -o"$TARGET_DIR" -y
fi
