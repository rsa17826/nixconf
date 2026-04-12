#!/usr/bin/env bash
# Usage: godot-debug-key.sh F5
# Sends the given key to the Godot window, but only when the currently
# active window title ends with "(DEBUG)".
KEY="$1"

active=$(hyprctl activewindow -j)
title=$(echo "$active" | jq -r '.title')
# from=$(echo "$active" | jq -r '.address')

# Match: anything followed by a space and "(DEBUG)" at end of title
if [[ "$title" =~ ^.*[[:space:]]\(DEBUG\)$ ]]; then
  godot=$(hyprctl clients -j |
    jq -r '[.[] | select(.class | ascii_downcase | test("godot"))][0].address')

  if [[ -n "$godot" && "$godot" != "null" ]]; then
    hyprctl dispatch focuswindow "address:$godot"
    sleep 0.04
    hyprctl dispatch sendshortcut ",$KEY,class:^[Gg]odot"
    # sleep 0.04
    # hyprctl dispatch focuswindow "address:$from"
  else
    hyprctl dispatch sendshortcut ",$KEY,class:^[Gg]odot"
  fi
else
  hyprctl dispatch sendshortcut ",$KEY,class:^[Gg]odot"
fi
