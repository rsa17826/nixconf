#!/usr/bin/env bash

# This function is called by the Quickshell process
download_logic() {
  local mode=$1
  local url=$2
  # 1. REMOVE literal escaped quotes from the template.
  # The array expansion "${args[@]}" handles spaces automatically.
  local output_tmpl="%(title)s - %(uploader)s.%(ext)s"
  local vid_format="bestvideo[height<=720]+bestaudio/worstvideo[height>720]+bestaudio/best"

  # 2. Define args normally
  local args=("--cookies-from-browser" "brave" "-o" "$HOME/videos/$output_tmpl" "--newline" "--progress")
  if [[ "$mode" == "Audio" ]]; then
    # Note: Using --embed-metadata as it's the modern version of --add-metadata
    args+=("-x" "--audio-format" "mp3" "--write-thumbnail" "--convert-thumbnails" "jpg" "--embed-thumbnail" "--embed-metadata")
  else
    args+=("-f" "$vid_format" "--merge-output-format" "mp4")
  fi

  # 3. CRITICAL: Execute by passing the array and the URL as separate arguments.
  # Do NOT wrap them in one string or add extra literal quotes.
  # yt-dlp "${args[@]}" "$url">a
  yt-dlp "${args[@]}" "$url" | stdbuf -oL sed -u -n 's/.*\[download\]\s*\([0-9.]*\)%.*/\1/p'
  #  | awk '{printf "VALUE:%.0f\n", $1; fflush()}'
}

export -f download_logic

# Get the absolute path of the script directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

echo "Clipboard Monitor Active..."

LAST_CLIP=""

#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAST_CLIP=""

while true; do
  # 1. Grab clipboard content, strip newlines and surrounding whitespace
  RAW_CLIP=$(wl-paste --type text --no-newline 2>/dev/null | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  # 2. Check if clipboard changed and isn't empty
  if [[ "$RAW_CLIP" != "$LAST_CLIP" && -n "$RAW_CLIP" ]]; then

    # 3. Extract URLs and clean them using sed (removing time stamps and quotes)
    # We use a process substitution to loop through each found URL
    while read -r URL; do
      if [[ -n "$URL" ]]; then
        # 4. Launch Quickshell with the environment variable
        # Standard Quickshell usually takes the path to the main.qml or the directory
        TARGET_URL="$URL" qs -p "$SCRIPT_DIR/MediaPopup.qml" &
      fi
    done < <(echo "$RAW_CLIP" | grep -Eo 'https?://[^[:space:]"]+' |
      sed -E "s/(&t|&startTime)=[0-9]+//g" |
      tr -d "'\"" | sort -u)

    LAST_CLIP="$RAW_CLIP"
  fi

  sleep 1
done
