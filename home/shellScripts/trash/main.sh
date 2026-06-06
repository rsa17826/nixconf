#!/usr/bin/env bash

# Check if an argument was provided
if [ $# -eq 0 ]; then
  echo "Usage: trash <file_or_directory>"
  exit 1
fi

# Determine the OS and set the correct Trash path
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS Trash
  TRASH_DIR="$HOME/.Trash"
else
  # Linux Freedesktop compliance Trash
  TRASH_DIR="$HOME/.local/share/Trash/files"
fi

# Ensure the trash directory exists
mkdir -p "$TRASH_DIR"
ec=0
# Loop through all arguments passed to the script
for item in "$@"; do
  if [ -e "$item" ]; then
    # Move the item to the trash
    mv "$item" "$TRASH_DIR/"
    # echo "Moved to Trash: $item"
  else
    ec=1
    # echo "Error: '$item' does not exist."
  fi
done
exit $ec
