#!/usr/bin/env bash

download_media() {
  local mode=$1
  local url=$2

  # Format: Title - By Creator.ext
  local output_tmpl="%(title)s - %(uploader)s.%(ext)s"

  # Logic:
  # 1. Best video <= 720p (Precedence: 720 > 480 > 360)
  # 2. If none, get the absolute worst video available (the smallest above 720p)
  local vid_format="bestvideo[height<=720]+bestaudio/worstvideo[height>720]+bestaudio/best"

  # Base arguments including Brave cookies
  local cmd_args=(
    "--cookies-from-browser" "brave"
    "-o" "$output_tmpl"
    "--newline"
    "$url"
  )

  if [[ "$mode" == "Audio" ]]; then
    # Audio: Extract, keep thumbnail, add metadata, use uploader name
    cmd_args+=("-x" "--audio-format" "mp3" "--embed-thumbnail" "--add-metadata")
  else
    # Video: Apply the 720p-down / 1080p-up logic
    cmd_args+=("-f" "$vid_format" "--merge-output-format" "mp4")
  fi

  yt-dlp "${cmd_args[@]}" |
    stdbuf -oL sed -n 's/^\[download\][[:space:]]*\([0-9.]*\)% of.*/\1/p' |
    zenity --progress \
      --title="Downloading $mode" \
      --text="Fetching: $url" \
      --percentage=0 --auto-close --width=450
}

echo "Clipboard Monitor Active (Brave Cookies enabled)..."

LAST_CLIP=""

while true; do
  # Get clipboard, strip newlines/spaces
  CURRENT_CLIP=$(wl-paste --type text --no-newline 2>/dev/null | xargs)

  # Check if it's a new valid link
  if [[ "$CURRENT_CLIP" != "$LAST_CLIP" ]]; then
    if [[ "$CURRENT_CLIP" =~ \.(mp3|mp4|webm|m3u8) || "$CURRENT_CLIP" == *"twitch.tv"* || "$CURRENT_CLIP" == *"youtube.com"* || "$CURRENT_CLIP" == *"youtu.be"* ]]; then

      # Popup with 5s timeout
      # Default behavior is 'Abort' if no action is taken
      CHOICE=$(zenity --list --title="Media Link Detected" \
        --text="Format for: ${CURRENT_CLIP:0:50}..." \
        --column="Action" "Video" "Audio" "Abort" \
        --timeout=5 --width=400 --height=250)

      case "$CHOICE" in
      "Video")
        download_media "Video" "$CURRENT_CLIP"
        ;;
      "Audio")
        download_media "Audio" "$CURRENT_CLIP"
        ;;
      *)
        echo "Dismissed."
        ;;
      esac

      # Mark as seen so we don't spam the popup
      LAST_CLIP="$CURRENT_CLIP"
    fi
  fi

  sleep 1
done
