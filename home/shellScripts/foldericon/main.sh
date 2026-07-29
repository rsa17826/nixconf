#!/usr/bin/env bash

set -euo pipefail

target_dir="${1:-.}"

if [[ ! -d "$SCRIPT_DATA_DIR/icons" ]]; then
  echo "Icons directory not found: $SCRIPT_DATA_DIR/icons" >&2
  exit 1
fi

# Build a lowercase-name -> filepath map for icons
declare -A icon_map
shopt -s nullglob
for f in "$SCRIPT_DATA_DIR/icons"/*; do
  [[ -f "$f" ]] || continue
  base="$(basename "$f")"
  name="${base%.*}"
  key="$(echo "$name" | tr '[:upper:]' '[:lower:]')"
  icon_map["$key"]="$f"
done
shopt -u nullglob

if [[ ${#icon_map[@]} -eq 0 ]]; then
  echo "No icon files found in $SCRIPT_DATA_DIR/icons" >&2
  exit 1
fi

linked=0
skipped=0

for dir in "$target_dir"/*/; do
  [[ -d "$dir" ]] || continue
  dirname="$(basename "$dir")"
  key="$(echo "$dirname" | tr '[:upper:]' '[:lower:]')"

  if [[ -n "${icon_map[$key]:-}" ]]; then
    icon_path="${icon_map[$key]}"
    ext="${icon_path##*.}"
    dest="${dir%/}/.foldericon.${ext}"

    if [[ -e "$dest" ]]; then
      # Already linked to correct file?
      if [[ "$dest" -ef "$icon_path" ]]; then
        echo "OK      $dirname -> already linked"
      else
        echo "SKIP    $dirname -> $dest already exists (different file)"
        ((skipped++))
      fi
      continue
    fi

    ln "$icon_path" "$dest"
    echo "LINKED  $dirname -> $dest (from $icon_path)"
    ((linked++))
  fi
done

echo
echo "Done. Linked: $linked, Skipped (existing): $skipped"
