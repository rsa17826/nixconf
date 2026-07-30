#!/usr/bin/env bash
# templates/script
set -euo pipefail

usage() {
  echo "usage: script <category>... [-- args passed to each category's 'run' script]" >&2
  exit 1
}
[ $# -ge 1 ] || usage

# cp preserves source mode bits; our templates often live in read-only
# locations (nix store), so a plain `cp` leaves dest/base read-only and
# every later run fails with "Permission denied". Always force writable.
wcp() {
  cp "$1" "$2"
  chmod u+w "$2"
}

# Files where multiple categories each contribute an independent fragment
# (not "the same file evolving") should be unioned, not 3-way merged.
# A 3-way merge assumes base/other share lineage; unrelated gitignore
# fragments don't, so git merge-file just replaces local with other.
is_fragment_file() {
  case "$1" in
  gitignore | env | dockerignore) return 0 ;;
  *) return 1 ;;
  esac
}

# Union src's lines into dest, preserving dest's existing lines/order,
# de-duplicated, only appending genuinely new lines from src.
combine_lines() {
  local dest="$1" src="$2"
  if [ ! -e "$dest" ]; then
    wcp "$src" "$dest"
    return
  fi
  local tmp
  tmp="$(mktemp)"
  comm -13 <(sort -u "$dest") <(sort -u "$src") >"$tmp" || true
  if [ -s "$tmp" ]; then
    cat "$tmp" >>"$dest"
  fi
  rm -f "$tmp"
}

apply_category() {
  local cat="$1" src_dir="$SCRIPT_DATA_DIR/$1"
  [ -d "$src_dir" ] || {
    echo "no template category: $cat" >&2
    exit 1
  }

  find "$src_dir" -maxdepth 1 -type f | while read -r src; do
    fname="$(basename "$src")"
    # per-category 'run' file is a hook, not a template to copy
    [ "$fname" = "run" ] && continue

    base_dir="./.template-base/$cat"
    base="$base_dir/$fname"
    if [[ "$fname" == "gitignore" ]]; then
      dest="./.$fname"
    else
      dest="./$fname"
    fi
    mkdir -p "$base_dir"

    if [ ! -e "$dest" ]; then
      if is_fragment_file "$fname"; then
        combine_lines "$dest" "$src"
      else
        wcp "$src" "$dest"
      fi
      wcp "$src" "$base"
      echo "created: $dest"
      continue
    fi

    if is_fragment_file "$fname"; then
      combine_lines "$dest" "$src"
      echo "combined: $dest"
      wcp "$src" "$base"
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
  done

  # optional post-setup hook, e.g. templates/go/run
  local hook="$src_dir/run"
  if [ -f "$hook" ]; then
    if [ -x "$hook" ]; then
      "$hook" "${run_args[@]}"
    else
      bash "$hook" "${run_args[@]}"
    fi
  fi
}

cats=()
while [ $# -gt 0 ] && [ "$1" != "--" ]; do
  cats+=("$1")
  shift
done
if [ "${1:-}" = "--" ]; then
  shift
fi
run_args=("$@")

[ ${#cats[@]} -ge 1 ] || usage

for cat in "${cats[@]}"; do
  apply_category "$cat"
done
