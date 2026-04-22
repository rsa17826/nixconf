#!/usr/bin/env bash

# CONFIG
BORDER=2
# COOLDOWN=0.4
# LAST_TRIGGER=0

# 1. Get Monitor Dimensions
read -r MON_X MON_Y MON_W MON_H < <(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.x) \(.y) \(.width) \(.height)"')

RIGHT_EDGE=$((MON_X + MON_W - BORDER))
LEFT_EDGE=$((MON_X + BORDER))
BOTTOM_EDGE=$((MON_Y + MON_H - BORDER))
TOP_EDGE=$((MON_Y + BORDER))
GX=$((MON_W / 2))
GY=$((MON_H / 2))

# The absolute pixel value for the "far" edge (adjusting for offset)
Y_MAX=$((MON_Y + MON_H - 5)) # 5px offset so it doesn't immediately re-trigger
Y_MIN=$((MON_Y + 5))

while true; do
  POS=$(hyprctl cursorpos)
  CX=${POS%%,*}
  CY=${POS#*, }

  # NOW=$EPOCHREALTIME

  # if (($(echo "$NOW - $LAST_TRIGGER > $COOLDOWN" | bc -l))); then
  # --- Horizontal: Switch Windows ---
  if ((CX >= RIGHT_EDGE)); then
    hyprctl dispatch movefocus r
    # LAST_TRIGGER=$NOW
  elif ((CX <= LEFT_EDGE)); then
    hyprctl dispatch movefocus l
    # LAST_TRIGGER=$NOW

  # --- Vertical: Switch Workspaces + Mouse Warp ---
  elif ((CY >= BOTTOM_EDGE)); then
    # Move to next workspace
    hyprctl dispatch workspace m+1
    # Warp mouse to Top (Y_MIN) keeping same X
    # hyprctl dispatch movecursor "$CX $Y_MIN"
    hyprctl dispatch movecursor "$GX $GY"
    # LAST_TRIGGER=$NOW

  elif ((CY <= TOP_EDGE)); then
    # Move to previous workspace
    hyprctl dispatch workspace m-1
    # Warp mouse to Bottom (Y_MAX) keeping same X
    # hyprctl dispatch movecursor "$CX $Y_MAX"
    hyprctl dispatch movecursor "$GX $GY"
    # LAST_TRIGGER=$NOW
  fi
  # fi

  sleep 0.05
done
