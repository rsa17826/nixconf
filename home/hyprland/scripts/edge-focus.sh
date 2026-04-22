#!/usr/bin/env bash
# edge-focus.sh — Daemon: mouse hits screen edge → focus next window + warp cursor to center
# Add to hyprland.conf:  exec-once = ~/.config/hypr/scripts/edge-focus.sh

BORDER=5          # px from screen edge that triggers focus change
COOLDOWN_MS=700   # ms to ignore further triggers after one fires

focus_and_warp() {
    local dir=$1

    # Only focus if a window actually exists in that direction (no wrapping)
    local active wx workspace has_win
    active=$(hyprctl activewindow -j 2>/dev/null)
    [ -z "$active" ] && return

    wx=$(echo "$active" | jq '.at[0]')
    workspace=$(echo "$active" | jq '.workspace.id')

    if [ "$dir" = "l" ]; then
        has_win=$(hyprctl clients -j | jq "[.[] | select(.workspace.id == $workspace and .floating == false and .at[0] < $wx)] | length > 0")
    else
        has_win=$(hyprctl clients -j | jq "[.[] | select(.workspace.id == $workspace and .floating == false and .at[0] > $wx)] | length > 0")
    fi

    [ "$has_win" != "true" ] && return

    # Move focus
    hyprctl dispatch layoutmsg "focus $dir" >/dev/null

    # Wait for layout to settle before reading new window position
    sleep 0.12

    # Warp cursor to center of newly focused window
    local win wax way waw wah
    win=$(hyprctl activewindow -j 2>/dev/null)
    wax=$(echo "$win" | jq '.at[0]')
    way=$(echo "$win" | jq '.at[1]')
    waw=$(echo "$win" | jq '.size[0]')
    wah=$(echo "$win" | jq '.size[1]')
    hyprctl dispatch movecursor "$((wax + waw / 2))" "$((way + wah / 2))" >/dev/null
}

LAST_TRIGGER=0

# Listen to Hyprland socket events using process substitution so variables persist
while IFS= read -r line; do
    # Only care about mouse movement events
    [[ "$line" != mousemove* ]] && continue

    # Debounce
    NOW=$(date +%s%3N)
    (( NOW - LAST_TRIGGER < COOLDOWN_MS )) && continue

    # Parse cursor X from "mousemove>>X,Y"
    COORDS="${line#mousemove>>}"
    CX="${COORDS%,*}"

    # Get focused monitor: x offset and logical width
    read -r MON_X MON_W < <(
        hyprctl monitors -j | jq -r '
            .[] | select(.focused == true) | "\(.x) \(.width)"
        '
    )

    # Trigger on right edge
    if (( CX >= MON_X + MON_W - BORDER )); then
        focus_and_warp r
        LAST_TRIGGER=$(date +%s%3N)
    # Trigger on left edge
    elif (( CX <= MON_X + BORDER )); then
        focus_and_warp l
        LAST_TRIGGER=$(date +%s%3N)
    fi

done < <(socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock")
