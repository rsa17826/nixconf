#!/bin/bash

# Path to your shader file
SHADER_PATH="~/.config/hypr/shaders/inwhi.glsl"

# Check if the shader is currently applied
CURRENT_SHADER=$(hyprctl keyword decoration:screen_shader)

if [ "$CURRENT_SHADER" == "$SHADER_PATH" ]; then
  # If the shader is already applied, disable it
  hyprctl keyword decoration:screen_shader ""
else
  # If the shader is not applied, enable it
  hyprctl keyword decoration:screen_shader "$SHADER_PATH"
fi
