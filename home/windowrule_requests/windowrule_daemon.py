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

There is exactly ONE trust database: conf/windowrule_requests/
approved_hashes.json in your nixconf repo (WR_DIR below), keyed by a
stable per-source-path filename -> sha256 (or the sentinel "DENIED").
This is the same file check_windowrule_hashes.py reads at
`home-manager switch` time, so the daemon and the rebuild-time check
never disagree about what's approved. (An earlier version of this
daemon kept its own separate trust db under XDG_DATA_HOME -- don't do
that, it can drift out of sync with approved_hashes.json and cause
silent auto-grants/blocks that don't match what's actually in git.)

Flow per request:
  1. Hash the target file's contents (sha256).
  2. Look up this source path's slot in approved_hashes.json:
       - same hash as before, and not DENIED -> auto-grant, no notification.
       - hash stored as DENIED -> auto-ignore, small low-priority notice.
       - unknown path, or hash changed since last decision -> ask via
         a notification with Grant / Deny / Ignore-for-now actions.

  3. On Grant: write the file's content directly into
     conf/windowrule_requests/<slot>.lua (default; override with
     WINDOWRULE_DIR) and record its hash in approved_hashes.json in the
     same directory, then hyprctl reload so it's live immediately. No
     staging dir, no separate approve script. You still need to git
     add/commit approved_hashes.json + the new .lua file for it to
     survive the next `home-manager switch` pulling a fresh checkout.
     On Deny: record DENIED in approved_hashes.json, remove the live
     file, reload.
     On Ignore for now: don't touch approved_hashes.json at all, just
     remove the live file for this request slot so nothing is
     half-applied. You'll be asked again next time.

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

# ~/.config/hypr is read-only, so the only thing that lives under
# XDG_DATA_HOME is the FIFO itself (pure runtime plumbing, not state).
XDG_DATA_HOME = os.getenv("XDG_DATA_HOME", os.path.join(HOME, ".local", "share"))
RUNTIME_BASE_DIR = os.getenv("WINDOWRULES_DIR", os.path.join(XDG_DATA_HOME, "hypr-windowrules"))
FIFO_PATH = os.path.join(RUNTIME_BASE_DIR, "requests.fifo")

# Where granted rule files and approved_hashes.json actually live --
# your nixconf repo. Override with WINDOWRULE_DIR.
WR_DIR = os.getenv(
  "WINDOWRULE_DIR",
  os.path.join(HOME, "nixconf", "home", "hyprland", "conf", "windowrule_requests"),
)
APPROVED_HASHES_FILE = os.path.join(WR_DIR, "approved_hashes.json")

# check_windowrule_hashes.py still exists for hand-authored files you
# drop in conf/windowrule_requests/_pending/ yourself (outside the
# notification flow). Granting/denying here also re-runs it so any of
# those get reconciled at the same time, and to pick up hyprctl reload.
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

os.makedirs(RUNTIME_BASE_DIR, exist_ok=True)
os.makedirs(WR_DIR, exist_ok=True)


def ensure_fifo():
  if os.path.exists(FIFO_PATH):
    if not stat.S_ISFIFO(os.stat(FIFO_PATH).st_mode):
      raise RuntimeError(f"{FIFO_PATH} exists and is not a FIFO -- remove it manually")

    return

  os.mkfifo(FIFO_PATH, mode=0o600)


def load_hashes():
  if not os.path.exists(APPROVED_HASHES_FILE):
    return {}

  try:
    with open(APPROVED_HASHES_FILE, "r") as f:
      return json.load(f)


  except (json.JSONDecodeError, OSError):
    return {}


def save_hashes(hashes):
  tmp = APPROVED_HASHES_FILE + ".tmp"
  with open(tmp, "w") as f:
    json.dump(hashes, f, indent=2, sort_keys=True)

  os.replace(tmp, APPROVED_HASHES_FILE)


def run_check_script():
  # Best-effort: reconciles any hand-authored _pending/ files and
  # gives us a single place that also does the hyprctl reload.
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


def reload_hyprland():
  try:
    subprocess.run(["hyprctl", "reload"], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

  except FileNotFoundError:
    pass


def sha256_of(path):
  h = hashlib.sha256()
  with open(path, "rb") as f:
    for chunk in iter(lambda: f.read(65536), b""):
      h.update(chunk)


  return h.hexdigest()


def slot_name(path):
  # stable filename for a given source path, independent of file content
  return "req_" + hashlib.sha256(path.encode("utf-8")).hexdigest()[:16] + ".lua"


def live_file_path(path):
  return os.path.join(WR_DIR, slot_name(path))


def apply_grant(path):
  dest = live_file_path(path)
  filename = os.path.basename(dest)
  try:
    with open(path, "rb") as src:
      content = src.read()

    with open(dest, "wb") as dst:
      dst.write(content)


  except OSError as e:
    notify_simple("windowrule request: write failed", f"{path}\n{e}", urgency="critical")
    return

  hashes = load_hashes()
  hashes[filename] = hashlib.sha256(content).hexdigest()
  save_hashes(hashes)
  run_check_script()

  notify_simple(
    "Window-rule granted and active",
    f"{dest}\ngit add/commit approved_hashes.json + {filename}\nto keep it live across rebuilds",
    urgency="normal",
  )


def revoke(path, mark_denied):
  dest = live_file_path(path)
  filename = os.path.basename(dest)
  try:
    if os.path.exists(dest):
      os.remove(dest)


  except OSError:
    pass

  hashes = load_hashes()
  if mark_denied:
    hashes[filename] = DENIED
    save_hashes(hashes)
  elif filename in hashes:
    del hashes[filename]
    save_hashes(hashes)

  run_check_script()


def notify_simple(title, body, urgency="normal"):
  n = Notify.Notification.new(title, body)
  urgency_map = {"low": 0, "normal": 1, "critical": 2}
  n.set_urgency(urgency_map.get(urgency, 1))
  n.show()


def short(h):
  return h[:12] if h else "(none)"


def prompt_and_handle(path, new_hash, old_hash):
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
      apply_grant(path)
    elif action == "deny":
      revoke(path, mark_denied=True)
      notify_simple("Window-rule denied", path, urgency="low")
    elif action == "ignore":
      # ignore for now: no persistence, don't apply this time
      revoke(path, mark_denied=False)

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


def handle_request_line(target):
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

  hashes = load_hashes() # always fresh: picks up manual approved_hashes.json edits too
  filename = slot_name(target)
  old_hash = hashes.get(filename)

  if old_hash == new_hash and old_hash != DENIED:
    # previously granted, unchanged content -> auto-allow silently
    apply_grant(target)
    return

  if old_hash == DENIED:
    notify_simple("Window-rule request blocked", f"{target}\n(previously denied)", urgency="low")
    return

  prompt_and_handle(target, new_hash, old_hash)


def main():
  Notify.init("windowrule-daemon")

  ensure_fifo()
  # O_RDWR (not O_RDONLY) is the key trick: it makes us our own phantom
  # writer, so the FIFO never reports EOF/hang-up even when every real
  # writer (request_windowrule.sh invocations) has closed. O_NONBLOCK
  # so the open() itself can't block.
  fd = os.open(FIFO_PATH, os.O_RDWR | os.O_NONBLOCK)

  buffer = b""

  def on_readable(source, condition):
    nonlocal buffer
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
        handle_request_line(text)


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
