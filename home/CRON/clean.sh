#!/usr/bin/env bash

# ===== CONFIG =====
ROOT="$HOME"
DAYS=7

KEEP_PATHS=(
  "$HOME/Documents/keep"
  "$HOME/Projects"
  "$HOME/nixconf"
  "$HOME/.ssh"
  "$HOME/.var"
  "$HOME/.zsh_history"
  "$HOME/.cache"
  "$HOME/.gitconfig"
  "$HOME/.local"
  "$HOME/.zshrc"
  "$HOME/Desktop"
  "$HOME/.config"
  "$HOME/.icons"
)

# ===== HELPERS =====
is_protected() {
  local path="$1"
  for kp in "${KEEP_PATHS[@]}"; do
    [[ "$path" == "$kp"* ]] && return 0
  done
  return 1
}

# ===== COLLECT OLD ITEMS (PRUNED & EXCLUDING GIT) =====
echo "Scanning for old items (excluding .git)..."

# Logic:
# 1. -path "*/.git/*" -prune : If it finds a .git folder, it ignores everything inside.
# 2. -o : "Or" (if the first part didn't match...)
# 3. \( -type d -o -type f \) -mtime "+$DAYS" -prune : Find old files/dirs and stop at the top level.
mapfile -t raw_list < <(
  find "$ROOT" \
    -path "*/.git/*" -prune -o \
    -path "*/.git" -prune -o \
    \( -type d -o -type f \) -mtime "+$DAYS" -prune -print 2>/dev/null
)

queue=()
for item in "${raw_list[@]}"; do
  # Double check protection list and ensure the item still exists
  if [[ -e "$item" ]] && ! is_protected "$item"; then
    queue+=("$item")
  fi
done

total_items=${#queue[@]}

if [[ $total_items -eq 0 ]]; then
  echo "No old items found."
  exit 0
fi

# ===== PROCESS DECISIONS =====
declare -A decisions

for index in "${!queue[@]}"; do
  path="${queue[$index]}"
  
  zenity --question \
    --title="Action Required: Old Item" \
    --text="Item: $path\n\nThis is older than $DAYS days. Delete it?" \
    --ok-label="Delete" \
    --cancel-label="Keep (Touch)" 2>/dev/null
  
  exit_code=$?
  
  if [[ $exit_code -eq 0 ]]; then
    decisions["$path"]=1
  else
    decisions["$path"]=0
  fi

  current=$((index + 1))
  percent=$((current * 100 / total_items))
  echo "$percent"
  echo "# Processing $current of $total_items..."
done | zenity --progress --title="Cleanup" --auto-close --percentage=0

# ===== EXECUTE DECISIONS =====
for path in "${!decisions[@]}"; do
  if [[ "${decisions[$path]}" -eq 1 ]]; then
    if [[ -e "$path" ]]; then
      rm -rf -- "$path"
      echo "DELETED: $path"
    fi
  else
    # Update timestamp
    if [[ -d "$path" ]]; then
      find "$path" -exec touch {} +
    else
      touch -- "$path"
    fi
    echo "KEPT: $path"
  fi
done

echo "Cleanup complete."