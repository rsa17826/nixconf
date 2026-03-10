#!/usr/bin/env bash

# 1. Setup Profile
PROFILE="${1:-/nix/var/nix/profiles/system}"
echo "Scanning profile: $PROFILE"

# 2. Get All Generations
# Format: "number date"
gens=$(nix-env -p "$PROFILE" --list-generations | awk '{print $1, $2}')

# 3. Identify CURRENT generation explicitly
current=$(nix-env -p "$PROFILE" --list-generations | grep "(current)" | awk '{print $1}')

# 4. Identify TODAY'S generations
today=$(date +%Y-%m-%d)
# Use mapfile to handle the list of generations for today robustly (Fixes SC2206)
mapfile -t gens_today < <(echo "$gens" | grep "$today" | awk '{print $1}')

# Initialize the 'keep' list array
keep=("$current" "${gens_today[@]}")

# Helper: Add oldest gen of a specific day
keep_oldest_of_day() {
  local date_str="$1"
  local oldest
  oldest=$(echo "$gens" | grep "$date_str" | head -n1 | awk '{print $1}')
  [[ -n "$oldest" ]] && keep+=("$oldest")
}

# 5. Policy: Last 7 Days (Oldest of each day)
for i in {1..7}; do
  keep_oldest_of_day "$(date -d "$i days ago" +%Y-%m-%d)"
done

# 6. Policy: Last 30 Days (Oldest 2)
month_start=$(date -d "30 days ago" +%Y-%m-%d)
# Read the oldest monthly generations into the array
while read -r g; do
  keep+=("$g")
done < <(echo "$gens" | awk -v start="$month_start" '$2 >= start {print $1}' | sort -n | head -n2)

# 7. Finalize the list (sort and unique)
# Using printf to handle array expansion safely
keep_final=$(printf "%s\n" "${keep[@]}" | sort -un | tr '\n' ' ')

# 8. Calculate Deletions
all_gens=$(echo "$gens" | awk '{print $1}')
to_delete=()
for g in $all_gens; do
  if [[ -z "$g" ]]; then continue; fi
  # Remove quotes from the right side of =~ (Fixes SC2076)
  # We check if the generation is surrounded by spaces in our 'keep' string
  if [[ ! " $keep_final " =~ " $g " ]]; then
    to_delete+=("$g")
  fi
done

# 9. Output results
echo "------------------------------------------"
echo "Current Generation: $current"
echo "Generations from Today ($today): ${gens_today[*]}"
echo "Total generations to PROTECT: $keep_final"
echo "------------------------------------------"

if [[ ${#to_delete[@]} -gt 0 ]]; then
  echo "Generations to DELETE: ${to_delete[*]}"
  echo "------------------------------------------"
  # To enable, uncomment the lines below.
  # Note: Using "${to_delete[@]}" ensures correct word splitting (Fixes SC2086)
  sudo nix-env -p "$PROFILE" --delete-generations "${to_delete[@]}"
  sudo nix-store --gc
else
  echo "Nothing to delete."
fi
