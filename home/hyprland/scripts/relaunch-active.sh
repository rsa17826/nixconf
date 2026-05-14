#!/usr/bin/env sh
PID=$(hyprctl activewindow -j | jq -r .pid)
BIN=$(readlink /proc/"$PID"/exe)

# Snapshot the running process's environment before killing it
ENV_FILE=$(mktemp)
tr '\0' '\n' </proc/"$PID"/environ >"$ENV_FILE"

kill -9 "$PID"
sleep 0.3

# Relaunch inside the original environment
(
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  exec "$BIN"
) &

rm -f "$ENV_FILE"
