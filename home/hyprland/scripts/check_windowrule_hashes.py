#!/usr/bin/env python3
"""
check_windowrule_hashes.py

Run during `home-manager switch` (see home.nix activation) to enforce
that window-rule files under conf/windowrule_requests/_pending/ are only
ever loaded by Hyprland if their current sha256 matches a hash you
explicitly approved (recorded in approved_hashes.json, which you commit
to git). This is the "declarative" counterpart to windowrule_daemon.py:

that daemon handles ad-hoc runtime requests from arbitrary programs;
this script handles rule files that live in your nixconf repo and get
approved by committing a hash, not by clicking a notification.

Layout (all inside conf/windowrule_requests/, which the "conf" dir in
editableConfigs already symlinks into ~/.config/hypr/conf/):

  conf/windowrule_requests/
    _pending/                 <- raw candidate .lua files you or a tool
                                  drop here. Excluded from Hyprland's
                                  auto_require() because the leading "_"
                                  segment matches its existing skip rule.
    approved_hashes.json      <- {"filename.lua": "sha256..."}. Edit
                                  this by running approve_windowrule.py,
                                  then git add/commit both files.
    *.lua                     <- symlinks this script creates back into
                                  _pending/ for files whose hash matches
                                  approved_hashes.json. No leading "_",
                                  so auto_require() picks these up
                                  normally -- this is the only path by
                                  which a rule actually gets loaded.

On mismatch (new file, or a previously-approved file whose content
changed) the script refuses to link it, prints a clear warning (visible
in `home-manager switch` output) with the path, new hash, and old hash
if any, and fires a desktop notification if notify-send is available.
"""

import hashlib
import json
import os
import subprocess
import sys

if len(sys.argv) != 2:
  print("usage: check_windowrule_hashes.py <windowrule_requests_dir>", file=sys.stderr)
  sys.exit(1)

WR_DIR = os.path.abspath(sys.argv[1])
PENDING_DIR = os.path.join(WR_DIR, "_pending")
DB_FILE = os.path.join(WR_DIR, "approved_hashes.json")


def sha256_of(path):
  h = hashlib.sha256()
  with open(path, "rb") as f:
    for chunk in iter(lambda: f.read(65536), b""):
      h.update(chunk)


  return h.hexdigest()


def load_db():
  if not os.path.exists(DB_FILE):
    return {}

  try:
    with open(DB_FILE, "r") as f:
      return json.load(f)


  except (json.JSONDecodeError, OSError):
    return {}


def notify(summary, body, urgency="normal"):
  if subprocess.run(["which", "notify-send"], capture_output=True).returncode == 0:
    subprocess.run(["notify-send", "-u", urgency, summary, body], check=False)


def short(h):
  return h[:12] if h else "(none)"


def main():
  os.makedirs(PENDING_DIR, exist_ok=True)
  if not os.path.exists(DB_FILE):
    with open(DB_FILE, "w") as f:
      json.dump({}, f)


  db = load_db()
  exit_code = 0

  pending_names = set()
  for name in sorted(os.listdir(PENDING_DIR)):
    if not name.endswith(".lua"):
      continue

    pending_names.add(name)

    pending_path = os.path.join(PENDING_DIR, name)
    link_path = os.path.join(WR_DIR, name)
    new_hash = sha256_of(pending_path)
    old_hash = db.get(name)

    if old_hash == new_hash:
      # approved and unchanged -> make sure the live symlink exists
      if os.path.islink(link_path) or os.path.exists(link_path):
        if not (os.path.islink(link_path) and os.readlink(link_path) == pending_path):
          os.remove(link_path)
          os.symlink(pending_path, link_path)

      else:
        os.symlink(pending_path, link_path)

    else:
      # not approved / changed since approval -> refuse to link
      if os.path.islink(link_path) or os.path.exists(link_path):
        os.remove(link_path)

      print(f"[windowrule] BLOCKED (hash mismatch): {name}")
      print(f"[windowrule]   path:     {pending_path}")
      print(f"[windowrule]   new hash: {short(new_hash)}")
      print(f"[windowrule]   old hash: {short(old_hash) if old_hash else '(none, never approved)'}")
      print(f"[windowrule]   run: approve_windowrule.py {name}")
      notify(
        "Window rule needs approval",
        f"{name}\nnew: {short(new_hash)}\nold: {short(old_hash) if old_hash else '(none)'}\nrun: approve_windowrule.py {name}",
        urgency="critical",
      )
      exit_code = 1


  # clean up dangling symlinks for pending files that got removed/renamed
  for name in sorted(os.listdir(WR_DIR)):
    if not name.endswith(".lua"):
      continue

    if name in pending_names:
      continue

    link_path = os.path.join(WR_DIR, name)
    if os.path.islink(link_path):
      os.remove(link_path)


  sys.exit(exit_code)


if __name__ == "__main__":
  main()
