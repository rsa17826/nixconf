#!/usr/bin/env bash
# request_windowrule.sh /absolute/path/to/rule.lua
#
# Exit codes:
#   0 - already granted (or just granted via the notification)
#   1 - already denied/ignored (or just denied/ignored via the notification)
#   2 - usage / setup error (daemon not running, fifo missing, etc.)
#
# Behavior:
#   1. Check approved_hashes.json directly (no daemon round-trip needed).
#      If this exact path+content-hash was already granted -> exit 0.
#      If it was already denied -> exit 1.
#   2. Otherwise, send a request (tagged with a unique id) through the
#      daemon's FIFO and block until windowrule_daemon.py writes a
#      response for that id (i.e. until the notification is acted on),
#      then exit 0 (granted) or 1 (denied/ignored/dismissed).

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 /absolute/path/to/rule.lua" >&2
  exit 2
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
responses_dir="$base_dir/responses"

# Must match WINDOWRULE_DIR / the default in windowrule_daemon.py -- this
# is where approved_hashes.json actually lives.
wr_dir="${WINDOWRULE_DIR:-$HOME/nixconf/home/hyprland/conf/windowrule_requests}"
approved_hashes_file="$wr_dir/approved_hashes.json"

if [[ ! -f "$target" ]]; then
  echo "error: $target does not exist" >&2
  exit 2
fi

# --- Step 1: fast local check against approved_hashes.json -----------------
#
# Mirrors windowrule_daemon.py's slot_name()/sha256_of() logic exactly so
# the cached-decision fast path never has to touch the daemon at all.
status="$(
  python3 - "$target" "$approved_hashes_file" <<'PYEOF'
import hashlib
import json
import os
import sys

target, hashes_file = sys.argv[1], sys.argv[2]

slot = "req_" + hashlib.sha256(target.encode("utf-8")).hexdigest()[:16] + ".lua"

h = hashlib.sha256()
try:
  with open(target, "rb") as f:
    for chunk in iter(lambda: f.read(65536), b""):
      h.update(chunk)
  file_hash = h.hexdigest()
except OSError:
  print("ERROR")
  sys.exit(0)

hashes = {}
if os.path.exists(hashes_file):
  try:
    with open(hashes_file, "r") as f:
      hashes = json.load(f)
  except (json.JSONDecodeError, OSError):
    hashes = {}

old_hash = hashes.get(slot)

if old_hash == "DENIED":
  print("DENIED")
elif old_hash is not None and old_hash == file_hash:
  print("GRANTED")
else:
  print("UNKNOWN")
PYEOF
)"

case "$status" in
GRANTED)
  exit 0
  ;;
DENIED)
  exit 1
  ;;
ERROR)
  echo "error: could not read $target" >&2
  exit 2
  ;;
esac

# --- Step 2: not cached -- ask the daemon and wait for a decision ----------

if [[ ! -p "$fifo" ]]; then
  echo "error: $fifo doesn't exist (is windowrule-daemon.service running?)" >&2
  exit 2
fi

mkdir -p "$responses_dir"

request_id="$(cat /proc/sys/kernel/random/uuid 2>/dev/null || python3 -c 'import uuid; print(uuid.uuid4())')"
response_file="$responses_dir/$request_id"

cleanup() {
  rm -f "$response_file"
}
trap cleanup EXIT

# Opening a FIFO for writing blocks until a reader is present. The daemon
# should always have one open (see O_RDWR trick in windowrule_daemon.py),
# but guard against a dead/stuck daemon so this can't hang forever.
# shellcheck disable=SC2016
if ! timeout 3 bash -c 'printf "%s\t%s\n" "$1" "$2" > "$3"' _ "$request_id" "$target" "$fifo"; then
  echo "error: timed out writing to $fifo (is windowrule-daemon.service running?)" >&2
  exit 2
fi

# Wait for the daemon to write a response, i.e. for the notification to
# be acted on (grant/deny/ignore) or dismissed. No timeout here on
# purpose -- this is waiting on a human, which can take a while.
if command -v inotifywait &>/dev/null; then
  while [[ ! -f "$response_file" ]]; do
    inotifywait -qq -e create,moved_to -t 2 "$responses_dir" 2>/dev/null || true
  done
else
  while [[ ! -f "$response_file" ]]; do
    sleep 0.2
  done
fi

result="$(cat "$response_file" 2>/dev/null || echo "IGNORED")"

case "$result" in
GRANTED)
  exit 0
  ;;
*)
  exit 1
  ;;
esac
