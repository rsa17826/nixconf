#!/usr/bin/env bash
# focus-dir.sh — Focus left/right without wrapping
# Usage: focus-dir.sh l|r
# Checks that a window exists in the direction before dispatching,
# so you don't wrap around when at the first/last window.

DIR=$1

# Get all necessary data in one JSON blob to minimize hyprctl calls
# We grab the active window and the full client list at once.
DATA=$(hyprctl -j clients)
ACTIVE=$(hyprctl -j activewindow)

# Use jq to perform the logic and output a command for the shell to execute
# This avoids multiple subshells and conditional checks in Bash.

# Execute the command if jq returned one
eval "$(jq -r --arg dir "$DIR" --argjson act "$ACTIVE" '
  if ($act | length) == 0 then empty
  else
    . as $clients |
    $act.at[0] as $ax |
    $act.workspace.id as $ws |

    # Check if any window exists in the specified direction
    if ($dir == "l") then
      any($clients[]; .workspace.id == $ws and .floating == false and .at[0] < $ax)
    else
      any($clients[]; .workspace.id == $ws and .floating == false and .at[0] > $ax)
    end

    # If found, output the dispatch command
    | if . then "hyprctl dispatch layoutmsg focus \($dir)" else empty end
  end
' <<<"$DATA")"
