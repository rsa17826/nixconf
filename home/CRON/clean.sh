#!/usr/bin/env bash
set -euo pipefail

# ===== CONFIG =====
ROOT="$HOME"
DAYS=7

KEEP_PATHS=(
  "$HOME/Documents/keep"
  "$HOME/Projects"
)

# ===== HELPERS =====
is_protected() {
  local path="$1"
  for kp in "${KEEP_PATHS[@]}"; do
    [[ "$path" == "$kp"* ]] && return 0
  done
  return 1
}

now=$(date +%s)
cutoff=$((DAYS * 86400))

# ===== COLLECT OLD DIRECTORIES =====
mapfile -t OLD_DIRS < <(
  find "$ROOT" -type d -mtime "+$DAYS" 2>/dev/null
)

# ===== PROCESS DIRECTORIES =====
for dir in "${OLD_DIRS[@]}"; do
  is_protected "$dir" && continue

  # skip if parent already handled
  parent="$(dirname "$dir")"
  [[ " ${OLD_DIRS[*]} " == *" $parent "* ]] && continue

  zenity --question \
    --title="Old folder detected" \
    --text="Folder is older than $DAYS days:\n\n$dir\n\nDelete folder and all contents?" \
    --ok-label="Delete" \
    --cancel-label="Keep +$DAYS days"

  if [[ $? -eq 0 ]]; then
    rm -rf -- "$dir"
    notify-send "Cleanup" "Deleted folder: $dir"
  else
    find "$dir" -exec touch {} +
    notify-send "Cleanup" "Kept folder for another $DAYS days"
  fi
done

# ===== COLLECT OLD FILES (NOT IN OLD DIRS) =====
mapfile -t OLD_FILES < <(
  find "$ROOT" -type f -mtime "+$DAYS" 2>/dev/null
)

for file in "${OLD_FILES[@]}"; do
  is_protected "$file" && continue

  skip=false
  for d in "${OLD_DIRS[@]}"; do
    [[ "$file" == "$d/"* ]] && skip=true && break
  done
  $skip && continue

  zenity --question \
    --title="Old file detected" \
    --text="File is older than $DAYS days:\n\n$file\n\nDelete file?" \
    --ok-label="Delete" \
    --cancel-label="Keep +$DAYS days"

  if [[ $? -eq 0 ]]; then
    rm -f -- "$file"
    notify-send "Cleanup" "Deleted file: $(basename "$file")"
  else
    touch -- "$file"
    notify-send "Cleanup" "Kept file for another $DAYS days"
  fi
done
