#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "Usage: fas <input_file> [extra_options]"
  exit 1
fi

# Get absolute path of the input file
INPUT_PATH=$(realpath "$1")
INPUT_DIR=$(dirname "$INPUT_PATH")

shift # Remove the first argument (the input file)

# Mount the specific video directly to the path the container demands
docker run \
  -v "$INPUT_PATH":/app/input/video.mp4 \
  -v "$INPUT_DIR":/app/output \
  ghcr.io/sirozha1337/faster-auto-subtitle:latest \
  "$@"
