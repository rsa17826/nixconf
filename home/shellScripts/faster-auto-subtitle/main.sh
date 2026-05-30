#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "Usage: fas <input_file> [extra_options]"
  exit 1
fi

# Get absolute path of the input file
INPUT_PATH=$(realpath "$1")
INPUT_DIR=$(dirname "$INPUT_PATH")
INPUT_FILE=$(basename "$INPUT_PATH")

shift # Remove the first argument (the input file)

# Mount the file's directory to /workspace, and pass the file directly
docker run \
  -v "$INPUT_DIR":/workspace \
  ghcr.io/sirozha1337/faster-auto-subtitle:latest \
  "/workspace/$INPUT_FILE" "$@"
