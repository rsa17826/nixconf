#!/usr/bin/env bash

# 1. Capture the 'before' state
LAST_VIDEO=$(ls -t ~/Videos/flashback/*.mp4 2>/dev/null | head -1)

# 2. Tell the recorder to save
killall -SIGUSR1 gpu-screen-recorder

# 3. Loop until the newest file is different from the 'before' state
while true; do
  CURRENT_VIDEO=$(ls -t ~/Videos/flashback/*.mp4 2>/dev/null | head -1)
  if [ "$CURRENT_VIDEO" != "$LAST_VIDEO" ] && [ -f "$CURRENT_VIDEO" ]; then
    break
  fi

  sleep 0.2 # Check every 200ms to be responsive
done

# 4. Now that we have the new file, open it
mpv "$CURRENT_VIDEO"

# 5. Ask to delete
if ! zenity --question --text="Keep this clip?" --ok-label="Keep" --cancel-label="Delete"; then
  rm "$CURRENT_VIDEO"
  notify-send "Deleted" "Recording removed."
fi
