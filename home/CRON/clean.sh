#!/usr/bin/env bash
# set -euo pipefail

# ===== CONFIG =====
ROOT="$HOME"
DAYS=7

KEEP_PATHS=(
  "$HOME/Documents/keep"
  "$HOME/Projects"
  "$HOME/nixconf"
  "$HOME/.ssh"
  "$HOME/.var"
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

# ===== COLLECT OLD DIRECTORIES AND FILES =====
mapfile -t OLD_DIRS < <(
  find "$ROOT" -type d -mtime "+$DAYS" 2>/dev/null
)

mapfile -t OLD_FILES < <(
  find "$ROOT" -type f -mtime "+$DAYS" 2>/dev/null
)

# ===== QUEUE FILES/FOLDERS FOR NOTIFICATIONS =====
declare -A decisions  # Associative array to store decisions (1=delete, 0=keep)
queue=()

# Add directories to the queue
for dir in "${OLD_DIRS[@]}"; do
  if ! is_protected "$dir"; then
    queue+=("$dir")
  fi
done

# Add files to the queue
for file in "${OLD_FILES[@]}"; do
  if ! is_protected "$file"; then
    queue+=("$file")
  fi
done

# ===== SHOW NOTIFICATIONS =====
for path in "${queue[@]}"; do
  echo "Showing notification for: $path"  # Debug log

  # Show Zenity dialog for each item
  zenity --question \
    --title="Old item detected" \
    --text="$path is older than $DAYS days.\n\nDelete this item?"

  exit_code=$?

  # Handle unexpected exit codes (like window close)
  if [[ "$exit_code" -ne 0 && "$exit_code" -ne 1 ]]; then
    echo "Zenity closed unexpectedly (exit code: $exit_code). Skipping this item."  # Debug log
    continue
  fi

  # Store the decision (1 for delete, 0 for keep)
  if [[ "$exit_code" -eq 0 ]]; then
    decisions["$path"]=1  # Delete
  else
    decisions["$path"]=0  # Keep
  fi

  echo "Zenity finished for $path with exit code: $exit_code"  # Debug log
done

# ===== PROCESS DECISIONS =====
for path in "${!decisions[@]}"; do
  decision="${decisions[$path]}"
  echo "Processing decision for $path: $decision"  # Debug log

  if [[ "$decision" -eq 1 ]]; then
    # DELETE: User clicked "OK"
    if [[ -d "$path" ]]; then
      rm -rf -- "$path"
      echo "Deleted folder: $path"  # Debug log
      notify-send "Cleanup" "Deleted folder: $path"
    else
      rm -f -- "$path"
      echo "Deleted file: $path"  # Debug log
      notify-send "Cleanup" "Deleted file: $path"
    fi
  else
    # KEEP: User clicked "Cancel"
    if [[ -d "$path" ]]; then
      find "$path" -exec touch {} +
      echo "Kept folder for another $DAYS days: $path"  # Debug log
      notify-send "Cleanup" "Kept folder for another $DAYS days"
    else
      touch -- "$path"
      echo "Kept file for another $DAYS days: $path"  # Debug log
      notify-send "Cleanup" "Kept file for another $DAYS days"
    fi
  fi

  # Print logs after action
  echo "Completed cleanup for: $path"
done

# Final confirmation/logging step after all actions
echo "Cleanup complete! All old files and folders processed."
