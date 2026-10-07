#!/usr/bin/env bash

usage() {
  echo "Usage: $0 /path/to/target/directory"
  exit 1
}

if [ -z "$1" ]; then
  echo "Error: No target directory provided."
  usage
fi

TARGET_DIR="$1"

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: '$TARGET_DIR' is not a valid directory."
  exit 1
fi

echo "Scanning for duplicate files in '$TARGET_DIR'..."
echo "------------------------------------------------"

# Step 1: Collect fdupes output entirely into memory
mapfile -t lines < <(fdupes -r "$TARGET_DIR")

current_group=()
all_groups=()

# Parse lines into duplicate sets separated by empty lines
for line in "${lines[@]}"; do
  if [ -z "$line" ]; then
    if [ ${#current_group[@]} -gt 1 ]; then
      # Store group size followed by group elements
      all_groups+=("${#current_group[@]}" "${current_group[@]}")
    fi
    current_group=()
  else
    current_group+=("$line")
  fi
done

# Handle trailing group if present
if [ ${#current_group[@]} -gt 1 ]; then
  all_groups+=("${#current_group[@]}" "${current_group[@]}")
fi

total_items=${#all_groups[@]}

if [ "$total_items" -eq 0 ]; then
  echo "No duplicate files found!"
  exit 0
fi

# Step 2: Interactive loop over each collected group
idx=0
group_num=1

while [ "$idx" -lt "$total_items" ]; do
  count="${all_groups[$idx]}"
  idx=$((idx + 1))

  files=()
  for ((i = 0; i < count; i++)); do
    files+=("${all_groups[$idx]}")
    idx=$((idx + 1))
  done

  echo ""
  echo "================================================="
  echo "Duplicate Group $group_num ($count files):"

  for i in "${!files[@]}"; do
    echo "  [$((i + 1))] ${files[$i]}"
  done

  echo ""
  echo "Opening '${files[0]}' in VSCodium..."
  # Launch codium detached from standard IO streams
  codium --reuse-window "${files[0]}" </dev/null &>/dev/null &

  echo ""
  echo "Options:"
  echo "  Enter a number (1-$count) to keep THAT file and delete the rest."
  echo "  Enter 'A' or 'all' to KEEP ALL files (delete none)."
  echo "  Enter 'D' or 'delete' to DELETE ALL files in this group."
  echo "  Enter 'S' or 'skip' to SKIP this group."

  while true; do
    read -rp "Your choice: " choice </dev/tty
    case "$choice" in
    [aA] | [aA][lL][lL])
      echo "Keeping all files in this group."
      break
      ;;
    [sS] | [sS][kK][iI][pP])
      echo "Skipping group."
      break
      ;;
    [dD] | [dD][eE][lL][eE][tT][eE])
      read -rp "Are you sure you want to DELETE ALL $count files? (y/N): " confirm </dev/tty
      if [[ "$confirm" =~ ^[yY](es)?$ ]]; then
        for file in "${files[@]}"; do
          echo "Deleting: $file"
          rm -f "$file"
        done
        break
      else
        echo "Action canceled."
      fi
      ;;
    *)
      if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$count" ]; then
        keep_index=$((choice - 1))
        keep_file="${files[$keep_index]}"
        echo "Keeping: $keep_file"

        for i in "${!files[@]}"; do
          if [ "$i" -ne "$keep_index" ]; then
            echo "Deleting: ${files[$i]}"
            rm -f "${files[$i]}"
          fi
        done
        break
      else
        echo "Invalid selection. Please enter 1-$count, 'A' (keep all), 'D' (delete all), or 'S' (skip)."
      fi
      ;;
    esac
  done

  group_num=$((group_num + 1))
done

echo ""
echo "Finished processing all duplicate files!"
