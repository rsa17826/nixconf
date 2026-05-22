#!/usr/bin/env python3
import sys
import json
import subprocess
import os
import glob
import re
from typing import cast
import threading

CACHE_DIR = os.path.expanduser("~/.cache/rofi-launcher-icons")
os.makedirs(CACHE_DIR, exist_ok=True)


def resolve_and_cache_icon_bg(icon_name: str, cache_path: str):
  """Background task to extract/copy the real theme icon to our fast cache."""
  if not icon_name or icon_name == "application-x-executable":
    return

  # Use system tools (like lxappearance, gtk-update-icon-cache lookups, or directly finding it)
  # A fast, reliable way in NixOS/Linux to resolve an icon name to a file path:
  try:
    # We look for the icon using a quick fallback sequence or xdg tools if available
    # For simplicity, we can use a quick search or match common sizes.
    # To keep it blazing fast and non-blocking, we use 'xdg-icon-resource' or 'find'
    # But even better: let's use a standard look up path.
    for base_path in [
      "/run/current-system/sw/share/icons/hicolor/48x48/apps",
      os.path.expanduser("~/.local/share/icons"),
    ]:
      found = glob.glob(f"{base_path}/{icon_name}.*")
      if found:
        # Cache the real file path so Rofi doesn't have to resolve the theme string next time
        with open(cache_path, "w") as f:
          _ = f.write(found[0])
        break
  except Exception:
    pass


def get_fast_icon(icon_name: str) -> str:
  """Returns a cached absolute path instantly, while spinning up a background check."""
  if not icon_name or "/" in icon_name:
    return icon_name or "application-x-executable"

  cache_path = os.path.join(CACHE_DIR, f"{icon_name}.path")

  # If we already have the resolved path cached from last time, use it instantly!
  if os.path.exists(cache_path):
    try:
      with open(cache_path, "r") as f:
        cached_real_path = f.read().strip()
        if os.path.exists(cached_real_path):
          return cached_real_path
    except Exception:
      pass

  # If it's a new icon or missing, trigger a background thread to cache it for next time
  # but immediately return the text name so Rofi doesn't freeze right now.
  threading.Thread(
    target=resolve_and_cache_icon_bg, args=(icon_name, cache_path), daemon=True
  ).start()
  return icon_name


def get_desktop_apps() -> list[dict[str, str]]:
  """Scans system paths for installed desktop applications and extracts names, execs, and icons."""
  apps: list[dict[str, str]] = []

  xdg_data_dirs = os.environ.get(
    "XDG_DATA_DIRS", "/usr/local/share:/run/current-system/sw/share:/usr/share"
  ).split(":")
  xdg_data_home = os.environ.get(
    "XDG_DATA_HOME", os.path.expanduser("~/.local/share")
  )

  paths = [os.path.join(xdg_data_home, "applications/*.desktop")]
  for data_dir in xdg_data_dirs:
    if os.path.exists(os.path.join(data_dir, "applications")):
      paths.append(os.path.join(data_dir, "applications/*.desktop"))

  seen_names: set[str] = set()
  for path_pattern in paths:
    for filepath in glob.glob(path_pattern):
      try:
        with open(filepath, "r", errors="ignore") as f:
          content = f.read()

        name_match = re.search(r"^Name=(.+)$", content, re.MULTILINE)
        exec_match = re.search(r"^Exec=(.+)$", content, re.MULTILINE)
        icon_match = re.search(r"^Icon=(.+)$", content, re.MULTILINE)
        no_display = re.search(r"^NoDisplay=[Tt]rue$", content, re.MULTILINE)

        if name_match and exec_match and not no_display:
          name = name_match.group(1).strip()
          executable = exec_match.group(1).strip()
          executable = re.sub(r" %Internal| %[uUfFdiInm]", "", executable)

          raw_icon = (
            icon_match.group(1).strip()
            if icon_match
            else "application-x-executable"
          )

          # --- MAGIC HAPPENS HERE ---
          # Instead of giving Rofi the raw icon name, we give it our lightning-fast cached path
          fast_icon = get_fast_icon(raw_icon)

          if name not in seen_names:
            apps.append(
              {"name": name, "exec": executable, "icon": fast_icon}
            )
            seen_names.add(name)
      except Exception:
        continue
  return sorted(apps, key=lambda x: x["name"].lower())


