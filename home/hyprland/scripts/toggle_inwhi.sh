#!/usr/bin/env bash

SHADER_PATH="$HOME/.config/hypr/shaders/inwhi.glsl"
CURRENT_SHADER=$(hyprctl getoption decoration:screen_shader -j | jq -r '.str')

if [ "$CURRENT_SHADER" = "$SHADER_PATH" ]; then
  hyprctl eval "hl.config({ decoration = { screen_shader = '' } })"
  echo "Shader disabled."
else
  hyprctl eval "hl.config({ decoration = { screen_shader = '$SHADER_PATH' } })"
  echo "Shader enabled: $SHADER_PATH"
fi