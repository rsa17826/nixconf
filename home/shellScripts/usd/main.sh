#!/usr/bin/env bash
time=${1:-3h}
shutdown "$time" &
nfu && update
sleep 5 || exit 1
shutdown
