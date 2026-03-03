#!/usr/bin/env -S nix shell nixpkgs#swayidle --command bash

# Define a temporary lock file to prevent double-firing
LOCK_FILE="/tmp/trap_active.lock"

# Cleanup function if script is interrupted
trap "rm -f $LOCK_FILE" EXIT

# 2. Run swayidle for a single event
# We use 'timeout 1' as a dummy trigger, but 'resume' is the real actor
swayidle -w \
  timeout 1 'echo "System armed..." ' \
  resume '
    if [ ! -f "'$LOCK_FILE'" ]; then
      touch "'$LOCK_FILE'"
      hyprlock --no-fade-in
      rm -f "'$LOCK_FILE'"
      pkill -u $USER swayidle
    fi'
