#!/usr/bin/env bash
# focus-dir.sh — Focus left/right without wrapping
# Usage: focus-dir.sh l|r
# Checks that a window exists in the direction before dispatching,
# so you don't wrap around when at the first/last window.

DIR=$1

ACTIVE=$(hyprctl activewindow -j 2>/dev/null)
[ -z "$ACTIVE" ] && exit 0

ACTIVE_X=$(echo "$ACTIVE" | jq '.at[0]')
WORKSPACE=$(echo "$ACTIVE" | jq '.workspace.id')

case "$DIR" in
  l)
    HAS=$(hyprctl clients -j | jq "[.[] | select(.workspace.id == $WORKSPACE and .floating == false and .at[0] < $ACTIVE_X)] | length > 0")
    [ "$HAS" = "true" ] && hyprctl dispatch layoutmsg "focus l"
    ;;
  r)
    HAS=$(hyprctl clients -j | jq "[.[] | select(.workspace.id == $WORKSPACE and .floating == false and .at[0] > $ACTIVE_X)] | length > 0")
    [ "$HAS" = "true" ] && hyprctl dispatch layoutmsg "focus r"
    ;;
esac
