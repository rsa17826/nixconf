#!/usr/bin/env bash

# Directories
SHADER_DIR="$HOME/.config/hypr/shaders"
TEMP_SHADER="$HOME/.config/hypr/shaders/.active_stack.glsl"
STATE_FILE="/tmp/shaderstack_state"

# Ensure state file exists
touch "$STATE_FILE"

toggle_shader() {
  local shader_name=$1
  local shader_path="$SHADER_DIR/$shader_name.glsl"

  if [ ! -f "$shader_path" ]; then
    echo "Error: Shader $shader_name not found in $SHADER_DIR"
    exit 1
  fi

  # Check if already in state
  if grep -qx "$shader_name" "$STATE_FILE"; then
    # Remove it
    sed -i "/^$shader_name$/d" "$STATE_FILE"
    echo "Disabled $shader_name"
  else
    # Add it
    echo "$shader_name" >>"$STATE_FILE"
    echo "Enabled $shader_name"
  fi

  rebuild_stack
}

rebuild_stack() {
  local active_shaders=$(cat "$STATE_FILE")

  if [ -z "$active_shaders" ]; then
    hyprctl eval "hl.config({ decoration = { screen_shader = '' } })"
    return
  fi

  {
    echo "precision highp float;"
    echo "varying vec2 v_texcoord;"
    echo "uniform sampler2D tex;"
    echo ""
    echo "void main() {"
    echo "    vec4 pix = texture2D(tex, v_texcoord);"

    while read -r name; do
      echo "    // --- Layer: $name ---"
      echo "    {"
      # 1. Extract the code inside main()
      # 2. Remove any line that tries to declare 'gl_FragColor'
      # 3. Replace the final assignment so it updates our global 'pix'
      sed -n '/main()/,/}/p' "$SHADER_DIR/$name.glsl" |
        sed '1d;$d' |
        sed 's/gl_FragColor\s*=\s*/pix = /g'
      echo "    }"
    done <<<"$active_shaders"

    echo ""
    echo "    gl_FragColor = pix;"
    echo "}"
  } >"$TEMP_SHADER"

  hyprctl eval "hl.config({ decoration = { screen_shader = '$TEMP_SHADER' } })"
}
case $1 in
toggle) toggle_shader "$2" ;;
clear)
  echo "" >"$STATE_FILE"
  rebuild_stack
  ;;
*) echo "Usage: shaderstack toggle <filename_without_ext> | clear" ;;
esac
