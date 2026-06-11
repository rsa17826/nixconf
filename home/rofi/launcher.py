#!/usr/bin/env python3
import sys
import json
import subprocess
import os
import glob
import re
import shlex
from typing import cast

# --- OWO TRANSLATION ENGINE ---

VOWEL = "[aiueo]"
VOWEL_NO_E = "[aiuo]"
VOWEL_NO_IE = "[auo]"
ZACKQY_WORD = "[jzckq]"


def sub_same_case(input_text: str, replace_text: str) -> str:
  result = []
  for i, char in enumerate(replace_text):
    if i < len(input_text):
      if input_text[i].isupper():
        result.append(char.upper())
      elif input_text[i].islower():
        result.append(char.lower())
      else:
        result.append(char)
    else:
      result.append(char)
  return "".join(result)


def owowify(text: str) -> str:
  text = str(text)
  end_sentence_pattern = r"([\w ,.!?]+)?"

  # OwO Emote Substitutions
  def sub_emote(emote: str):
    def repl(match: re.Match[str]) -> str:
      g1, g2 = match.group(1), match.group(2)
      if not g2 or g2.isspace():
        return f"{g1} {emote}"
      return match.group(0)

    return repl

  text = re.sub(
    rf"(i(?:'|)m(?:\s+|\s+so+\s+)bored){end_sentence_pattern}",
    sub_emote("-w-"),
    text,
    flags=re.IGNORECASE,
  )
  text = re.sub(
    rf"(love\s+(?:you|him|her|them)){end_sentence_pattern}",
    sub_emote("uwu"),
    text,
    flags=re.IGNORECASE,
  )
  text = re.sub(
    rf"(i\s+don(?:'|)t\s+care|i\s*d\s*c){end_sentence_pattern}",
    sub_emote("0w0"),
    text,
    flags=re.IGNORECASE,
  )

  # Word replacement
  text = re.sub(
    r"l[ou]ve?",
    lambda m: sub_same_case(m.group(0), "luv"),
    text,
    flags=re.IGNORECASE,
  )

  # R translation variations
  text = re.sub(
    r"(?<=\w)r", lambda m: sub_same_case(m.group(0), "w"), text, flags=re.IGNORECASE
  )
  text = re.sub(
    r"r(?=\w)", lambda m: sub_same_case(m.group(0), "w"), text, flags=re.IGNORECASE
  )

  # L translation variations
  def l_repl(match: re.Match[str]) -> str:
    word = match.group(0)
    runes = list(word)
    for i, char in enumerate(runes):
      if char.lower() != "l" or len(runes) == 1:
        continue
      if i + 1 < len(runes) and runes[i + 1].lower() in ["w", "l"]:
        continue
      prefix = "".join(runes[:i])
      if prefix and re.match(rf"^[wl]{VOWEL}*$", prefix, re.IGNORECASE):
        continue
      runes[i] = "W" if char.isupper() else "w"
    return "".join(runes)

  text = re.sub(r"[a-z]+", l_repl, text, flags=re.IGNORECASE)

  # Syllable modifications (N, M, P)
  text = re.sub(
    rf"n({VOWEL_NO_E}+)",
    lambda m: sub_same_case(m.group(0), f"ny{m.group(1)}"),
    text,
    flags=re.IGNORECASE,
  )

  def lookahead_sub(insertion: str):
    def repl(match: re.Match[str]) -> str:
      full_match = match.group(0)
      start_idx = match.start()
      following_text = text[start_idx + len(full_match) :]
      if re.match(rf"^w*{ZACKQY_WORD}", following_text, re.IGNORECASE):
        return full_match
      return sub_same_case(full_match, f"{insertion}{match.group(1)}")

    return repl

  # For the 'M' syllable rules:
  text = re.sub(rf"m({VOWEL_NO_IE}+)", lookahead_sub("my"), text, flags=re.IGNORECASE)

  # For the 'P' syllable rules:
  text = re.sub(rf"p({VOWEL_NO_IE}+)", lookahead_sub("pw"), text, flags=re.IGNORECASE)

  return text


