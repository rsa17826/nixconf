#!/usr/bin/env sh

if [ "$#" -gt 0 ]; then
  wl-copy "$@"
elif [ ! -t 0 ]; then
  wl-copy
else
  wl-paste
fi
