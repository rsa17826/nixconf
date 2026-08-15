#!/usr/bin/env bash
time=${1:-3h}
cd ~/nixconf || exit 1
shutdown "$time" &
nfu && update
sleep 15 || (
  shutdown -c
  exit 1
)
shutdown
