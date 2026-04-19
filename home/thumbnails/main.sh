#!/usr/bin/env bash
size="$1"
dir="$(realpath "$2")"
output="$3"

while true; do
  if [[ "$dir" == "/" ]]; then
    rm -f \
      "$HOME/.cache/thumbnails/normal/$(printf '%s' "$4" | md5sum | cut -d ' ' -f1).png" \
      "$HOME/.thumbnails/normal/$(printf '%s' "$4" | md5sum | cut -d ' ' -f1).png" \
      "$HOME/.cache/thumbnails/large/$(printf '%s' "$4" | md5sum | cut -d ' ' -f1).png" \
      "$HOME/.thumbnails/large/$(printf '%s' "$4" | md5sum | cut -d ' ' -f1).png"
    exit 1
  fi

  if [[ -f "$dir/.foldericon.png" ]]; then
    magick "$dir/.foldericon.png" -thumbnail "$size" "$output" 2>/dev/null
    exit 0
  fi
  if [[ -f "$dir/.favicon.ico" ]]; then
    magick "$dir/.favicon.ico" -thumbnail "$size" "$output" 2>/dev/null
    exit 0
  fi
  if [[ -f "$dir/.favicon.png" ]]; then
    magick "$dir/.favicon.png" -thumbnail "$size" "$output" 2>/dev/null
    exit 0
  fi

  # Move one directory up
  dir="$(dirname "$dir")"
done
