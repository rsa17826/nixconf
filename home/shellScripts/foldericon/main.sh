#!/usr/bin/env bash

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

while IFS= read -r -d '' dir; do
  dirname="$(basename "$dir")"
  key="$(echo "$dirname" | tr '[:upper:]' '[:lower:]')"

  if [[ -n "${icon_map[$key]:-}" ]]; then
    icon_path="${icon_map[$key]}"
    ext="${icon_path##*.}"
    dest="${dir%/}/.foldericon.${ext}"

    if [[ -e "$dest" ]]; then
      # Already linked to correct file?
      if [[ "$dest" -ef "$icon_path" ]]; then
        echo "OK      $dir -> already linked"
      else
        echo "SKIP    $dir -> $dest already exists (different file)"
        ((skipped++))
      fi
      continue
    fi

    ln -s "$icon_path" "$dest"
    echo "LINKED  $dir -> $dest (from $icon_path)"
    ((linked++))
  fi
done < <(
  find "$target_dir" -maxdepth 20 -type d \
    \( -name 'node_modules' -o -name '.git' -o -name 'dist' -o -name 'build' -o -name '.next' \) -prune \
    -o -type d ! -path '*/.*' -print0
)

echo
echo "Done. Linked: $linked, Skipped (existing): $skipped"
