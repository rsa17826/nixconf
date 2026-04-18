#!/usr/bin/env bash

# Pathing
SHADER_TEMPLATE="$HOME/.config/hypr/shaders/clone_region.frag"
SHADER_RUNTIME="$HOME/.config/hypr/shaders/active_clone.frag"

# 1. Get Screen Resolution
# We use -j for JSON and jq for reliable parsing
MONITOR_INFO=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true)')
SCREEN_W=$(echo "$MONITOR_INFO" | jq -r '.width')
SCREEN_H=$(echo "$MONITOR_INFO" | jq -r '.height')

# 2. Select region with slurp
GEOM=$(slurp -f "%x %y %w %h")
[ -z "$GEOM" ] && exit 1
read -r X Y W H <<<"$GEOM"

# 3. Calculate normalized values (0.0 to 1.0)
# We use printf to ensure a leading zero (e.g., .5 becomes 0.5)
OFF_X=$(printf "%.4f" "$(echo "scale=4; $X / $SCREEN_W" | bc)")
OFF_Y=$(printf "%.4f" "$(echo "scale=4; $Y / $SCREEN_H" | bc)")
SIZE_W=$(printf "%.4f" "$(echo "scale=4; $W / $SCREEN_W" | bc)")
SIZE_H=$(printf "%.4f" "$(echo "scale=4; $H / $SCREEN_H" | bc)")

# 4. Update the runtime shader
# This looks for the placeholders and replaces the entire line
sed -e "s|vec2 offset = .*|vec2 offset = vec2($OFF_X, $OFF_Y);|" \
  -e "s|vec2 size = .*|vec2 size = vec2($SIZE_W, $SIZE_H);|" \
  "$SHADER_TEMPLATE" >"$SHADER_RUNTIME"

# 5. Apply
hyprctl keyword decoration:screen_shader "$SHADER_RUNTIME"
