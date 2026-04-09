#!/usr/bin/env sh

parse_to_minutes() {
  input="$1"
  total_sec=0

  # Hours
  h_val=$(echo "$input" | sed -n 's/.*\([0-9]\{1,\}\)h.*/\1/p')
  if [ -n "$h_val" ]; then
    total_sec=$((total_sec + h_val * 3600))
  fi

  # Minutes
  m_val=$(echo "$input" | sed -n 's/.*\([0-9]\{1,\}\)m.*/\1/p')
  if [ -n "$m_val" ]; then
    total_sec=$((total_sec + m_val * 60))
  fi

  # Seconds
  s_val=$(echo "$input" | sed -n 's/.*\([0-9]\{1,\}\)s.*/\1/p')
  if [ -n "$s_val" ]; then
    total_sec=$((total_sec + s_val))
  fi

  # Fallback: if just a number, treat as minutes (to match standard shutdown behavior)
  if [ -z "$h_val" ] && [ -z "$m_val" ] && [ -z "$s_val" ]; then
    echo "$input"
    return
  fi

  # Convert total seconds to minutes (rounding up)
  # systemd shutdown uses +m
  echo "$(((total_sec + 59) / 60))"
}

# 1. Handle "cancel" or other flags first
case "$1" in
-c | --show | --help)
  sudo /run/current-system/sw/bin/shutdown "$1"
  exit 0
  ;;
esac

# 2. Handle Reboot vs Shutdown and Time parsing
if [ -z "$1" ]; then
  # Default: immediate
  sudo /run/current-system/sw/bin/shutdown now
else
  MINS=$(parse_to_minutes "$1")
  # Use + notation for relative time
  sudo /run/current-system/sw/bin/shutdown "+$MINS"
fi
