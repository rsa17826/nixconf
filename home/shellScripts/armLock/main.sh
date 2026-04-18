#!/usr/bin/env bash
# Define a temporary lock file to prevent double-firing
LOCK_FILE="/tmp/trap_active.lock"

# Cleanup function if script is interrupted
rm -f $LOCK_FILE
# shellcheck disable=SC2064
trap "rm -f $LOCK_FILE" EXIT

swayidle -w \
  timeout 1 "echo 'Armed...'" \
  resume "
    if [ ! -f \"$LOCK_FILE\" ]; then
      touch \"$LOCK_FILE\"
      hyprlock --no-fade-in
      rm -f \"$LOCK_FILE\"
      pkill -u \$USER swayidle
    fi"
