#!/usr/bin/env bash
time=${1:-3h}
cd ~/nixconf || exit
shutdown "$time" &
nfu && update
sleep 5 || exit 1
shutdown
