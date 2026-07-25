#!/usr/bin/env python3
"""
windowrule_daemon.py

Watches ~/.config/hypr/windowrule_requests/incoming/ for request files.
Each request file's content is a single line: the absolute path to a .lua
file that some program wants Hyprland to load as a window-rule module.

Flow per request:
  1. Read the target path, delete the request file.
  2. Hash the target file's contents (sha256).
  3. Look up the path in the trust database (approved.json):
       - same hash as before, and not DENIED -> auto-grant, no notification.
       - hash stored as DENIED -> auto-ignore, small low-priority notice.
       - unknown path, or hash changed since last decision -> ask via
         a notification with Grant / Deny / Ignore-for-now actions.

  4. On Grant: symlink the file into conf/windowrules/ (already picked up
     by the existing auto_require() in hyprland.lua), remember the hash,
     and hyprctl reload.
     On Deny: remember hash as DENIED, remove any existing symlink.
     On Ignore for now: do nothing persistent, remove any existing
     symlink for this request slot so the rule isn't half-applied.

Run this as a long-lived process (systemd --user service, see
windowrule-daemon.service).
"""

import hashlib
import json
import os
import subprocess
import sys
import time
import gi

gi.require_version("Notify", "0.7")
from gi.repository import Notify, GLib # noqa: E402

HOME = os.path.expanduser("~")
BASE_DIR = os.path.join(HOME, ".config", "windowrule_requests")
INCOMING_DIR = os.path.join(BASE_DIR, "incoming")
DB_FILE = os.path.join(BASE_DIR, "approved.json")
RULES_DIR = os.path.join(HOME, ".config", "windowrule_requests/conf", "windowrules")
DENIED = "DENIED"
POLL_INTERVAL = 1.0 # seconds

os.makedirs(INCOMING_DIR, exist_ok=True)
os.makedirs(RULES_DIR, exist_ok=True)


def load_db():
  if not os.path.exists(DB_FILE):
    return {}

  try:
    with open(DB_FILE, "r") as f:
      return json.load(f)


  except (json.JSONDecodeError, OSError):
    return {}


def save_db(db):
  tmp = DB_FILE + ".tmp"
  with open(tmp, "w") as f:
    json.dump(db, f, indent=2, sort_keys=True)

  os.replace(tmp, DB_FILE)


def sha256_of(path):
  h = hashlib.sha256()
  with open(path, "rb") as f:
    for chunk in iter(lambda: f.read(65536), b""):
      h.update(chunk)


  return h.hexdigest()


def slot_name(path):
  # stable filename for a given source path, independent of file content
  return "req_" + hashlib.sha256(path.encode("utf-8")).hexdigest()[:16] + ".lua"


def rules_link_path(path):
  return os.path.join(RULES_DIR, slot_name(path))


def reload_hyprland():
  try:
    subprocess.run(
      ["hyprctl", "reload"],
      check=False,
      stdout=subprocess.DEVNULL,
      stderr=subprocess.DEVNULL,
    )

  except FileNotFoundError:
    pass


def apply_grant(path):
  link = rules_link_path(path)
  try:
    if os.path.islink(link) or os.path.exists(link):
      os.remove(link)

    os.symlink(path, link)

  except OSError as e:
    notify_simple("windowrule request: link failed", f"{path}\n{e}", urgency="critical")
    return

  reload_hyprland()


def revoke(path):
  link = rules_link_path(path)
  if os.path.islink(link) or os.path.exists(link):
    try:
      os.remove(link)
      reload_hyprland()

    except OSError:
      pass



def notify_simple(title, body, urgency="normal"):
  n = Notify.Notification.new(title, body)
  urgency_map = {"low": 0, "normal": 1, "critical": 2}
  n.set_urgency(urgency_map.get(urgency, 1))
  n.show()


def short(h):
  return h[:12] if h else "(none)"


def prompt_and_handle(path, new_hash, old_hash, db):
  title = "Window-rule permission request"
  body_lines = [
    f"Path: {path}",
    f"New hash: {short(new_hash)}",
  ]
  if old_hash and old_hash != DENIED:
    body_lines.append(f"Previous hash: {short(old_hash)}")
  elif old_hash == DENIED:
    body_lines.append("Previously: DENIED")
  else:
    body_lines.append("Previous hash: (none, first request)")

  body = "\n".join(body_lines)

  n = Notify.Notification.new(title, body)
  n.set_urgency(1)

  def on_action(notification, action, user_data=None):
    print(action)
    if action == "grant":
      db[path] = new_hash
      save_db(db)
      apply_grant(path)
      notify_simple("Window-rule granted", path, urgency="low")
    elif action == "deny":
      db[path] = DENIED
      save_db(db)
      revoke(path)
      notify_simple("Window-rule denied", path, urgency="low")
    elif action == "ignore":
      # ignore for now: no persistence, don't apply this time
      revoke(path)

    notification.close()

  n.add_action("grant", "Grant", on_action, None)
  n.add_action("deny", "Deny", on_action, None)
  n.add_action("ignore", "Ignore for now", on_action, None)
  n.show()


def handle_request_file(req_path, db):
  try:
    with open(req_path, "r") as f:
      target = f.readline().strip()


  finally:
    try:
      os.remove(req_path)

    except OSError:
      pass


  if not target:
    return

  target = os.path.expanduser(target)

  if not os.path.isfile(target):
    notify_simple("Window-rule request: file not found", target, urgency="critical")
    return

  try:
    new_hash = sha256_of(target)

  except OSError as e:
    notify_simple(
      "Window-rule request: could not read file",
      f"{target}\n{e}",
      urgency="critical",
    )
    return

  old_hash = db.get(target)

  if old_hash == new_hash and old_hash != DENIED:
    # previously granted, unchanged content -> auto-allow silently
    apply_grant(target)
    return

  if old_hash == DENIED and old_hash is not None:
    # was denied before; if content also unchanged we can't tell
    # (DENIED doesn't store a hash) so we still just block quietly,
    # with a low-priority heads-up.
    notify_simple(
      "Window-rule request blocked",
      f"{target}\n(previously denied)",
      urgency="low",
    )
    return

  prompt_and_handle(target, new_hash, old_hash, db)


def main():
  Notify.init("windowrule-daemon")
  db = load_db()

  loop = GLib.MainLoop()

  def poll():
    nonlocal db
    try:
      entries = sorted(os.listdir(INCOMING_DIR))

    except OSError:
      entries = []

    for name in entries:
      req_path = os.path.join(INCOMING_DIR, name)
      if os.path.isfile(req_path):
        db = load_db() # pick up any external edits
        handle_request_file(req_path, db)


    return True # keep the timeout alive

  GLib.timeout_add(int(POLL_INTERVAL * 1000), poll)
  try:
    loop.run()

  except KeyboardInterrupt:
    sys.exit(0)


if __name__ == "__main__":
  main()
