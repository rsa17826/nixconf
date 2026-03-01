#!/usr/bin/env bash

# 1. Signal the recorder to save
killall -SIGUSR1 gpu-screen-recorder
sleep 0.8

# 2. Find the newest video
VIDEO_FILE=$(ls -t ~/Videos/*.mp4 2>/dev/null | head -1)

if [ -z "$VIDEO_FILE" ]; then
  notify-send "Error" "No video file found."
  exit 1
fi

# 3. Open the video and WAIT for the player to close
# We use 'mpv' here because it's standard on NixOS/Hyprland,
# but you can use your preferred player.
mpv "$VIDEO_FILE"

# 4. Ask to delete using a simple Zenity dialog
if zenity --question --text="Keep the recording?" --ok-label="Keep" --cancel-label="Delete"; then
  notify-send "Saved" "Video kept at $VIDEO_FILE"
else
  rm "$VIDEO_FILE"
  notify-send "Deleted" "Recording has been removed."
fi
