#!/usr/bin/env python3
"""
wmv.py - wildcard move/rename with referenceable captures.

Pattern syntax:
  *          matches any run of characters (not '/'), captured as a numbered group
  {a,b,c}    matches one of the listed literal alternatives, captured as a numbered group
  Groups are numbered in the order they appear, left to right (both * and {...} count).

Destination template:
  $1, $2, $3 ... refer to the captured groups, by position.

If the pattern contains no '/', matching is done against top-level files in the
current directory only (like a normal shell glob). If it contains '/', matching
is done recursively against relative paths.

Examples:
  wmv.py '*-*.{js,css}' '$3/$1/$2' --mkdir
      foo-bar.js   -> js/foo/bar
      alpha-1.css  -> css/alpha/1

  wmv.py --dry-run 'report-*.pdf' 'archive/$1.pdf'

"""

import argparse
import re
import sys
from pathlib import Path


def compile_pattern(pattern: str):
  i = 0
  regex_parts = []
  group_num = 0
  while i < len(pattern):
    c = pattern[i]
    if c == "*":
      group_num += 1
      regex_parts.append("([^/]*)")
      i += 1
    elif c == "{":
      end = pattern.find("}", i)
      if end == -1:
        raise ValueError(f"unmatched '{{' in pattern at position {i}: {pattern!r}")

      content = pattern[i + 1 : end]
      options = content.split(",")
      if any(o == "" for o in options):
        raise ValueError(f"empty alternative in {{...}} group: {{{content}}}")

      group_num += 1
      regex_parts.append("(" + "|".join(re.escape(o) for o in options) + ")")
      i = end + 1
    else:
      regex_parts.append(re.escape(c))
      i += 1


  regex = "^" + "".join(regex_parts) + "$"
  return re.compile(regex), group_num


def find_candidates(pattern: str):
  recursive = "/" in pattern
  root = Path(".")
  if recursive:
    return [p for p in root.rglob("*") if p.is_file()]
  else:
    return [p for p in root.iterdir() if p.is_file()]


def substitute(template: str, groups: tuple, group_num: int) -> str:
  def repl(m):
    idx = int(m.group(1))
    if idx < 1 or idx > group_num:
      raise ValueError(f"destination references ${idx} but pattern only has {group_num} capture group(s)")

    return groups[idx - 1]

  result = re.sub(r"\$(\d+)", repl, template)
  if "$" in result:
    stray = re.search(r"\$\d*", result)
    raise ValueError(f"unresolved reference {stray.group(0)!r} in destination template")

  return result


def main():
  ap = argparse.ArgumentParser(
    description="Wildcard-based rename/move with referenceable captures ($1, $2, ...).",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog=__doc__,
  )
  _ = ap.add_argument("pattern", help="source pattern, e.g. '*-*.{js,css}'")
  _ = ap.add_argument("dest_template", help="destination template, e.g. '$3/$1/$2'")
  _ = ap.add_argument("--mkdir", action="store_true", help="create destination parent directories if missing")
  _ = ap.add_argument("--dry-run", action="store_true", help="show what would happen without moving anything")
  _ = ap.add_argument("--force", action="store_true", help="overwrite destination if it already exists")
  args = ap.parse_args()

  regex, group_num = compile_pattern(args.pattern)

  candidates = find_candidates(args.pattern)
  matches = []
  for p in candidates:
    relpath = p.as_posix()
    m = regex.fullmatch(relpath)
    if m:
      matches.append((p, m.groups()))


  if not matches:
    print(f"no files matched pattern {args.pattern!r}", file=sys.stderr)
    sys.exit(1)

  planned = []
  for src, groups in matches:
    dest_str = substitute(args.dest_template, groups, group_num)
    planned.append((src, Path(dest_str)))

  had_error = False
  for src, dest in planned:
    if dest.exists() and not args.force:
      print(f"ERROR: destination already exists, skipping: {src} -> {dest} (use --force to overwrite)", file=sys.stderr)
      had_error = True
      continue

    if not dest.parent.exists():
      if args.mkdir:
        if not args.dry_run:
          dest.parent.mkdir(parents=True, exist_ok=True)

      else:
        print(f"ERROR: destination directory does not exist: {dest.parent} (use --mkdir to create it)", file=sys.stderr)
        had_error = True
        continue


    if args.dry_run:
      print(f"{src} -> {dest}")
    else:
      src.rename(dest)
      print(f"{src} -> {dest}")


  if had_error:
    sys.exit(1)


if __name__ == "__main__":
  main()
