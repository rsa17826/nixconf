#!/usr/bin/env bash
# request_windowrule.sh /absolute/path/to/rule.lua
#
# Sends a request that windowrule_daemon.py will pick up, hash, and
# either auto-approve (if this exact path+hash was granted before),
# auto-block (if denied before), or ask you via a notification.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 /absolute/path/to/rule.lua" >&2
  exit 1
fi

target="$1"

if [[ "$target" != /* ]]; then
  target="$(realpath -m "$target")"
fi

# Must match WINDOWRULES_DIR / the default in windowrule_daemon.py.
# ~/.config/hypr is read-only, so state lives under XDG_DATA_HOME instead.
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
base_dir="${WINDOWRULES_DIR:-$data_home/hypr-windowrules}"
fifo="$base_dir/requests.fifo"

if [[ ! -p "$fifo" ]]; then
  echo "error: $fifo doesn't exist (is windowrule-daemon.service running?)" >&2
  exit 1
fi

# Opening a FIFO for writing blocks until a reader is present. The daemon
# should always have one open (see O_RDWR trick in windowrule_daemon.py),
# but guard against a dead/stuck daemon so this can't hang forever.
# shellcheck disable=SC2016
if ! timeout 3 bash -c 'printf "%s\n" "$1" > "$2"' _ "$target" "$fifo"; then
  echo "error: timed out writing to $fifo (is windowrule-daemon.service running?)" >&2
  exit 1
fi
