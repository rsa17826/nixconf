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
    disable_shader "$shader_name"
  else
    enable_shader "$shader_name"
  fi
}

disable_shader() {
  local name=$1 # Accept the argument
  sed -i "/^$name$/d" "$STATE_FILE"
  echo "Disabled $name"
  rebuild_stack
}

enable_shader() {
  local name=$1 # Accept the argument
  # Extra safety: don't add if it's already there
  if ! grep -qx "$name" "$STATE_FILE"; then
    echo "$name" >>"$STATE_FILE"
  fi
  echo "Enabled $name"
  rebuild_stack
}

rebuild_stack() {
  local active_shaders
  active_shaders=$(cat "$STATE_FILE" 2>/dev/null)

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
      [ -z "$name" ] && continue
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
enable) enable_shader "$2" ;;
disable) disable_shader "$2" ;;
enabled)
  if [ -n "$2" ]; then
    # Check if a specific shader is in the state file
    grep -qx "$2" "$STATE_FILE"
  else
    # Default behavior: list all
    if [ -s "$STATE_FILE" ]; then
      echo "Currently active shaders:"
      sed 's/^/  - /' "$STATE_FILE"
    else
      echo "None"
    fi
  fi
  ;;
clear)
  : >"$STATE_FILE"
  rebuild_stack
  ;;
*) echo "Usage: shaderstack toggle <filename_without_ext> | clear" ;;
esac
