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

is_protected() {
  local path="$1"
  for kp in "${KEEP_PATHS[@]}"; do
    [[ "$path" == "$kp"* ]] && return 0
  done
  return 1
}

# ===== 1. COLLECT ITEMS (FASTER) =====
echo "Scanning... please wait."
mapfile -t raw_list < <(
  find "$ROOT" \
    -path "*/.git/*" -prune -o \
    -path "*/.git" -prune -o \
    \( -type d -o -type f \) -mtime "+$DAYS" -prune -print 2>/dev/null
)

# Prepare the list for Zenity
# Format: TRUE/FALSE (status), Path
zenity_args=()
for item in "${raw_list[@]}"; do
  if [[ -e "$item" ]] && ! is_protected "$item"; then
    zenity_args+=("TRUE" "$item")
  fi
done

if [[ ${#zenity_args[@]} -eq 0 ]]; then
  zenity --info --text="No old items found."
  exit 0
fi

# ===== 2. SINGLE INTERACTIVE LIST =====
# This is where the speed comes from. One window for everything.
selected_items=$(zenity --list --checklist \
  --title="Cleanup Manager" \
  --column="Delete?" --column="Path" \
  --width=800 --height=600 \
  --text="Select the items you want to PERMANENTLY delete. Unselected items will be kept." \
  "${zenity_args[@]}")

# If user hits Cancel or closes window, exit to be safe
[[ $? -ne 0 ]] && echo "Cancelled." && exit 0

# ===== 3. PROCESS RESULTS =====
# Convert pipe-separated string to array
IFS="|" read -ra TO_DELETE <<<"$selected_items"

# Create a temporary associative array for fast lookup
declare -A delete_map
for item in "${TO_DELETE[@]}"; do
  delete_map["$item"]=1
done

# Run through the original queue to handle Keep vs Delete
for ((i = 1; i < ${#zenity_args[@]}; i += 2)); do
  path="${zenity_args[$i]}"

  if [[ ${delete_map["$path"]} ]]; then
    # DELETE
    rm -rf -- "$path"
    echo "DELETED: $path"
  else
    # KEEP (Touch)
    if [[ -d "$path" ]]; then
      find "$path" -exec touch {} +
    else
      touch -- "$path"
    fi
    echo "KEPT: $path"
  fi
done

notify-send "Cleanup Complete" "Finished processing all items."
