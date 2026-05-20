#!/usr/bin/env bash
set -e
# Directories
SHADER_DIR="$HOME/.config/hypr/shaders"
TEMP_SHADER="$HOME/.config/hypr/.active_stack.glsl"
STATE_FILE="/tmp/shaderstack_state"

touch "$STATE_FILE"

rebuild_stack() {
  local active_shaders
  active_shaders=$(cat "$STATE_FILE" 2>/dev/null)

  # Reset to default if no shaders are active
  if [ -z "$(echo "$active_shaders" | tr -d '[:space:]')" ]; then
    hyprctl eval "hl.config({ decoration = { screen_shader = '' } })"
    return
  fi

  {
    echo "precision highp float;"
    echo "varying vec2 v_texcoord;"
    echo "uniform sampler2D tex;"
    echo "vec4 pix;" # Global pixel variable for layers to modify

    # 1. Define each shader as its own unique function
    while read -r name; do
      [ -z "$name" ] && continue
      local shader_file="$SHADER_DIR/$name.glsl"

      if [ -f "$shader_file" ]; then
        echo "// --- Function for Layer: $name ---"
        # Rename 'void main()' to a unique function name
        # Remove global headers to avoid redefinition errors
        sed -e "s/void main()/void layer_${name}()/" \
          -e '/precision/d' -e '/varying/d' -e '/uniform sampler2D tex/d' \
          -e 's/gl_FragColor/pix/g' \
          -e 's/texture2D(tex, v_texcoord)/pix/g' "$shader_file"
        echo ""
      fi
    done <<<"$active_shaders"

    # 2. Main entry point calls the functions in order
    echo "void main() {"
    echo "    pix = texture2D(tex, v_texcoord);"
    while read -r name; do
      [ -z "$name" ] && continue
      if [ -f "$SHADER_DIR/$name.glsl" ]; then
        echo "    layer_${name}();"
      fi
    done <<<"$active_shaders"
    echo "    gl_FragColor = pix;"
    echo "}"
  } >"$TEMP_SHADER"

  hyprctl eval "hl.config({ decoration = { screen_shader = '$TEMP_SHADER' } })"
}

enable_shader() {
  local name=$1
  [ -z "$name" ] && return
  if ! grep -qx "$name" "$STATE_FILE"; then
    echo "$name" >>"$STATE_FILE"
  fi
  echo "ok"
  rebuild_stack
}

disable_shader() {
  local name=$1
  sed -i "/^$name$/d" "$STATE_FILE"
  # Auto-clean empty lines to prevent the " - " blank entries
  sed -i '/^$/d' "$STATE_FILE"
  echo "ok"
  rebuild_stack
}

case $1 in
enable) enable_shader "$2" ;;
disable) disable_shader "$2" ;;
toggle)
  # Change $FILE_STATE to $STATE_FILE
  if grep -qx "$2" "$STATE_FILE"; then
    disable_shader "$2"
  else
    enable_shader "$2"
  fi
  ;;
enabled)
  if [ -n "$2" ]; then
    grep -qx "$2" "$STATE_FILE" # Silent exit code for scripts [cite: 1, 9]
  else
    [ -s "$STATE_FILE" ] && sed 's/^/  - /' "$STATE_FILE" || echo "None"
  fi
  ;;
clear)
  : >"$STATE_FILE" # SC2188 fix [cite: 1]
  rebuild_stack
  ;;
esac
