#!/usr/bin/env bash

# Elevation check for the calling script
# This script should only be sourced by other scripts

admin() {
  # Check if the script is being run as root
  if [ "$(id -u)" -ne 0 ]; then
    # Re-run the calling script with sudo and pass all arguments
    sudo -- "$0" "$@"
    exit # Exit the current non-root instance after elevation
  fi
}
