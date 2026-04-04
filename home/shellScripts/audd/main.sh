#!/usr/bin/env bash

# 1. Get clipboard content using wl-paste
# The -n flag ensures we don't append a trailing newline if it's already there
raw_clipboard=$(wl-paste -n)

# 2. Extract and clean URLs
# - grep: extracts anything starting with http(s)
# - sed: removes time parameters (&t or &startTime)
# - tr: removes single and double quotes
urls=$(echo "$raw_clipboard" | grep -oE "https?://[^[:space:]\"]+" |
  sed -E 's/(&t=|&startTime=)[0-9]+//g' |
  tr -d "'\"")

# 3. Guard clause: Exit if no URLs found
if [ -z "$urls" ]; then
  echo "Error: No valid URLs found in the clipboard."
  exit 1
fi

# 4. Process each URL
# We use a loop to handle cases where multiple URLs are copied at once
while read -r url; do
  echo "--- Downloading: $url ---"

  yt-dlp --newline --progress --cookies-from-browser brave \
    --no-check-certificate --extract-audio \
    --remote-components ejs:github --paths "$HOME/audio/" \
    --audio-format mp3 --audio-quality 128k \
    --sponsorblock-remove "sponsor, intro, outro, selfpromo, preview, filler, interaction, music_offtopic" \
    --write-thumbnail \
    -o "%(fulltitle)s - by %(channel)s.%(ext)s" \
    "$url"

done <<<"$urls"

echo "Finished processing all links."
