#!/usr/bin/env bash

# Pathing
SHADER_TEMPLATE="$HOME/.config/hypr/shaders/clone_region.glsl"
SHADER_RUNTIME="/tmp/active_clone.glsl"
if shaderstack enabled active_clone; then
  shaderstack disable active_clone
  exit 0
fi

# 1. Get Screen Resolution
MONITOR_INFO=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true)')
SCREEN_W=$(echo "$MONITOR_INFO" | jq -r '.width')
SCREEN_H=$(echo "$MONITOR_INFO" | jq -r '.height')

# 2. Select region with slurp
GEOM=$(slurp -f "%x %y %w %h")
[ -z "$GEOM" ] && exit 1
read -r X Y W H <<<"$GEOM"

# 3. Calculate normalized source region (0.0 to 1.0)
OFF_X=$(printf "%.6f" "$(echo "scale=6; $X / $SCREEN_W" | bc)")
OFF_Y=$(printf "%.6f" "$(echo "scale=6; $Y / $SCREEN_H" | bc)")
SIZE_W=$(printf "%.6f" "$(echo "scale=6; $W / $SCREEN_W" | bc)")
SIZE_H=$(printf "%.6f" "$(echo "scale=6; $H / $SCREEN_H" | bc)")

# 4. Calculate display size with aspect-ratio-preserving black borders
#    Compare region AR (W/H) vs screen AR (SCREEN_W/SCREEN_H) using integer cross-multiply
#    to avoid floating-point issues.
#    If W * SCREEN_H > H * SCREEN_W → region is wider than screen → letterbox (bars top/bottom)
#    Otherwise                       → region is taller than screen → pillarbox (bars left/right)
REGION_WIDER=$(echo "$W * $SCREEN_H > $H * $SCREEN_W" | bc)

if [ "$REGION_WIDER" -eq 1 ]; then
  # Fit to full width; height shrinks to preserve AR
  DISP_W="1.000000"
  DISP_H=$(printf "%.6f" "$(echo "scale=6; $H * $SCREEN_W / ($W * $SCREEN_H)" | bc)")
else
  # Fit to full height; width shrinks to preserve AR
  DISP_H="1.000000"
  DISP_W=$(printf "%.6f" "$(echo "scale=6; $W * $SCREEN_H / ($H * $SCREEN_W)" | bc)")
fi

# 5. Stamp values into the runtime shader
sed \
  -e "s|vec2 offset = .*|vec2 offset = vec2($OFF_X, $OFF_Y);|" \
  -e "s|vec2 size = .*|vec2 size = vec2($SIZE_W, $SIZE_H);|" \
  -e "s|vec2 dispSize = .*|vec2 dispSize = vec2($DISP_W, $DISP_H);|" \
  "$SHADER_TEMPLATE" >"$SHADER_RUNTIME"

# 6. Apply
shaderstack enable active_clone
