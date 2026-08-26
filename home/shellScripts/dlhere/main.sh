#!/usr/bin/env bash
#
# Move recently-downloaded files into place:
#  - if exactly one file with the same name exists somewhere under DEST,
#    move the new file into that subdirectory (overwriting the match)
#  - if multiple files share that name in different subdirs, compare
#    file CONTENTS against each candidate and overwrite whichever is
#    most similar (uses `diff` for text files, `cmp` for binary files)
#  - if no match exists anywhere, just drop it in DEST (current dir)
#
#  - special case: if exactly one new file showed up and it's a .zip:
#      1. if the zip's own filename matches an existing file somewhere
#         under DEST, treat it exactly like a normal file (move/overwrite
#         that match) -- it is NOT extracted.
#      2. otherwise, if every entry in the zip lives under one common
#         top-level directory (e.g. a.zip/dir/...) and a directory with
#         that same name exists somewhere under DEST, extract the zip's
#         contents INTO that directory (dropping the wrapping dir name),
#         overwriting anything that collides.
#      3. otherwise, try to match each file inside the zip (ignoring any
#         common wrapping directory from step 2) against existing files
#         under DEST by name, picking the closest-content match when a
#         name has multiple candidates. Matched entries are extracted
#         into their matched location (overwriting); entries with no
#         match anywhere are extracted flat into DEST. If at least one
#         entry matched, the zip is consumed (deleted) after extraction.
#      4. if nothing at all matches (no name match on the zip itself and
#         no entry inside it matches anything), just drop the zip into
#         DEST unchanged, like any other unmatched file.

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

# Detect which tool we can use to read/extract zip files. Prefers python3
# (almost always present, no extra dependency) and falls back to `unzip`.
detect_zip_tool() {
  if command -v python3 >/dev/null 2>&1; then
    echo "python3"
  elif command -v unzip >/dev/null 2>&1; then
    echo "unzip"
  else
    echo ""
  fi
}

# Print the entries (paths) inside a zip, one per line -- directory entries
# keep their trailing slash, same convention as `unzip -Z1`.
zip_list_entries() {
  local tool="$1" file="$2"
  case "$tool" in
  python3)
    python3 - "$file" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    for n in z.namelist():
        print(n)
PY
    ;;
  unzip)
    unzip -Z1 "$file" 2>/dev/null
    ;;
  esac
}

# Write the contents of a single zip entry to stdout.
zip_extract_entry_stdout() {
  local tool="$1" file="$2" entry="$3"
  case "$tool" in
  python3)
    python3 - "$file" "$entry" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    sys.stdout.buffer.write(z.read(sys.argv[2]))
PY
    ;;
  unzip)
    unzip -p "$file" "$entry" 2>/dev/null
    ;;
  esac
}

# Fully extract a zip into a destination directory.
zip_extract_all() {
  local tool="$1" file="$2" destdir="$3"
  case "$tool" in
  python3)
    python3 - "$file" "$destdir" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    z.extractall(sys.argv[2])
PY
    ;;
  unzip)
    unzip -oq "$file" -d "$destdir" 2>/dev/null
    ;;
  esac
}

