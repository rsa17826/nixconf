#!/usr/bin/env bash

# Check if at least one argument was passed
if [ $# -eq 0 ]; then
  echo "Error: No command provided."
  echo "Usage: $0 <command> [args...]"
  exit 1
fi

# Join all arguments into a single string for execution
CMD="$*"

BEFORE=$(mktemp)
AFTER=$(mktemp)

trap 'rm -f "$BEFORE" "$AFTER"' EXIT

echo "▶ Running first time: $CMD"
$CMD >"$BEFORE"

echo -e "\nInitial output saved."
read -rp "Press [Enter] to run again and compare..."

echo -e "\n▶ Running second time: $CMD"
$CMD >"$AFTER"

echo -e "\n=== Differences ==="
if diff --color=auto -u "$BEFORE" "$AFTER"; then
  echo "No changes detected."
fi
