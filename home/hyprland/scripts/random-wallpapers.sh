#!/usr/bin/env bash
# Randomly cycles wallpapers for hyprpaper
# Usage: wallpaper-cycle.sh [interval_seconds]

WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"
INTERVAL="${1:-300}" # default: 5 minutes

# Build the wallpaper list using a bash glob (avoids find locale issues)
shopt -s nullglob
WALLPAPERS=("$WALLPAPER_DIR"/videoframe_*.png)

if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
  echo "No wallpapers found in $WALLPAPER_DIR matching videoframe_*.png" >&2
  exit 1
fi

echo "Found ${#WALLPAPERS[@]} wallpapers. Cycling every ${INTERVAL}s."
RESIZE_TYPE="fit"
export AWWW_TRANSITION_FPS="${AWWW_TRANSITION_FPS:-60}"
export AWWW_TRANSITION_STEP="${AWWW_TRANSITION_STEP:-2}"
last_index=-1

while true; do
  # Pick a random index, avoiding repeating the same wallpaper back-to-back
  while true; do
    index=$((RANDOM % ${#WALLPAPERS[@]}))
    [[ $index -ne $last_index ]] && break
  done
  last_index=$index
  if [[ "$(hyprctl -j activewindow)" != "{}" ]]; then
    wp="${WALLPAPERS[$index]}"
    echo "Setting: $(basename "$wp")"

    awww img --resize="$RESIZE_TYPE" "$wp"

    sleep "$INTERVAL"
  fi
done
