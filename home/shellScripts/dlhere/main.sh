#!/usr/bin/env bash

# Define the source directory
SRC="$HOME/Downloads"

# Find files modified less than 30 seconds ago (-0.5 minutes)
# and move them to the current directory (.)
find "$SRC" -maxdepth 1 -type f -mmin -0.5 -exec mv -t . {} +
