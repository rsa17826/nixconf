#!/usr/bin/env bash

VIDEO_DIR="$HOME/videos/flashback"
MAX_WAIT=5 # Seconds to wait for the new file
START_TIME=$(date +%s)

# 1. Get the current newest file
LAST_VIDEO=$(find "$VIDEO_DIR" -maxdepth 1 -name "*.mp4" -printf '%T+ %p\n' | sort -r | head -1 | cut -d' ' -f2-)

# 2. Trigger the save — target only the flashback instance (identified by -r flag)
pkill -SIGUSR1 -f "gpu-screen-recorder.*-r "

while true; do
  CURRENT_VIDEO=$(find "$VIDEO_DIR" -maxdepth 1 -name "*.mp4" -printf '%T+ %p\n' | sort -r | head -1 | cut -d' ' -f2-)
  NOW=$(date +%s)

  # Check if a new file appeared
  if [ "$CURRENT_VIDEO" != "$LAST_VIDEO" ] && [ -f "$CURRENT_VIDEO" ]; then
    FOUND=true
    break
  fi

  # Check if we have exceeded the 5-second limit
  if [ $((NOW - START_TIME)) -ge "$MAX_WAIT" ]; then
    FOUND=false
    break
  fi

  sleep 0.2
done

# 3. Handle Result
if [ "$FOUND" = true ]; then
  # Ask the user how many seconds to keep from the end of the video
  TRIM_SECS=$(alwaysFocusedInputBox --title "Trim Clip" --text "Enter seconds to keep from the end (e.g., 30):" --entry-text "30")

  # If the user cancels or provides no input, exit without deleting anything
  if [ -z "$TRIM_SECS" ]; then
    notify-send "Cancelled" "No trimming performed. Original video kept."
    exit 0
  fi

  # Generate temporary filename for the trimmed version
  TRIMMED_VIDEO="${CURRENT_VIDEO%.mp4}_trimmed.mp4"

  # Use ffmpeg to extract the last X seconds cleanly without re-encoding
  if ffmpeg -sseof "-$TRIM_SECS" -i "$CURRENT_VIDEO" -c copy "$TRIMMED_VIDEO" -y -loglevel error; then
    # Move original to trash
    trash "$CURRENT_VIDEO"
    # Rename the trimmed version to the original filename
    mv "$TRIMMED_VIDEO" "$CURRENT_VIDEO"
    notify-send "Success" "Trimmed to last ${TRIM_SECS}s and saved."
  else
    notify-send "Error" "Failed to trim the video."
    # Clean up temp file if it was created but failed
    [ -f "$TRIMMED_VIDEO" ] && rm "$TRIMMED_VIDEO"
  fi
else
  notify-send "Error" "Save timed out after ${MAX_WAIT}s."
fi
