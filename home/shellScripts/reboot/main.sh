#!/usr/bin/env sh
if [ -z "$1" ]; then
  sudo /run/current-system/sw/bin/reboot 0
else
  sudo /run/current-system/sw/bin/reboot %*
fi