#!/usr/bin/env bash

# This function is called by the Quickshell process
#!/usr/bin/env bash

download_logic() {
  local mode=$1
  local url=$2
  local pid=$$ # Use the current subshell PID for the bar ID
  local output_tmpl="%(fulltitle)s - %(uploader)s.%(ext)s"

  # Initial message to create the bar
  echo "{\"progress\": 0, \"name\": \"$mode: $url\", \"color\": \"#3498db\", \"pid\": $pid}" | nc -U /tmp/progress_bars.sock

  # Run yt-dlp and pipe progress to a loop that sends updates to the socket
  # https://www.youtube.com/watch?v=7LkGQTsTXAk&t=115&startTime=0
  yt-dlp --newline --progress --cookies-from-browser brave \
    --no-check-certificate --extract-audio "$url" \
    --output ".\%(title)s.%(ext)s" \
    --remote-components ejs:github --paths "$HOME/videos/" \
    --audio-format mp3 --audio-quality 128k --sponsorblock-remove "sponsor, intro, outro, selfpromo, preview, filler, interaction, music_offtopic" \
    --write-thumbnail 2>~/ass
  #    while read -r line; do
  #   if [[ $line =~ \[download\]\ +([0-9.]+)% ]]; then
  #     local percent="${BASH_REMATCH[1]}"
  #     # Send update to socket
  #     echo "{\"progress\": $percent, \"name\": \"$HOME/videos/$output_tmpl\", \"pid\": $pid}" | nc -U /tmp/progress_bars.sock
  #   fi
  # done

  # Close the bar after 5 seconds (using the max_idle logic we built)
  echo "{\"action\": \"close\", \"pid\": $pid}" | nc -U /tmp/progress_bars.sock
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
