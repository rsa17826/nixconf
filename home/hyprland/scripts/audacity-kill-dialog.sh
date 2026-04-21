#!/usr/bin/env bash

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

socat -U - UNIX-CONNECT:"$SOCKET" |
  while read -r line; do
    case "$line" in
      openwindow*save\ changes*|openwindow*Save\ changes*)
        pkill -9 audacity
        rm -f /var/tmp/audacity-nyix/*.aup3unsaved*
        ;;
    esac
  done