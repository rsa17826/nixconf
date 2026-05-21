#!/usr/bin/env bash
set -e

# Directories
SHADER_DIR="$HOME/.config/hypr/shaders"
TEMP_SHADER="/tmp/.active_stack.glsl"
STATE_FILE="/tmp/shaderstack_state"

touch "$STATE_FILE"

# Resolve target input: Convert to an absolute path if it's a file,
# otherwise treat it as a standard shader name.
TARGET=""
if [ -n "$2" ]; then
  if [ -f "$2" ]; then
    TARGET=$(realpath "$2")
  else
    TARGET="$2"
  fi
fi

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
    while read -r entry; do
      [ -z "$entry" ] && continue

      local shader_file=""
      if [ -f "$entry" ]; then
        shader_file="$entry"
      else
        shader_file="$SHADER_DIR/$entry.glsl"
      fi

      if [ -f "$shader_file" ]; then
        # Sanitize the entry string into a valid GLSL function name identifier (Fixes SC2001)
        local func_suffix="${entry//[^a-zA-Z0-9_]/_}"

        echo "// --- Function for Layer: $entry ---"
        # Rename 'void main()' to a unique function name
        # Remove global headers to avoid redefinition errors
        sed -e "s/void main()/void layer_${func_suffix}()/" \
          -e '/precision/d' -e '/varying/d' -e '/uniform sampler2D tex/d' \
          -e 's/gl_FragColor/pix/g' \
          -e 's/texture2D(tex, v_texcoord)/pix/g' "$shader_file"
        echo ""
      fi
    done <<<"$active_shaders"

    # 2. Main entry point calls the functions in order
    echo "void main() {"
    echo "    pix = texture2D(tex, v_texcoord);"
    while read -r entry; do
      [ -z "$entry" ] && continue

      local shader_file=""
      if [ -f "$entry" ]; then
        shader_file="$entry"
      else
        shader_file="$SHADER_DIR/$entry.glsl"
      fi

      if [ -f "$shader_file" ]; then
        # Fixes SC2001
        local func_suffix="${entry//[^a-zA-Z0-9_]/_}"
        echo "    layer_${func_suffix}();"
      fi
    done <<<"$active_shaders"
    echo "    gl_FragColor = pix;"
    echo "}"
  } >"$TEMP_SHADER"

  hyprctl eval "hl.config({ decoration = { screen_shader = '$TEMP_SHADER' } })"
}

enable_shader() {
  local entry=$1
  [ -z "$entry" ] && return
  if ! grep -Fqx "$entry" "$STATE_FILE"; then
    echo "$entry" >>"$STATE_FILE"
  fi
  echo "ok"
  rebuild_stack
}

disable_shader() {
  local entry=$1
  [ -z "$entry" ] && return

  # Using awk to avoid delimiter collisions in sed when paths have slashes
  awk -v target="$entry" '$0 != target && $0 ~ /[^[:space:]]/ {print}' "$STATE_FILE" >"${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"

  echo "ok"
  rebuild_stack
}

case $1 in
enable)
  if [[ -z "$TARGET" ]]; then
    # Removed 'local' keyword here to fix SC2168
    active_shaders=$(cat "$STATE_FILE" 2>/dev/null)
    if [ -z "$(echo "$active_shaders" | tr -d '[:space:]')" ]; then
      hyprctl eval "hl.config({ decoration = { screen_shader = '' } })"
    else
      hyprctl eval "hl.config({ decoration = { screen_shader = '$TEMP_SHADER' } })"
    fi
    exit 0
  fi
  enable_shader "$TARGET"
  ;;
disable)
  if [[ -z "$TARGET" ]]; then
    hyprctl eval "hl.config({ decoration = { screen_shader = '' } })"
    exit 0
  fi
  disable_shader "$TARGET"
  ;;
toggle)
  if [[ -z "$TARGET" ]]; then
    echo "Usage: $0 toggle <shader_name_or_path>"
    exit 1
  fi
  if grep -Fqx "$TARGET" "$STATE_FILE"; then
    disable_shader "$TARGET"
  else
    enable_shader "$TARGET"
  fi
  ;;
enabled)
  if [ -n "$TARGET" ]; then
    grep -Fqx "$TARGET" "$STATE_FILE"
  else
    [ -s "$STATE_FILE" ] && sed 's/^/  - /' "$STATE_FILE" || echo "None"
  fi
  ;;
clear)
  : >"$STATE_FILE"
  rebuild_stack
  ;;
*)
  echo "Usage: $0 {enable|disable|toggle|enabled|clear} [name_or_path]"
  exit 1
  ;;
esac