# --- SYSTEM INTERACTION LAYER ---


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

  seen_names: set[str] = set()
  for path_pattern in search_paths:
    for filepath in glob.glob(path_pattern):
      try:
        with open(filepath, "r", errors="ignore") as f:
          content = f.read()

        name_match = re.search(r"^Name=(.+)$", content, re.MULTILINE)
        exec_match = re.search(r"^Exec=(.+)$", content, re.MULTILINE)
        icon_match = re.search(r"^Icon=(.+)$", content, re.MULTILINE)
        path_match = re.search(r"^Path=(.+)$", content, re.MULTILINE)
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
          workdir = path_match.group(1).strip() if path_match else ""

          if name not in seen_names:
            apps.append(
              {
                "name": name,
                "owo_name": owowify(
                  name
                ), # Pre-calculate the transformed text
                "exec": executable,
                "icon": icon,
                "workdir": workdir,
              }
            )
            seen_names.add(name)
      except Exception:
        continue
  return sorted(apps, key=lambda x: x["name"].lower())


def copy_to_clipboard(text: str):
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


def launch_app(exec_command: str, workdir: str = ""):
  """Launches an application in the background detached from Rofi."""
  try:
    _ = subprocess.Popen(
      shlex.split(exec_command),
      stdout=subprocess.DEVNULL,
      stderr=subprocess.DEVNULL,
      env=os.environ,
      cwd=workdir if workdir else None,
    )
  except Exception:
    pass


def format_rofi_lines(math_result: str, app_list: list[dict[str, str]]):
  lines: list[dict[str, str]] = []
  if math_result:
    lines.append(
      {
        "text": f"➔ {owowify(math_result)}",
        "icon": "edit-paste",
      }
    )
  for app in app_list:
    lines.append({"text": app["owo_name"], "icon": app["icon"]})
  return lines


def main():
  all_apps = get_desktop_apps()

  initial_state = {
    "input action": "send",
    "message": owowify("Type math or search apps..."),
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

      # 1. HANDLE SELECTION ACTIONS
      if event_name == "select entry":
        if user_input.startswith("➔"):
          if active_math_calculation:
            copy_to_clipboard(active_math_calculation)
            sys.exit(0)
        else:
          # Match against our pre-calculated 'owo_name' OR original 'name'
          for app in all_apps:
            if app["owo_name"] == user_input or app["name"] == user_input:
              launch_app(app["exec"], app.get("workdir", ""))
              sys.exit(0)
        continue

      # 2. HANDLE DYNAMIC SEARCH FILTERING & MATH EVALUATION
      if not user_input:
        current_displayed_apps = list(all_apps)
        active_math_calculation = ""
        response = {
          "input action": "send",
          "message": owowify("Type math or search apps..."),
          "lines": format_rofi_lines("", all_apps),
        }
      else:
        # The user query can be matched directly or converted out of OwO properties
        query = user_input.lower()

        def match_rank(app: dict[str, str]) -> int:
          # name = app["name"].lower()
          owo_name = app["owo_name"].lower()
          exec_ = app["exec"].lower()

          # if name == query or owo_name == query:
          #   return 0
          # if name.startswith(query) or owo_name.startswith(query):
          #   return 1
          # if query in name or query in owo_name:
          #   return 2
          if owo_name == query:
            return 0
          if owo_name.startswith(query):
            return 1
          if query in owo_name:
            return 2
          if query in owowify(exec_):
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

        if active_math_calculation or current_displayed_apps:
          msg = (
            f"Result: {active_math_calculation}"
            if active_math_calculation
            else "Searching apps..."
          )
          response = {
            "input action": "send",
            "message": owowify(msg),
            "lines": format_rofi_lines(
              active_math_calculation, current_displayed_apps
            ),
          }
        else:
          response = {
            "input action": "send",
            "message": owowify(f"No matches found for '{user_input}'"),
            "lines": [],
          }
      if not len(response["lines"]):
        _ = response["lines"].append( # type: ignore[union-attr] # pyright: ignore[reportUnknownMemberType, reportAttributeAccessIssue, reportUnknownVariableType]
          {
            "text": "",
            "icon": "dialog-warning",
          }
        )
      print(json.dumps(response), flush=True)

    except Exception as e:
      print(json.dumps({"message": f"Error: {str(e)}", "lines": []}), flush=True)


if __name__ == "__main__":
  main()
