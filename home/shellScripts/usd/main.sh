#!/usr/bin/env bash
time=${1:-3h}
sd "$time" &
nfu && update
sd
