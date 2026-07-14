#!/usr/bin/env bash

# ==========================================
# Configuration
# ==========================================
NAMES_FILE="/data/streams/names.txt"
BASE_DIR="/data/streams"

# ==========================================
# Pre-flight Checks
# ==========================================
# Ensure the names file exists
if [ ! -f "$NAMES_FILE" ]; then
  echo "Error: Names file not found at $NAMES_FILE"
  exit 1
fi

# Ensure yt-dlp and ffmpeg are installed
if ! command -v yt-dlp &>/dev/null || ! command -v ffmpeg &>/dev/null; then
  echo "Error: Both yt-dlp and ffmpeg are required. Please install them."
  exit 1
fi

# ==========================================
# Main Loop
# ==========================================
# Read the file line by line
while IFS= read -r channel || [ -n "$channel" ]; do

  # Clean up whitespace and skip empty lines or commented lines (#)
  channel=$(echo "$channel" | xargs)
  [[ -z "$channel" || "$channel" == \#* ]] && continue

  echo "=============================================="
  echo "Checking for new videos from: $channel"
  echo "=============================================="

  # Define the output directory based on your requested structure
  CREATOR_DIR="$BASE_DIR/$channel/video"
  mkdir -p "$CREATOR_DIR"

  # Define an archive file so yt-dlp remembers what it has already downloaded
  ARCHIVE_FILE="$BASE_DIR/$channel/download_archive.txt"

  # Execute yt-dlp to fetch, download, and compress
  yt-dlp "https://www.twitch.tv/$channel/videos" \
    --download-archive "$ARCHIVE_FILE" \
    --output "$CREATOR_DIR/%(title)s [%(id)s].%(ext)s" \
    --playlist-end 10 \
    --format "bestvideo[height=720]+bestaudio/bestvideo[height>720]+bestaudio/bestvideo+bestaudio/best" \
    --merge-output-format mp4 \
    --postprocessor-args "ffmpeg:-c:v libx264 -crf 28 -preset fast -c:a aac -b:a 128k" \
    --no-warnings

done <"$NAMES_FILE"

echo "Sync complete."
