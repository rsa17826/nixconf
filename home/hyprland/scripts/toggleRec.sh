#!/usr/bin/env bash

SAVE_DIR="$HOME/videos/rec"
PID_FILE="/tmp/gpu-screen-recorder-rec.pid"
mkdir -p "$SAVE_DIR"

# 1. Check if a manual recording is already running (via PID file)
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  kill -SIGINT "$(cat "$PID_FILE")"
  rm -f "$PID_FILE"

  LATEST_FILE=$(find "$SAVE_DIR" -maxdepth 1 -name "*.mp4" -printf '%T+ %p\n' | sort -r | head -1 | cut -d' ' -f2-)
  if ! GTK_THEME=Adwaita:dark zenity --question --text="Recording saved. Keep it?" --ok-label="Keep" --cancel-label="Delete"; then
    rm "$LATEST_FILE"
    notify-send -e -t 1000 "Deleted" "File removed."
  fi
else
  # Stale PID file cleanup
  rm -f "$PID_FILE"

  # 2. Select region
  RAW_GEOM=$(slurp)
  [ -z "$RAW_GEOM" ] && exit 1

  # Format geometry for gsr
  GEOM=$(echo "$RAW_GEOM" | sed -E 's/([0-9]+),([0-9]+) ([0-9]+x[0-9]+)/\3+\1+\2/')

  # 3. Prepare default filename
  DEFAULT_NAME="rec_$(date +%Y-%m-%d_%H-%M-%S).mp4"

  # 4. Ask user for a name (pre-filled with default)
  USER_FILENAME=$(GTK_THEME=Adwaita:dark zenity --entry --title="Save Recording As" --text="Enter filename:" --entry-text="$DEFAULT_NAME")

  # If user cancels the name prompt, exit
  [ -z "$USER_FILENAME" ] && exit 1

  # Ensure it ends with .mp4
  [[ "$USER_FILENAME" != *.mp4 ]] && USER_FILENAME="${USER_FILENAME}.mp4"

  FINAL_PATH="$SAVE_DIR/$USER_FILENAME"

  notify-send -e -t 1000 "Recorder" "Recording started: $USER_FILENAME"

  # 5. Launch recorder and store its PID
  gpu-screen-recorder -w region -region "$GEOM" -f 60 -a "default_output" -o "$FINAL_PATH"
fi
