#!/usr/bin/env bash

# Pathing
SHADER_TEMPLATE="$HOME/.config/hypr/shaders/clone_region.glsl"
SHADER_RUNTIME="/tmp/active_clone.glsl"

if shaderstack enabled "$SHADER_RUNTIME"; then
  shaderstack disable "$SHADER_RUNTIME"
  exit 0
fi

# 1. Screen Resolution + Position
SCREEN_W=1920
SCREEN_H=1080
MON_X=2000
MON_ID=$(hyprctl monitors -j | jq -r '.[] | select(.name=="HDMI-A-1")|.id')
# 2. Select region with slurp
GEOM=$(slurp -f "%x %y %w %h")
[ -z "$GEOM" ] && exit 1
read -r X Y W H <<<"$GEOM"

# 3. Calculate normalized source region (0.0 to 1.0)
OFF_X=$(printf "%.6f" "$(echo "scale=6; ($X - $MON_X) / $SCREEN_W" | bc)")
OFF_Y=$(printf "%.6f" "$(echo "scale=6; $Y / $SCREEN_H" | bc)")
SIZE_W=$(printf "%.6f" "$(echo "scale=6; $W / $SCREEN_W" | bc)")
SIZE_H=$(printf "%.6f" "$(echo "scale=6; $H / $SCREEN_H" | bc)")

# 4. Calculate display size & centering offset
# Compare region AR (W/H) vs screen AR (SCREEN_W/SCREEN_H)
REGION_WIDER=$(echo "$W * $SCREEN_H > $H * $SCREEN_W" | bc)

if [ "$REGION_WIDER" -eq 1 ]; then
  # Fit to full width; height shrinks (letterbox top/bottom)
  DISP_W="1.000000"
  DISP_H=$(printf "%.6f" "$(echo "scale=6; ($H * $SCREEN_W) / ($W * $SCREEN_H)" | bc)")
  DISP_OFF_X="0.000000"
  DISP_OFF_Y=$(printf "%.6f" "$(echo "scale=6; (1.0 - $DISP_H) / 2.0" | bc)")
else
  # Fit to full height; width shrinks (pillarbox left/right)
  DISP_H="1.000000"
  DISP_W=$(printf "%.6f" "$(echo "scale=6; ($W * $SCREEN_H) / ($H * $SCREEN_W)" | bc)")
  DISP_OFF_Y="0.000000"
  DISP_OFF_X=$(printf "%.6f" "$(echo "scale=6; (1.0 - $DISP_W) / 2.0" | bc)")
fi

# 5. Stamp values into the runtime shader
sed \
  -e "s|vec2 offset = .*|vec2 offset = vec2($OFF_X, $OFF_Y);|" \
  -e "s|vec2 size = .*|vec2 size = vec2($SIZE_W, $SIZE_H);|" \
  -e "s|vec2 dispSize = .*|vec2 dispSize = vec2($DISP_W, $DISP_H);|" \
  -e "s|vec2 dispOffset = .*|vec2 dispOffset = vec2($DISP_OFF_X, $DISP_OFF_Y);|" \
  -e "s|int MON = -1|int MON = $MON_ID|" \
  "$SHADER_TEMPLATE" >"$SHADER_RUNTIME"

# 6. Apply
shaderstack enable "$SHADER_RUNTIME"
