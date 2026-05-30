#!/usr/bin/env bash

# Check if at least one argument (the input file) was provided
if [ -z "$1" ]; then
  echo "Usage: fas <input_file> [extra_options]"
  exit 1
fi

# Grab the absolute path of the input file so Docker can find it
INPUT_PATH=$(realpath "$1")
INPUT_DIR=$(dirname "$INPUT_PATH")
INPUT_FILE=$(basename "$INPUT_PATH")

# Shift the arguments so "$@" only contains the extra options
shift

# Run Docker, mounting the video's directory to /workspace inside the container
docker run \
  -v "$INPUT_DIR":/workspace \
  ghcr.io/sirozha1337/faster-auto-subtitle:latest \
  "/workspace/$INPUT_FILE" "$@"
