#!/usr/bin/env bash

# Check if at least one argument was passed
if [ $# -eq 0 ]; then
  echo "Usage: $0 [watch [interval]] <command>"
  exit 1
fi

WATCH_MODE=false
INTERVAL=1

# Logic to handle "watch" flag and optional interval
if [ "$1" == "watch" ]; then
  WATCH_MODE=true
  shift # Remove "watch" from arguments

  # Check if the next argument is a number (the interval)
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    INTERVAL=$1
    shift # Remove the interval from arguments
  fi
fi

CMD="$*"
BEFORE=$(mktemp)
AFTER=$(mktemp)
trap 'rm -f "$BEFORE" "$AFTER"' EXIT

# Initial Run
$CMD >"$BEFORE"

if [ "$WATCH_MODE" = true ]; then
  echo "Watching: $CMD (Interval: ${INTERVAL}s)"
  while true; do
    sleep "$INTERVAL"
    $CMD >"$AFTER"

    # Check for differences quietly
    if ! diff -q "$BEFORE" "$AFTER" >/dev/null; then
      echo -e "\n=== Change Detected at $(date +%H:%M:%S) ==="
      diff --color=auto -u "$BEFORE" "$AFTER"

      # Update "BEFORE" so we only see new changes next time
      cp "$AFTER" "$BEFORE"
    fi
  done
else
  # Original Manual Mode
  echo "▶ Running first time: $CMD"
  echo -e "\nInitial output saved."
  read -rp "Press [Enter] to run again and compare..."

  echo -e "\n▶ Running second time: $CMD"
  $CMD >"$AFTER"

  echo -e "\n=== Differences ==="
  if diff --color=auto -u "$BEFORE" "$AFTER"; then
    echo "No changes detected."
  fi
fi