def copy_to_clipboard(text: str):
  """Copies math text to clipboard."""
  clean_text = text.replace("➔", "").strip()
  try:
    _ = subprocess.run(
      ["wl-copy"], input=clean_text, text=True, check=True, env=os.environ
    )
  except Exception:
    try:
      _ = subprocess.run(
        ["xclip", "-selection", "clipboard"],
        input=clean_text,
        text=True,
        check=True,
        env=os.environ,
      )
    except Exception:
      pass


def launch_app(exec_command: str):
  """Launches an application in the background detached from Rofi."""
  try:
    _ = subprocess.Popen(
      exec_command.split(),
      stdout=subprocess.DEVNULL,
      stderr=subprocess.DEVNULL,
      env=os.environ,
    )
  except Exception:
    pass


def format_rofi_lines(math_result: str, app_list: list[dict[str, str]]):
  lines: list[dict[str, str]] = []
  if math_result:
    lines.append(
      {
        "text": f"➔ {math_result}",
        "icon": "edit-paste",
      }
    )
  for app in app_list:
    lines.append({"text": app["name"], "icon": app["icon"]})
  return lines


def main():
  all_apps = get_desktop_apps()

  initial_state = {
    "input action": "send", # MUST be "send" to forward input events to Python
    "message": "Type math or search apps...",
    "lines": format_rofi_lines("", all_apps),
  }
  print(json.dumps(initial_state), flush=True)

  active_math_calculation = ""
  current_displayed_apps = list(all_apps)

  for line in sys.stdin:
    try:
      payload = json.loads(line) # pyright: ignore[reportAny]
      event_name: str = cast(
        str, payload.get("name", "") # pyright: ignore[reportAny]
      )
      user_input: str = cast(
        str, payload.get("value", "").strip() # pyright: ignore[reportAny]
      )

      # 1. HANDLE SELECTION ACTIONS (WHEN USER PRESSES ENTER)
      if event_name == "select entry":
        # Scenario A: The selected text row belongs to our math evaluation symbol
        if user_input.startswith("➔"):
          if active_math_calculation:
            copy_to_clipboard(active_math_calculation)
            sys.exit(0)
        else:
          # Scenario B: Match the selected app text directly against our app registry
          for app in all_apps:
            if app["name"] == user_input:
              launch_app(app["exec"])
              sys.exit(0)
        continue

      # 2. HANDLE DYNAMIC SEARCH FILTERING & MATH EVALUATION
      # 2. HANDLE DYNAMIC SEARCH FILTERING & MATH EVALUATION
      if not user_input:
        current_displayed_apps = list(all_apps)
        active_math_calculation = ""
        response = {
          "input action": "send",
          # Slight tweak to the message string forces Rofi to trigger a clean redraw
          "message": "Type math or search apps...",
          "lines": format_rofi_lines("", all_apps),
        }
      else:
        current_displayed_apps = [
          app
          for app in all_apps
          if user_input.lower() in app["name"].lower()
          or user_input.lower() in app["exec"].lower()
        ]

        try:
          # Basic sanitization check to prevent eval hanging on broken symbols
          if any(c in user_input for c in "+-*/%()0123456789 "):
            result = eval( # pyright: ignore[reportAny]
              user_input, {"__builtins__": None}, {}
            )
            active_math_calculation = str(
              result # pyright: ignore[reportAny]
            )
          else:
            active_math_calculation = ""
        except Exception:
          active_math_calculation = ""

        # Construct the response dynamically based on whether we actually found things
        if active_math_calculation or current_displayed_apps:
          response: dict[str, str | list[dict[str, str]]] = {
            "input action": "send",
            "message": (
              f"Result: {active_math_calculation}"
              if active_math_calculation
              else "Searching apps..."
            ),
            "lines": format_rofi_lines(
              active_math_calculation, current_displayed_apps
            ),
          }
        else:
          # CRITICAL FIX: If nothing matches, explicitly send an empty lines array
          # with a distinct message so Rofi registers the structural layout change.
          response = {
            "input action": "send",
            "message": f"No matches found for '{user_input}'",
            "lines": [],
          }
      _ = response["lines"].append( # type: ignore[union-attr] # pyright: ignore[reportUnknownMemberType, reportAttributeAccessIssue, reportUnknownVariableType]
        {
          "text": f"",
          "icon": "dialog-warning", # Keeps the UI structure intact
        }
      )
      print(json.dumps(response), flush=True)

    except Exception as e:
      print(json.dumps({"message": f"Error: {str(e)}", "lines": []}), flush=True)


if __name__ == "__main__":
  main()
