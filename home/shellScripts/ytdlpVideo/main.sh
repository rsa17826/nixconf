#!/usr/bin/env bash

# 1. Define the function
download_url() {
  local url=$1
  echo "Found URL: $url"

  # Download with progress sent to Zenity
  yt-dlp -o "%(title)s.%(ext)s" "$url" --newline |
    stdbuf -oL sed -n 's/^\[download\][[:space:]]*\([0-9.]*\)% of.*/\1/p' |
    zenity --progress \
      --title="Downloading Video" \
      --text="Fetching: $url" \
      --percentage=0 \
      --auto-close \
      --width=400
}

# 2. Export the function so 'bash -c' can see it
export -f download_url

echo "Monitoring clipboard for URLs..."

# 3. Watch the clipboard
wl-paste --type text --watch bash -c '
    url=$(wl-paste)
    if [[ "$url" =~ ^https?://[^[:space:]\r\n\t]+ ]]; then
        download_url "$url"
    fi
'
