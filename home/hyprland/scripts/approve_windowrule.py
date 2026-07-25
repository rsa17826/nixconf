#!/usr/bin/env python3
"""
approve_windowrule.py <filename.lua>

Records the current sha256 of conf/windowrule_requests/_pending/<filename>
in approved_hashes.json, so check_windowrule_hashes.py will link it in on
the next `home-manager switch`.

This is the "grant" action for git-tracked rules. After running it:
    git add conf/windowrule_requests/approved_hashes.json \
            conf/windowrule_requests/_pending/<filename>
    git commit -m "windowrules: approve <filename>"
    home-manager switch

Usage:
    approve_windowrule.py <filename.lua>          # uses default dir
    approve_windowrule.py <filename.lua> <dir>     # explicit windowrule_requests dir

"""

import hashlib
import json
import os
import sys

DEFAULT_WR_DIR = os.path.expanduser(os.getenv("WINDOWRULE_REQUESTS_DIR", "~/nixconf/home/hyprland/conf/windowrule_requests"))


def sha256_of(path):
  h = hashlib.sha256()
  with open(path, "rb") as f:
    for chunk in iter(lambda: f.read(65536), b""):
      h.update(chunk)


  return h.hexdigest()


def main():
  if len(sys.argv) not in (2, 3):
    print(__doc__, file=sys.stderr)
    sys.exit(1)

  name = sys.argv[1]
  wr_dir = os.path.abspath(sys.argv[2]) if len(sys.argv) == 3 else DEFAULT_WR_DIR
  pending_path = os.path.join(wr_dir, "_pending", name)
  db_file = os.path.join(wr_dir, "approved_hashes.json")

  if not os.path.isfile(pending_path):
    print(f"error: {pending_path} does not exist", file=sys.stderr)
    sys.exit(1)

  new_hash = sha256_of(pending_path)

  db = {}
  if os.path.exists(db_file):
    try:
      with open(db_file, "r") as f:
        db = json.load(f)


    except (json.JSONDecodeError, OSError):
      db = {}


  old_hash = db.get(name)
  db[name] = new_hash

  tmp = db_file + ".tmp"
  with open(tmp, "w") as f:
    json.dump(db, f, indent=2, sort_keys=True)

  os.replace(tmp, db_file)

  print(f"approved: {name}")
  print(f"  new hash: {new_hash}")
  print(f"  old hash: {old_hash or '(none)'}")
  print("Now git add/commit approved_hashes.json + the file, then home-manager switch.")


if __name__ == "__main__":
  main()
