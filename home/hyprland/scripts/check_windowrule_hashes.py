#!/usr/bin/env python3

import hashlib
import json
import os
import subprocess
import sys

DENIED = "DENIED"


def sha256_of(path):
  # open() follows symlinks, so this hashes the actual live content
  # whether the .lua entry is a real file or a symlink to one.
  h = hashlib.sha256()
  with open(path, "rb") as f:
    for chunk in iter(lambda: f.read(65536), b""):
      h.update(chunk)


  return h.hexdigest()


def load_db(db_file):
  if not os.path.exists(db_file):
    return {}

  try:
    with open(db_file, "r") as f:
      return json.load(f)


  except (json.JSONDecodeError, OSError) as e:
    print(f"[windowrule] ERROR: could not parse {db_file}: {e}", file=sys.stderr)
    return None


def notify(summary, body, urgency="critical"):
  try:
    subprocess.run(["notify-send", "-u", urgency, summary, body], check=False)

  except OSError:
    pass # notify-send not on PATH (e.g. during home-manager activation) -- non-fatal


def main():
  if len(sys.argv) != 2:
    print("usage: check_windowrule_hashes.py <windowrule_requests_dir>", file=sys.stderr)
    sys.exit(1)

  wr_dir = os.path.abspath(sys.argv[1])
  db_file = os.path.join(wr_dir, "approved_hashes.json")

  if not os.path.isdir(wr_dir):
    # Nothing to check yet -- not an error, just nothing granted so far.
    sys.exit(0)

  db = load_db(db_file)
  if db is None:
    sys.exit(1) # malformed approved_hashes.json is always a hard failure

  failures = []

  for name in sorted(os.listdir(wr_dir)):
    if not name.endswith(".lua"):
      continue

    path = os.path.join(wr_dir, name)

    if os.path.islink(path) and not os.path.exists(path):
      failures.append((name, "broken symlink (target missing)", None, db.get(name)))
      continue

    try:
      current_hash = sha256_of(path)

    except OSError as e:
      failures.append((name, f"could not read file: {e}", None, db.get(name)))
      continue

    recorded_hash = db.get(name)

    if recorded_hash is None:
      failures.append((name, "no entry in approved_hashes.json", current_hash, None))
    elif recorded_hash == DENIED:
      failures.append((name, "recorded as DENIED", current_hash, DENIED))
    elif recorded_hash != current_hash:
      failures.append((name, "hash mismatch", current_hash, recorded_hash))


  if not failures:
    sys.exit(0)

  print(f"[windowrule] {len(failures)} window-rule file(s) failed hash verification in {wr_dir}:", file=sys.stderr)
  for name, reason, current_hash, recorded_hash in failures:
    print(f"[windowrule]   {name}: {reason}", file=sys.stderr)
    print(f"[windowrule]     current hash:  {current_hash}", file=sys.stderr)
    print(f"[windowrule]     recorded hash: {recorded_hash}", file=sys.stderr)

  names = ", ".join(f[0] for f in failures)
  notify(
    "Window-rule verification failed",
    f"{len(failures)} file(s) failed: {names}\nCheck approved_hashes.json in {wr_dir}",
  )

  sys.exit(1)


if __name__ == "__main__":
  main()
