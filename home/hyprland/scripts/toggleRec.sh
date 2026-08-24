#!/usr/bin/env bash

SAVE_DIR="$HOME/videos/rec"
PID_FILE="/tmp/gpu-screen-recorder-rec.pid"
mkdir -p "$SAVE_DIR"

rerange() {
  local val=$1 low1=$2 high1=$3 low2=$4 high2=$5
  echo "scale=10; (($val - $low1) / ($high1 - $low1)) * ($high2 - $low2) + $low2" | bc -l
}

# 1. Check if a manual recording is already running (via PID file)
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  kill -SIGINT "$(cat "$PID_FILE")"
  rm -f "$PID_FILE"

  LATEST_FILE=$(find "$SAVE_DIR" -maxdepth 1 -name "*.mp4" -printf '%T+ %p\n' | sort -r | head -1 | cut -d' ' -f2-)

  if [[ $(alwaysFocusedInputBox --yes-no --title "Recording saved. Keep it?" --yes-text "Keep" --no-text "Delete") == no ]]; then
    rm "$LATEST_FILE"
    notify-send -e -t 1000 "Deleted" "File removed."
  fi
else
  # Stale PID file cleanup
  rm -f "$PID_FILE"

  # 2. Select region
  RAW_GEOM=$(slurp)
  [ -z "$RAW_GEOM" ] && exit 1

  # Extract X, Y, W, H from "X,Y WxH"
  read -r X Y W H <<<"$(echo "$RAW_GEOM" | sed -E 's/([0-9]+),([0-9]+) ([0-9]+)x([0-9]+)/\1 \2 \3 \4/')"

  # Source bounds: X in [2000, 3920], Y in [0, 1081]
  # Target bounds: X in [0, 1920], Y in [1052, 2132]
  NEW_X=$(printf "%.0f" "$(rerange "$X" 2000 3920 0 1920)")
  NEW_Y=$(printf "%.0f" "$(rerange "$Y" 0 1081 1052 2132)")
  NEW_W=$(printf "%.0f" "$(rerange "$W" 0 1920 0 1920)")
  NEW_H=$(printf "%.0f" "$(rerange "$H" 0 1081 0 1080)")

  # Format geometry for gsr (WxH+X+Y)
  GEOM="${NEW_W}x${NEW_H}+${NEW_X}+${NEW_Y}"

  # 3. Prepare default filename
  DEFAULT_NAME="rec_$(date +%Y-%m-%d_%H-%M-%S).mp4"

  # 4. Ask user for a name (pre-filled with default)
  USER_FILENAME=$(alwaysFocusedInputBox --title "Save Recording As" --text "Enter filename:" --default-text "$DEFAULT_NAME")

  # If user cancels the name prompt, exit
  [ -z "$USER_FILENAME" ] && exit 1

  # Ensure it ends with .mp4
  [[ "$USER_FILENAME" != *.mp4 ]] && USER_FILENAME="${USER_FILENAME}.mp4"

  FINAL_PATH="$SAVE_DIR/$USER_FILENAME"

  notify-send -e -t 1000 "Recorder" "Recording started: $USER_FILENAME"

  # 5. Launch recorder and store its PID
  gpu-screen-recorder -w "$GEOM" -f 60 -a "default_output" -k hevc_vulkan -o "$FINAL_PATH" &
  echo $! >"$PID_FILE"
fi
