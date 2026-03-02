#!/usr/bin/env bash

VIDEO_DIR="$HOME/videos/flashback"
MAX_WAIT=5 # Seconds to wait for the new file
START_TIME=$(date +%s)

# 1. Get the current newest file
LAST_VIDEO=$(ls -t "$VIDEO_DIR"/*.mp4 2>/dev/null | head -1)

# 2. Trigger the save
killall -SIGUSR1 gpu-screen-recorder

while true; do
  CURRENT_VIDEO=$(ls -t "$VIDEO_DIR"/*.mp4 2>/dev/null | head -1)
  NOW=$(date +%s)

  # Check if a new file appeared
  if [ "$CURRENT_VIDEO" != "$LAST_VIDEO" ] && [ -f "$CURRENT_VIDEO" ]; then
    FOUND=true
    break
  fi

  # Check if we have exceeded the 5-second limit
  # (Now - Start_Time >= Max_Wait)
  if [ $((NOW - START_TIME)) -ge "$MAX_WAIT" ]; then
    FOUND=false
    break
  fi

  sleep 0.2
done

# 4. Handle Result
if [ "$FOUND" = true ]; then
  mpv "$CURRENT_VIDEO"
  if ! zenity --question --text="Keep this clip?" --title="Replay Saved"; then
    rm "$CURRENT_VIDEO"
    notify-send "Deleted" "Recording removed."
  fi
else
  notify-send "Error" "Save timed out after ${MAX_WAIT}s."
fi
