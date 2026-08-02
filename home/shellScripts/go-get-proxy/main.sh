#!/usr/bin/env bash
# go-proxy.sh — drop-in wrapper for `go` that tracks rsa17826 modules.
#
# Setup:
#   1. Save this file somewhere on disk, e.g. ~/bin/go-proxy.sh
#   2. chmod +x ~/bin/go-proxy.sh
#   3. Put ~/bin first in PATH, and either:
#        - symlink it as `go`:  ln -s ~/bin/go-proxy.sh ~/bin/go
#        - or alias it:         alias go='~/bin/go-proxy.sh'
#      (the wrapper calls the REAL go binary internally, see REAL_GO below)
#
# Behavior:
#   - Passes every command straight through to the real `go` binary.
#   - When the command is `go get ... <module>` and <module> contains
#     "rsa17826", records "<module_path>\t<local_dir>" into the tracked
#     modules file (deduped), so `main.sh` can later re-`go get -u` it
#     from the right directory.

set -e

TRACK_FILE="$HOME/.config/goproxy-rsa17826/modules.tsv"
mkdir -p "$(dirname "$TRACK_FILE")"
touch "$TRACK_FILE"

# Locate the real go binary (skip this wrapper itself if it's shadowing `go`)
REAL_GO=""
IFS=':' read -ra PATH_DIRS <<<"$PATH"
for dir in "${PATH_DIRS[@]}"; do
  candidate="$dir/go"
  if [ -x "$candidate" ] && [ "$candidate" != "$0" ] && ! cmp -s "$candidate" "$0" 2>/dev/null; then
    REAL_GO="$candidate"
    break
  fi
done
if [ -z "$REAL_GO" ]; then
  echo "go-proxy: could not find the real go binary in PATH (excluding this wrapper)." >&2
  exit 1
fi

# Run the real command first so `go get` actually does its job.
"$REAL_GO" "$@"
STATUS=$?

# Only bother tracking on successful `go get ...`
if [ "$STATUS" -eq 0 ] && [ "${1:-}" = "get" ]; then
  CWD="$(pwd)"
  shift
  for arg in "$@"; do
    case "$arg" in
      -*) continue ;; # skip flags like -u
    esac
    if [[ "$arg" == *rsa17826* ]]; then
      # strip a trailing @version/@latest if present
      MODULE="${arg%@*}"
      LINE="${MODULE}	${CWD}"
      if ! grep -Fxq "$LINE" "$TRACK_FILE"; then
        echo "$LINE" >>"$TRACK_FILE"
        echo "go-proxy: tracked $MODULE -> $CWD" >&2
      fi
    fi
  done
fi

exit "$STATUS"
