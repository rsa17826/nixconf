#!/usr/bin/env bash
# templates/script
set -euo pipefail
cmd="${1:?usage: script init|update <category>... }"
shift

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
        cp "$src" "$dest"
        echo "created: $dest"
      fi
      cp "$src" "$base" # record what we applied
      ;;
    update)
      if [ ! -e "$dest" ]; then
        cp "$src" "$dest"
        cp "$src" "$base"
        echo "created: $dest"
        continue
      fi
      if [ ! -e "$base" ]; then
        cp "$dest" "$base" # no history yet; treat current as base
      fi
      if git merge-file -q "$dest" "$base" "$src"; then
        echo "merged clean: $dest"
      else
        echo "CONFLICTS in: $dest  (resolve markers, then rerun)"
      fi
      cp "$src" "$base" # advance base to new template regardless
      ;;
    *)
      echo "unknown cmd: $cmd" >&2
      exit 1
      ;;
    esac
  done
done
