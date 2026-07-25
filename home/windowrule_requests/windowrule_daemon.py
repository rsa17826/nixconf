#!/usr/bin/env python3

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
    if os.path.islink(dest) or os.path.exists(dest):
      os.remove(dest)

    with open(path, "rb") as src:
      content = src.read()

    with open(dest, "wb") as dst:
      dst.write(content)


  except OSError as e:
    notify_simple("windowrule request: link failed", f"{path}\n{e}", urgency="critical")
    return

  try:
    new_hash = sha256_of(path)

  except OSError as e:
    notify_simple("windowrule request: hash failed", f"{path}\n{e}", urgency="critical")
    return

  hashes = load_hashes()
  hashes[filename] = new_hash
  save_hashes(hashes)
  reload_hyprland()

  notify_simple(
    "Window-rule granted and active",
    f"{dest} -> {path}",
    urgency="normal",
  )


def revoke(path, mark_denied):
  dest = live_file_path(path)
  filename = os.path.basename(dest)
  try:
    if os.path.islink(dest) or os.path.exists(dest):
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

  reload_hyprland()


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
