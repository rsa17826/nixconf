#!/usr/bin/env bash

# 1. Capture the full screen immediately to freeze the moment
TEMP_IMG=$(mktemp)
grim "$TEMP_IMG"

# 2. Select the crop region using slurp
# The format string converts slurp's output into ImageMagick geometry (WxH+X+Y)
REGION=$(slurp -f "%wx%h+%x+%y")

# If the user cancels slurp (e.g., presses Escape), clean up and exit
if [ -z "$REGION" ]; then
  rm -f "$TEMP_IMG"
  exit 0
fi

# 3. Crop the frozen screenshot using magick and pipe it directly to Satty
# '+repage' resets the canvas coordinates so Satty doesn't misbehave
magick "$TEMP_IMG" -crop "$REGION" +repage png:-

# 4. Clean up the temporary full screenshot
rm -f "$TEMP_IMG"
