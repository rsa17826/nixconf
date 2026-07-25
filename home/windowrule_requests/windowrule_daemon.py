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
     WINDOWRULE_PENDING_DIR), record its hash directly in
     conf/windowrule_requests/approved_hashes.json (the same file/format
     check_windowrule_hashes.py reads -- no separate approve script
     needed), and re-run check_windowrule_hashes.py so the rule is live
     immediately. You still need to git add/commit approved_hashes.json
     + the _pending file for it to survive the next `home-manager
     switch` pulling a fresh checkout.
     On Deny: remember hash as DENIED, remove any staged copy, remove
     it from approved_hashes.json, and re-run the check script so it
     stops being live right away.
     On Ignore for now: do nothing persistent in this daemon's own db,
     but still undo any staged copy/approval for this request slot so
     nothing is half-applied.
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

# Granted rules are copied into the nixconf repo's _pending dir.
# Override with WINDOWRULE_PENDING_DIR.
PENDING_DIR = os.getenv(
  "WINDOWRULE_PENDING_DIR",
  os.path.join(HOME, "nixconf", "home", "hyprland", "conf", "windowrule_requests", "_pending"),
)
# The parent of _pending -- same dir check_windowrule_hashes.py expects
# as its argument, and where approved_hashes.json lives.
WR_DIR = os.path.dirname(PENDING_DIR)
APPROVED_HASHES_FILE = os.path.join(WR_DIR, "approved_hashes.json")

# check_windowrule_hashes.py normally only runs at `home-manager switch`
# time. Granting here also runs it immediately (best-effort) so the rule
# goes live right away instead of waiting for the next rebuild -- you
# still want to git commit approved_hashes.json + the _pending file
# afterward so it stays live across rebuilds.
CHECK_SCRIPT = os.getenv(
  "WINDOWRULE_CHECK_SCRIPT",
  os.path.join(HOME, "nixconf", "home", "hyprland", "scripts", "check_windowrule_hashes.py"),
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


def load_json_db(path):
  if not os.path.exists(path):
    return {}

  try:
    with open(path, "r") as f:
      return json.load(f)


  except (json.JSONDecodeError, OSError):
    return {}


def save_json_db(path, db):
  tmp = path + ".tmp"
  with open(tmp, "w") as f:
    json.dump(db, f, indent=2, sort_keys=True)

  os.replace(tmp, path)


def load_db():
  return load_json_db(DB_FILE)


def save_db(db):
  save_json_db(DB_FILE, db)


def approve_in_nixconf(filename, file_hash):
  # Same file/format check_windowrule_hashes.py reads: {filename: sha256}.
  hashes = load_json_db(APPROVED_HASHES_FILE)
  hashes[filename] = file_hash
  save_json_db(APPROVED_HASHES_FILE, hashes)


def unapprove_in_nixconf(filename):
  hashes = load_json_db(APPROVED_HASHES_FILE)
  if filename in hashes:
    del hashes[filename]
    save_json_db(APPROVED_HASHES_FILE, hashes)


def run_check_script():
  # Best-effort: makes the rule live right now instead of waiting for
  # the next `home-manager switch`. Non-fatal if the script/dir isn't
  # there yet or hyprctl isn't available.
  try:
    subprocess.run(
      [sys.executable, CHECK_SCRIPT, WR_DIR],
      check=False,
      stdout=subprocess.DEVNULL,
      stderr=subprocess.DEVNULL,
    )

  except OSError:
    pass

  reload_hyprland()


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
  # Copies the content into the nixconf _pending dir, records its hash
  # directly in approved_hashes.json (no more separate
  # approve_windowrule.py step), then re-runs check_windowrule_hashes.py
  # so the rule is live immediately. Still needs a git commit to survive
  # the next rebuild's source checkout.
  dest = pending_copy_path(path)
  filename = os.path.basename(dest)
  try:
    with open(path, "rb") as src, open(dest, "wb") as dst:
      content = src.read()
      dst.write(content)


  except OSError as e:
    notify_simple("windowrule request: copy failed", f"{path}\n{e}", urgency="critical")
    return

  file_hash = hashlib.sha256(content).hexdigest()
  approve_in_nixconf(filename, file_hash)
  run_check_script()

  notify_simple(
    "Window-rule granted and active",
    f"{dest}\ngit add/commit approved_hashes.json + _pending/{filename}\nto keep it live across rebuilds",
    urgency="normal",
  )


def revoke(path):
  dest = pending_copy_path(path)
  filename = os.path.basename(dest)
  try:
    if os.path.exists(dest):
      os.remove(dest)


  except OSError:
    pass

  unapprove_in_nixconf(filename)
  run_check_script()


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
