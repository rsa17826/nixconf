#!/usr/bin/env bash

# Use $HOME instead of ~ for reliability in hyprctl
SHADER_PATH="$HOME/.config/hypr/shaders/inwhi.glsl"

# Get the actual string value of the current shader
# We use jq -r to get the raw string without quotes
CURRENT_SHADER=$(hyprctl getoption decoration:screen_shader -j | jq -r '.str')

# Check if the current shader string matches our path
if [ "$CURRENT_SHADER" = "$SHADER_PATH" ]; then
  # It's active, so clear it
  hyprctl keyword decoration:screen_shader ""
  echo "Shader disabled."
else
  # It's not active (or a different one is), so enable it
  hyprctl keyword decoration:screen_shader "$SHADER_PATH"
  echo "Shader enabled: $SHADER_PATH"
fi
