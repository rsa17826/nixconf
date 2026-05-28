#!/usr/bin/env python3
import sys
import json
import subprocess
import os
import glob
import re
import shlex
from typing import cast


def get_desktop_apps() -> list[dict[str, str]]:
  """Scans system paths for installed desktop applications and extracts names, execs, and icons."""
  apps: list[dict[str, str]] = []
  xdg_data_dirs = os.environ.get(
    "XDG_DATA_DIRS", "/usr/local/share:/run/current-system/sw/share:/usr/share"
  ).split(":")
  xdg_data_home = os.environ.get(
    "XDG_DATA_HOME", os.path.expanduser("~/.local/share")
  )

  search_paths = [os.path.join(xdg_data_home, "applications/*.desktop")]
  for data_dir in xdg_data_dirs:
    if os.path.exists(os.path.join(data_dir, "applications")):
      search_paths.append(os.path.join(data_dir, "applications/*.desktop"))

  seen_names: set[str] = set[str]()
  for path_pattern in search_paths:
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

          icon = (
            icon_match.group(1).strip()
            if icon_match
            else "application-x-executable"
          )

          if name not in seen_names:
            apps.append({"name": name, "exec": executable, "icon": icon})
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
      shlex.split(exec_command),
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
        query = user_input.lower()

        def match_rank(app: dict[str, str]) -> int:
          name = app["name"].lower()
          exec_ = app["exec"].lower()
          if name == query:
            return 0
          if name.startswith(query):
            return 1
          if query in name:
            return 2
          if query in exec_:
            return 3
          return 99

        current_displayed_apps = sorted(
          [app for app in all_apps if match_rank(app) < 99],
          key=lambda app: (match_rank(app), app["name"].lower()),
        )

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
