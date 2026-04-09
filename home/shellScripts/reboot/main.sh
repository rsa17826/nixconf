#!/usr/bin/env sh
if [ -z "$1" ]; then
  doas /run/current-system/sw/bin/reboot 0
else
  doas /run/current-system/sw/bin/reboot %*
fi