# Given a source file path and a target filename, find where under DEST it
# should go: prints the target directory (empty string if no match found).
find_best_target_dir() {
  local src="$1" fname="$2"
  mapfile -d '' -t matches < <(find "$DEST" -mindepth 2 -not -path ".template-base/*" -type f -name "$fname" -print0 2>/dev/null)
  local match_count=${#matches[@]}

  if ((match_count == 0)); then
    echo ""
  elif ((match_count == 1)); then
    dirname "${matches[0]}"
  else
    local best_dist=-1 best_path="" dist candidate
    for candidate in "${matches[@]}"; do
      dist=$(file_distance "$src" "$candidate")
      if ((best_dist == -1 || dist < best_dist)); then
        best_dist=$dist
        best_path="$candidate"
      fi
    done
    dirname "$best_path"
  fi
}

# Standard single-file handling (the original behavior)
process_plain_file() {
  local file="$1"
  local fname target_dir
  fname="$(basename "$file")"
  target_dir=$(find_best_target_dir "$file" "$fname")

  if [[ -z "$target_dir" ]]; then
    mv -t "$DEST" "$file"
  else
    mv -f "$file" "$target_dir/$fname"
  fi
}

# Extract entries from a zip (optionally stripping a leading "$strip_prefix"
# path component), matching each entry's basename against existing files
# under DEST the same way process_plain_file does. Matched entries land in
# their matched directory; unmatched entries land flat in DEST. If nothing
# matched at all, the zip is left untouched in DEST instead.
try_flat_extract() {
  local file="$1" strip_prefix="$2" tool="$3"
  local entries rel_entries=() tmp_files=() target_dirs=()
  local any_match=0 e rel bname tmpfile tdir i

  mapfile -t entries < <(zip_list_entries "$tool" "$file")

  for e in "${entries[@]}"; do
    [[ "$e" == */ ]] && continue # skip directory-only entries
    rel="$e"
    if [[ -n "$strip_prefix" ]]; then
      [[ "$rel" == "$strip_prefix"* ]] || continue
      rel="${rel#"$strip_prefix"}"
    fi
    [[ -z "$rel" ]] && continue
    bname="$(basename "$rel")"

    tmpfile=$(mktemp)
    zip_extract_entry_stdout "$tool" "$file" "$e" >"$tmpfile"

    tdir=$(find_best_target_dir "$tmpfile" "$bname")

    rel_entries+=("$e")
    tmp_files+=("$tmpfile")
    target_dirs+=("$tdir")
    [[ -n "$tdir" ]] && any_match=1
  done

  if ((any_match == 0)); then
    # nothing inside the zip matches anything -> leave the zip as-is
    for tmpfile in "${tmp_files[@]}"; do rm -f "$tmpfile"; done
    mv -t "$DEST" "$file"
    return
  fi

  for ((i = 0; i < ${#rel_entries[@]}; i++)); do
    bname="$(basename "${rel_entries[$i]}")"
    tdir="${target_dirs[$i]}"
    if [[ -n "$tdir" ]]; then
      mv -f "${tmp_files[$i]}" "$tdir/$bname"
    else
      mv -f "${tmp_files[$i]}" "$DEST/$bname"
    fi
  done
  rm -f "$file"
}

# Handles the single-zip-file case per the rules described up top.
process_zip_file() {
  local file="$1"
  local fname target_dir
  fname="$(basename "$file")"

  local tool
  tool=$(detect_zip_tool)
  if [[ -z "$tool" ]]; then
    # No way to read zip contents on this system -> treat like a plain file
    process_plain_file "$file"
    return
  fi

  # Step 1: does the zip's own filename match an existing file? If so,
  # treat it exactly like any other file -- do not extract it.
  target_dir=$(find_best_target_dir "$file" "$fname")
  if [[ -n "$target_dir" ]]; then
    mv -f "$file" "$target_dir/$fname"
    return
  fi

  # Step 2: inspect the zip's contents
  local entries files_only=() e
  mapfile -t entries < <(zip_list_entries "$tool" "$file")
  for e in "${entries[@]}"; do
    [[ "$e" == */ ]] && continue
    files_only+=("$e")
  done

  if ((${#files_only[@]} == 0)); then
    # empty or unreadable zip -> just drop it in DEST
    mv -t "$DEST" "$file"
    return
  fi

  # Does every entry live under one common top-level directory?
  local topdir="" single_topdir=1 first
  for e in "${files_only[@]}"; do
    if [[ "$e" != */* ]]; then
      single_topdir=0
      break
    fi
    first="${e%%/*}"
    if [[ -z "$topdir" ]]; then
      topdir="$first"
    elif [[ "$topdir" != "$first" ]]; then
      single_topdir=0
      break
    fi
  done

  if ((single_topdir == 1)) && [[ -n "$topdir" ]]; then
    # Look for an existing directory with this same name under DEST
    local dirmatches
    mapfile -d '' -t dirmatches < <(find "$DEST" -mindepth 1 -not -path ".template-base/*" -type d -name "$topdir" -print0 2>/dev/null)

    if ((${#dirmatches[@]} == 1)); then
      local tmpdir
      tmpdir=$(mktemp -d)
      zip_extract_all "$tool" "$file" "$tmpdir"
      cp -af "$tmpdir/$topdir/." "${dirmatches[0]}/"
      rm -rf "$tmpdir"
      rm -f "$file"
      return
    fi

    # No single matching directory -> fall back to matching individual
    # files inside, ignoring the wrapping top-level directory.
    try_flat_extract "$file" "$topdir/" "$tool"
    return
  fi

  # No common wrapping directory -> match individual files directly
  try_flat_extract "$file" "" "$tool"
}

# Find files modified in the last 30 seconds, directly in Downloads
mapfile -d '' -t newfiles < <(find "$SRC" -maxdepth 1 -not -path ".template-base/*" -type f -mmin -0.5 -print0)

if ((${#newfiles[@]} == 1)) && [[ "${newfiles[0]}" == *.zip ]]; then
  process_zip_file "${newfiles[0]}"
else
  for file in "${newfiles[@]}"; do
    process_plain_file "$file"
  done
fi
