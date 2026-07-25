#!/usr/bin/env python3
"""
windowrule_daemon.py

Watches a FIFO at $WINDOWRULES_DIR/requests.fifo (default:

$XDG_DATA_HOME/hypr-windowrules/requests.fifo, i.e.
~/.local/share/hypr-windowrules/requests.fifo) for requests, one per
line: the absolute path to a .lua file that some program wants
Hyprland to load as a window-rule module. Event-driven via
GLib.io_add_watch -- no polling. The daemon opens the FIFO O_RDWR
(even though it only reads) so it always holds a phantom writer open;
this means the pipe never sees EOF and any number of short-lived
writers (see request_windowrule.sh) can open/write/close without the
daemon needing to reopen anything.

Flow per request:
  1. Hash the target file's contents (sha256).
  2. Look up the path in the trust database ($WINDOWRULES_DIR/approved.json):
       - same hash as before, and not DENIED -> auto-grant, no notification.
       - hash stored as DENIED -> auto-ignore, small low-priority notice.
       - unknown path, or hash changed since last decision -> ask via
         a notification with Grant / Deny / Ignore-for-now actions.

  3. On Grant: copy the file's content into the nixconf repo's
     conf/windowrule_requests/_pending/ dir (default; override with
     WINDOWRULE_PENDING_DIR). This does NOT make the rule live -- it
     still needs approve_windowrule.py + git commit + a rebuild before
     check_windowrule_hashes.py will actually activate it. That keeps
     runtime-granted rules going through the same git-tracked
     hash-approval gate as declaratively-added ones.
     On Deny: remember hash as DENIED, remove any staged copy.
     On Ignore for now: do nothing persistent, remove any staged copy
     for this request slot so it isn't half-applied.

Run this as a long-lived process (systemd --user service, see
windowrule-daemon.service).
"""

import hashlib
import json
import os
import stat
import subprocess
import sys
import gi

gi.require_version("Notify", "0.7")
from gi.repository import Notify, GLib # noqa: E402

HOME = os.path.expanduser("~")

# ~/.config/hypr is read-only, so ephemeral runtime state (the incoming
# request queue, and this daemon's own path->hash trust table) lives
# under XDG_DATA_HOME. Override with WINDOWRULES_DIR if you want it
# somewhere else.
XDG_DATA_HOME = os.getenv("XDG_DATA_HOME", os.path.join(HOME, ".local", "share"))
BASE_DIR = os.getenv("WINDOWRULES_DIR", os.path.join(XDG_DATA_HOME, "hypr-windowrules"))
FIFO_PATH = os.path.join(BASE_DIR, "requests.fifo")
DB_FILE = os.path.join(BASE_DIR, "approved.json")

# Granted rules are NOT written under BASE_DIR anymore. Instead they're
# copied into the nixconf repo's _pending dir -- the same directory
# check_windowrule_hashes.py / approve_windowrule.py already watch --
# so a runtime grant here still requires an explicit
# approve_windowrule.py + git commit before it goes live on next
# `home-manager switch`. Override with WINDOWRULE_PENDING_DIR.
PENDING_DIR = os.getenv(
  "WINDOWRULE_PENDING_DIR",
  os.path.join(HOME, "nixconf", "home", "hyprland", "conf", "windowrule_requests", "_pending"),
)
DENIED = "DENIED"

# PyGObject does not keep a Notification alive on its own once add_action()
# is set up -- if nothing holds a Python reference to it, it gets garbage
# collected before the ActionInvoked D-Bus signal comes back, and the
# on_action callback silently never fires. Keep every notification with
# pending actions referenced here until it's closed/handled.
_PENDING_NOTIFICATIONS = {}

os.makedirs(BASE_DIR, exist_ok=True)
os.makedirs(PENDING_DIR, exist_ok=True)


def ensure_fifo():
  if os.path.exists(FIFO_PATH):
    if not stat.S_ISFIFO(os.stat(FIFO_PATH).st_mode):
      raise RuntimeError(f"{FIFO_PATH} exists and is not a FIFO -- remove it manually")

    return

  os.mkfifo(FIFO_PATH, mode=0o600)


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


