#!/usr/bin/env bash
# templates/script
set -euo pipefail
cmd="${1:?usage: script init|update <category>... }"
shift

# cp preserves source mode bits; our templates often live in read-only
# locations (nix store), so a plain `cp` leaves dest/base read-only and
# every later run fails with "Permission denied". Always force writable.
wcp() {
  cp "$1" "$2"
  chmod u+w "$2"
}

for cat in "$@"; do
  src_dir="$SCRIPT_DATA_DIR/$cat"
  [ -d "$src_dir" ] || {
    echo "no template category: $cat" >&2
    exit 1
  }

  find "$src_dir" -maxdepth 1 -type f | while read -r src; do
    fname="$(basename "$src")"
    base_dir="./.template-base/$cat"
    base="$base_dir/$fname"
    if [[ "$fname" == "gitignore" ]]; then
      dest="./.$fname"
    else
      dest="./$fname"
    fi
    mkdir -p "$base_dir"

    case "$cmd" in
    init)
      if [ -e "$dest" ]; then
        echo "skip (exists): $dest"
      else
        wcp "$src" "$dest"
        echo "created: $dest"
      fi
      wcp "$src" "$base" # record what we applied
      ;;
    update)
      if [ ! -e "$dest" ]; then
        wcp "$src" "$dest"
        wcp "$src" "$base"
        echo "created: $dest"
        continue
      fi
      if [ ! -e "$base" ]; then
        wcp "$dest" "$base" # no history yet; treat current as base
      fi
      if git merge-file -q "$dest" "$base" "$src"; then
        echo "merged clean: $dest"
      else
        echo "CONFLICTS in: $dest  (resolve markers, then rerun)"
      fi
      wcp "$src" "$base" # advance base to new template regardless
      ;;
    *)
      echo "unknown cmd: $cmd" >&2
      exit 1
      ;;
    esac
  done
done
