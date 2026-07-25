#!/usr/bin/env bash
# request_windowrule.sh /absolute/path/to/rule.lua
#
# Drops a request that windowrule_daemon.py will pick up, hash, and
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
incoming_dir="$base_dir/incoming"
mkdir -p "$incoming_dir"

req_file="$incoming_dir/req_$(date +%s%N)_$$.txt"
echo "$target" >"$req_file"
