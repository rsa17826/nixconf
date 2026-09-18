#!/usr/bin/env bash

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

# Wait until the socket is actually available
while [[ ! -S "$SOCKET" ]]; do
  sleep 0.5
done

# Restart socat if it ever dies (e.g. Hyprland reloads)
while true; do
  socat -U - UNIX-CONNECT:"$SOCKET" |
    while read -r line; do
      case "$line" in
      openwindow*save\ changes* | openwindow*Save\ changes*)
        pkill -9 audacity
        rm -f /var/tmp/audacity-nyix/*.aup3unsaved*
        ;;
      esac
    done
  sleep 1
done
