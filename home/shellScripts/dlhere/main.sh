#!/usr/bin/env bash
#
# Move recently-downloaded files into place:
#  - if exactly one file with the same name exists somewhere under DEST,
#    move the new file into that subdirectory (overwriting the match)
#  - if multiple files share that name in different subdirs, compare
#    file CONTENTS against each candidate and overwrite whichever is
#    most similar (uses `diff` for text files, `cmp` for binary files)
#  - if no match exists anywhere, just drop it in DEST (current dir)

SRC="$HOME/Downloads"
DEST="."

# Returns true (0) if the file looks binary
is_binary() {
  # `file` command is fast and reliable; fall back to `grep -qI` if unavailable
  if command -v file >/dev/null 2>&1; then
    ! file -b "$1" | grep -qi "text"
  else
    ! grep -qI '' "$1" 2>/dev/null
  fi
}

# Text-file distance: differing lines / total lines, scaled *1000 (no floats in bash)
text_distance() {
  local f1="$1" f2="$2"
  local changed total
  changed=$(diff --unchanged-line-format='' --old-line-format='%L' --new-line-format='%L' \
    "$f1" "$f2" 2>/dev/null | wc -l)
  total=$(($(wc -l <"$f1") + $(wc -l <"$f2")))
  ((total == 0)) && total=1
  echo $((changed * 1000 / total))
}

# Binary-file distance: differing bytes / total bytes, scaled *1000
binary_distance() {
  local f1="$1" f2="$2"
  local changed total size1 size2
  # cmp -l lists byte offsets that differ; count them
  changed=$(cmp -l "$f1" "$f2" 2>/dev/null | wc -l)
  size1=$(wc -c <"$f1")
  size2=$(wc -c <"$f2")
  total=$((size1 + size2))
  ((total == 0)) && total=1
  echo $((changed * 1000 / total))
}

# Dispatch to the right comparison based on file type
file_distance() {
  local f1="$1" f2="$2"
  if is_binary "$f1" || is_binary "$f2"; then
    binary_distance "$f1" "$f2"
  else
    text_distance "$f1" "$f2"
  fi
}

# Find files modified in the last 30 seconds, directly in Downloads
find "$SRC" -maxdepth 1 -type f -mmin -0.5 -print0 | while IFS= read -r -d '' file; do
  fname="$(basename "$file")"

  # Find all files with the same name in subdirectories of DEST
  mapfile -d '' -t matches < <(find "$DEST" -mindepth 2 -type f -name "$fname" -print0 2>/dev/null)

  match_count=${#matches[@]}

  if ((match_count == 0)); then
    # No match anywhere -> drop in DEST as before
    mv -t "$DEST" "$file"

  elif ((match_count == 1)); then
    # Exactly one match -> move into that subdirectory, overwriting it
    target_dir="$(dirname "${matches[0]}")"
    mv -f "$file" "$target_dir/$fname"

  else
    # Multiple matches -> compare file CONTENTS to pick closest match
    best_dist=-1
    best_path=""
    for candidate in "${matches[@]}"; do
      dist=$(file_distance "$file" "$candidate")
      if ((best_dist == -1 || dist < best_dist)); then
        best_dist=$dist
        best_path="$candidate"
      fi
    done
    target_dir="$(dirname "$best_path")"
    mv -f "$file" "$target_dir/$fname"
  fi
done