def pending_copy_path(path):
  return os.path.join(PENDING_DIR, slot_name(path))


def reload_hyprland():
  try:
    subprocess.run(["hyprctl", "reload"], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

  except FileNotFoundError:
    pass


def apply_grant(path):
  # Granting here no longer makes the rule live immediately -- it copies
  # the content into the nixconf _pending dir. It only actually loads
  # once you run approve_windowrule.py on it, commit, and
  # `home-manager switch` (check_windowrule_hashes.py enforces that gate).
  dest = pending_copy_path(path)
  try:
    with open(path, "rb") as src, open(dest, "wb") as dst:
      dst.write(src.read())


  except OSError as e:
    notify_simple("windowrule request: copy failed", f"{path}\n{e}", urgency="critical")
    return

  notify_simple(
    "Window-rule copied to nixconf",
    f"{dest}\nRun: approve_windowrule.py {os.path.basename(dest)}\nthen git commit + home-manager switch",
    urgency="normal",
  )


def revoke(path):
  dest = pending_copy_path(path)
  try:
    if os.path.exists(dest):
      os.remove(dest)


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

  # Keyed by id() of the notification object; see _PENDING_NOTIFICATIONS
  # comment above for why this is necessary.
  key = id(n)
  _PENDING_NOTIFICATIONS[key] = n

  def cleanup():
    _PENDING_NOTIFICATIONS.pop(key, None)

  def on_action(notification, action, user_data=None):
    if action == "grant":
      db[path] = new_hash
      save_db(db)
      apply_grant(path)
    elif action == "deny":
      db[path] = DENIED
      save_db(db)
      revoke(path)
      notify_simple("Window-rule denied", path, urgency="low")
    elif action == "ignore":
      # ignore for now: no persistence, don't apply this time
      revoke(path)

    notification.close()

  def on_closed(notification):
    # Covers the case where the notification is dismissed/expired
    # without an action being clicked, so it doesn't leak forever.
    cleanup()

  n.connect("closed", on_closed)
  n.add_action("grant", "Grant", on_action, None)
  n.add_action("deny", "Deny", on_action, None)
  n.add_action("ignore", "Ignore for now", on_action, None)
  n.show()


def handle_request_line(target, db):
  target = target.strip()
  if not target:
    return

  target = os.path.expanduser(target)

  if not os.path.isfile(target):
    notify_simple("Window-rule request: file not found", target, urgency="critical")
    return

  try:
    new_hash = sha256_of(target)

  except OSError as e:
    notify_simple("Window-rule request: could not read file", f"{target}\n{e}", urgency="critical")
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
    notify_simple("Window-rule request blocked", f"{target}\n(previously denied)", urgency="low")
    return

  prompt_and_handle(target, new_hash, old_hash, db)


def main():
  Notify.init("windowrule-daemon")
  db = load_db()

  ensure_fifo()
  # O_RDWR (not O_RDONLY) is the key trick: it makes us our own phantom
  # writer, so the FIFO never reports EOF/hang-up even when every real
  # writer (request_windowrule.sh invocations) has closed. O_NONBLOCK
  # so the open() itself can't block.
  fd = os.open(FIFO_PATH, os.O_RDWR | os.O_NONBLOCK)

  buffer = b""

  def on_readable(source, condition):
    nonlocal buffer, db
    try:
      chunk = os.read(fd, 65536)

    except BlockingIOError:
      return True

    except OSError:
      return True

    if not chunk:
      # Shouldn't happen thanks to the O_RDWR trick, but don't spin if it does.
      return True

    buffer += chunk
    while b"\n" in buffer:
      line, buffer = buffer.split(b"\n", 1)
      text = line.decode("utf-8", errors="replace")
      if text.strip():
        db = load_db() # pick up any external edits (e.g. approve_windowrule.py)
        handle_request_line(text, db)


    return True # keep watching

  GLib.io_add_watch(fd, GLib.IO_IN, on_readable)

  loop = GLib.MainLoop()
  try:
    loop.run()

  except KeyboardInterrupt:
    sys.exit(0)

  finally:
    os.close(fd)


if __name__ == "__main__":
  main()
