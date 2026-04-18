#!/usr/bin/env python3
"""
Watches ./Violentmonkey (VM JSON files) and syncs to ./userjs as named .user.js files.
- Violentmonkey/vm_xxx -> userjs/@name.user.js  (on start + when VM file changes)
- userjs/@name.user.js -> Violentmonkey/vm_xxx  (when you save the .user.js)
"""

import hashlib
import json
import re
import sys
import time
from pathlib import Path
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

BASE_DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
VM_DIR = BASE_DIR / "Violentmonkey"
JS_DIR = BASE_DIR / "userjs"

JS_DIR.mkdir(exist_ok=True)

_vm_to_js: dict[Path, Path] = {}
_js_to_vm: dict[Path, Path] = {}

# Last known hash of each file — skip write if content unchanged
_hashes: dict[Path, str] = {}


def md5(text: str) -> str:
  return hashlib.md5(text.encode()).hexdigest()


def extract_name(code: str) -> str:
  m = re.search(r"//\s*@name\s+(.+)", code)
  name = m.group(1).strip() if m else "unnamed"
  return re.sub(r'[<>:"/\\|?*]', "-", name)


def vm_to_js(vm_path: Path):
  try:
    data = json.loads(vm_path.read_text(encoding="utf-8"))
    code = data.get("code", "")
    if not code:
      return

    name = extract_name(code)
    js_path = JS_DIR / f"{name}.user.js"

    _vm_to_js[vm_path.resolve()] = js_path.resolve()
    _js_to_vm[js_path.resolve()] = vm_path.resolve()

    h = md5(code)
    if _hashes.get(js_path.resolve()) == h:
      return # content unchanged, skip
    _hashes[js_path.resolve()] = h

    js_path.write_text(code, encoding="utf-8")
    print(f"[vm->js]  {vm_path.name} -> userjs/{js_path.name}")
  except Exception as e:
    print(f"[error]  {vm_path.name}: {e}")


def js_to_vm(js_path: Path):
  vm_path = _js_to_vm.get(js_path.resolve())
  if not vm_path:
    print(f"[warn]   No matching VM file for {js_path.name}, skipping")
    return
  try:
    code = js_path.read_text(encoding="utf-8")

    h = md5(code)
    if _hashes.get(js_path.resolve()) == h:
      return # content unchanged, skip
    _hashes[js_path.resolve()] = h

    data = json.loads(vm_path.read_text(encoding="utf-8"))
    data["code"] = code

    vm_json = json.dumps(data)
    vh = md5(vm_json)
    if _hashes.get(vm_path.resolve()) == vh:
      return
    _hashes[vm_path.resolve()] = vh

    vm_path.write_text(vm_json, encoding="utf-8")
    print(f"[js->vm]  {js_path.name} -> {vm_path.name}")
  except Exception as e:
    print(f"[error]  {js_path.name}: {e}")


class SyncHandler(FileSystemEventHandler):
  def on_modified(self, event):
    if event.is_directory:
      return
    p = Path(event.src_path).resolve()

    if p.parent == JS_DIR.resolve() and p.name.endswith(".user.js"):
      js_to_vm(p)
    elif p.parent == VM_DIR.resolve() and "." not in p.name:
      vm_to_js(p)


def initial_sync():
  count = 0
  for f in VM_DIR.iterdir():
    if f.is_file() and "." not in f.name:
      vm_to_js(f)
      count += 1
  print(f"[init]   Synced {count} scripts -> {JS_DIR}")


if __name__ == "__main__":
  print(f"[vm_sync] Base: {BASE_DIR.resolve()}")
  print(f"          VM:   {VM_DIR}")
  print(f"          JS:   {JS_DIR}")
  initial_sync()

  handler = SyncHandler()
  observer = Observer()
  observer.schedule(handler, str(VM_DIR), recursive=False)
  observer.schedule(handler, str(JS_DIR), recursive=False)
  observer.start()
  print("[vm_sync] Watching for changes. Ctrl+C to stop.")
  try:
    while True:
      time.sleep(1)
  except KeyboardInterrupt:
    observer.stop()
  observer.join()
