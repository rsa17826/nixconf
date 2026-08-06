#!/usr/bin/env python3
import sys
import json
import subprocess
import os
import glob
import re
import shlex
from typing import cast

# --- CACHING ---

CACHE_DIR = os.environ.get("XDG_CACHE_HOME", os.path.expanduser("~/.cache"))
CACHE_DIR = os.path.join(CACHE_DIR, "launcher")
APPS_CACHE_FILE = os.path.join(CACHE_DIR, "apps_cache.json")
EMOJI_CACHE_FILE = os.path.join(CACHE_DIR, "emoji_cache.json")


def _load_json_cache(path: str):
  try:
    with open(path, "r") as f:
      return json.load(f) # pyright: ignore[reportAny]


  except Exception:
    return None


def _save_json_cache(path: str, data) -> None: # pyright: ignore[reportMissingParameterType]
  try:
    os.makedirs(CACHE_DIR, exist_ok=True)
    tmp_path = f"{path}.tmp.{os.getpid()}"
    with open(tmp_path, "w") as f:
      json.dump(data, f)

    os.replace(tmp_path, path)

  except Exception:
    pass


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
  text = re.sub(r"(?<=\w)r", lambda m: sub_same_case(m.group(0), "w"), text, flags=re.IGNORECASE)
  text = re.sub(r"r(?=\w)", lambda m: sub_same_case(m.group(0), "w"), text, flags=re.IGNORECASE)

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


# --- EMOJI MODE ENGINE ---


def build_emoji_database() -> list[dict[str, str]]:
  """Builds a flat list of {char, name} from the `emoji` package's data table.

  The result never changes for a given installed version of the `emoji`
  package, so it's cached on disk and keyed by that version to avoid
  rebuilding + resorting the (large) table on every launch.
  """
  import emoji

  pkg_version = getattr(emoji, "__version__", "unknown")

  cached = _load_json_cache(EMOJI_CACHE_FILE)
  if isinstance(cached, dict) and cached.get("version") == pkg_version:
    items = cached.get("items")
    if isinstance(items, list):
      return cast(list[dict[str, str]], items)


  items: list[dict[str, str]] = []
  for char, data in emoji.EMOJI_DATA.items(): # pyright: ignore[reportAny]
    raw_name = cast(str, data.get("en", "")) # pyright: ignore[reportAny]
    if not raw_name:
      continue

    name = raw_name.strip(":").replace("_", " ")
    items.append({"char": char, "name": name})

  items = sorted(items, key=lambda x: x["name"])
  _save_json_cache(EMOJI_CACHE_FILE, {"version": pkg_version, "items": items})
  return items


def _js_escape(codepoint: int) -> str:
  if codepoint > 0xFFFF:
    cp = codepoint - 0x10000
    high = 0xD800 + (cp >> 10)
    low = 0xDC00 + (cp & 0x3FF)
    return f"\\u{high:04x}\\u{low:04x}"

  return f"\\u{codepoint:04x}"


def _python_escape(codepoint: int) -> str:
  if codepoint > 0xFFFF:
    return f"\\U{codepoint:08x}"

  return f"\\u{codepoint:04x}"


def get_emoji_encodings(char: str) -> list[dict[str, str]]:
  """Returns every common encoding for a (possibly multi-codepoint) emoji."""
  codepoints = [ord(c) for c in char]

  return [
    {"label": "emoji", "value": char},
    {"label": "codepoint", "value": " ".join(f"U+{cp:04X}" for cp in codepoints)},
    {"label": "html", "value": "".join(f"&#{cp};" for cp in codepoints)},
    {"label": "html (hex)", "value": "".join(f"&#x{cp:x};" for cp in codepoints)},
    {"label": "js/css", "value": "".join(_js_escape(cp) for cp in codepoints)},
    {"label": "python", "value": "".join(_python_escape(cp) for cp in codepoints)},
    {"label": "alt code", "value": " ".join(f"{cp:x}".upper() for cp in codepoints)},
    {"label": "^u code (ibus)", "value": " ".join(f"{cp:x}" for cp in codepoints)},
  ]


def _try_parse_pasted_emoji(query: str, emoji_char_set: set[str]) -> str | None:
  q = query.strip()
  if q in emoji_char_set:
    return q

  # A pasted emoji may have stray whitespace collapsed around it; also check
  # each maximal run of non-ascii characters in case of extra input.
  for token in re.findall(r"[^\x00-\x7F]+", q):
    if token in emoji_char_set:
      return token


  return None


def _try_parse_code(query: str) -> str | None:
  q = query.strip()
  if not q:
    return None

  # HTML entity, hex: &#x1F600; or &#x1F600
  m = re.match(r"^&#x([0-9a-fA-F]+);?$", q)
  if m:
    return chr(int(m.group(1), 16))

  # HTML entity, decimal: &#128512; or &#128512
  m = re.match(r"^&#(\d+);?$", q)
  if m:
    return chr(int(m.group(1)))

  # JS/CSS unicode escapes: \u1F600 or a surrogate pair \uD83D\uDE00
  parts = re.findall(r"\\u([0-9a-fA-F]{4,6})", q)
  if parts:
    codepoints = [int(p, 16) for p in parts]
    if len(codepoints) == 2 and 0xD800 <= codepoints[0] <= 0xDBFF and 0xDC00 <= codepoints[1] <= 0xDFFF:
      combined = ((codepoints[0] - 0xD800) << 10) + (codepoints[1] - 0xDC00) + 0x10000
      return chr(combined)

    try:
      return "".join(chr(cp) for cp in codepoints)

    except ValueError:
      return None


  # Python escape: \U0001F600
  m = re.match(r"^\\U([0-9a-fA-F]{8})$", q)
  if m:
    return chr(int(m.group(1), 16))

  # Bare hex codepoint: alt-code / ^U style input, optionally prefixed
  m = re.match(r"^(?:u\+|0x)?([0-9a-fA-F]{2,8})$", q, re.IGNORECASE)
  if m:
    try:
      return chr(int(m.group(1), 16))

    except (ValueError, OverflowError):
      return None


  return None


def search_emojis(query: str, all_emojis: list[dict[str, str]], emoji_char_set: set[str], limit: int = 60) -> list[dict[str, str]]:
  query = query.strip()
  if not query:
    return all_emojis[:limit]

  parsed_char = _try_parse_pasted_emoji(query, emoji_char_set) or _try_parse_code(query)
  if parsed_char:
    for item in all_emojis:
      if item["char"] == parsed_char:
        return [item]


    return [{"char": parsed_char, "name": "Unicode Character"}]

  q = query.lower()

  def rank(item: dict[str, str]) -> int:
    name = item["name"].lower()
    if name == q:
      return 0

    if name.startswith(q):
      return 1

    if q in name:
      return 2

    return 99

  matches = sorted(
    (item for item in all_emojis if rank(item) < 99),
    key=lambda item: (rank(item), item["name"]),
  )

  return matches[:limit]


def format_emoji_search_lines(matches: list[dict[str, str]]) -> list[dict[str, str]]:
  return [{"text": f"{m['char']} - {m['name']}", "icon": "accessories-character-map"} for m in matches]


def format_emoji_detail_lines(char: str) -> list[dict[str, str]]:
  encodings = get_emoji_encodings(char)
  return [{"text": f"{e['value']} - {e['label']}", "icon": "accessories-character-map"} for e in encodings]


# --- SYSTEM INTERACTION LAYER ---


def _desktop_file_signature() -> list[list]: # pyright: ignore[reportMissingTypeArgument]
  """Cheap fingerprint of every .desktop file we'd scan: (path, mtime) pairs.

  Computing this is just a glob + stat per file (no reading/parsing), so it's
  fast enough to run every launch to decide whether the cache is still valid.
  """
  xdg_data_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/run/current-system/sw/share:/usr/share").split(":")
  xdg_data_home = os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))

  search_paths = [os.path.join(xdg_data_home, "applications/*.desktop")]
  for data_dir in xdg_data_dirs:
    if os.path.exists(os.path.join(data_dir, "applications")):
      search_paths.append(os.path.join(data_dir, "applications/*.desktop"))


  sig: list[list] = [] # pyright: ignore[reportMissingTypeArgument]
  for path_pattern in search_paths:
    for filepath in glob.glob(path_pattern):
      try:
        sig.append([filepath, os.path.getmtime(filepath)])

      except OSError:
        continue



  sig.sort(key=lambda x: x[0])
  return sig


def get_desktop_apps() -> list[dict[str, str]]:
  """Scans system paths for installed desktop applications and extracts names, execs, and icons.

  Parsing + owowifying every .desktop file is the slow part of startup, so
  the result is cached on disk. The cache is reused as long as the set of
  .desktop files and their mtimes haven't changed since it was written.
  """
  current_sig = _desktop_file_signature()
  cached = _load_json_cache(APPS_CACHE_FILE)
  if isinstance(cached, dict) and cached.get("signature") == current_sig:
    apps = cached.get("apps")
    if isinstance(apps, list):
      return cast(list[dict[str, str]], apps)


  apps: list[dict[str, str]] = []
  xdg_data_dirs = os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/run/current-system/sw/share:/usr/share").split(":")
  xdg_data_home = os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))

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

          icon = icon_match.group(1).strip() if icon_match else "application-x-executable"
          workdir = path_match.group(1).strip() if path_match else ""

          if name not in seen_names:
            apps.append(
              {
                "name": name,
                "owo_name": owowify(name), # Pre-calculate the transformed text
                "exec": executable,
                "icon": icon,
                "workdir": workdir,
              }
            )
            seen_names.add(name)



      except Exception:
        continue



  apps = sorted(apps, key=lambda x: x["name"].lower())
  _save_json_cache(APPS_CACHE_FILE, {"signature": current_sig, "apps": apps})
  return apps


def copy_to_clipboard(text: str):
  clean_text = text.replace("➔", "").strip()
  try:
    _ = subprocess.run(["wl-copy"], input=clean_text, text=True, check=True, env=os.environ)

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
  all_emojis = build_emoji_database()
  emoji_char_set = {item["char"] for item in all_emojis}

  initial_state = {
    "input action": "send",
    "message": owowify("Type math or search apps, or : for emoji..."),
    "lines": format_rofi_lines("", all_apps),
  }
  print(json.dumps(initial_state), flush=True)

  active_math_calculation = ""
  current_displayed_apps = list(all_apps)
  # mode is one of: "normal", "emoji_search", "emoji_detail"
  mode = "normal"
  current_emoji_char = ""

  for line in sys.stdin:
    try:
      payload = json.loads(line) # pyright: ignore[reportAny]
      event_name: str = cast(
        str,
        payload.get("name", ""), # pyright: ignore[reportAny]
      )
      user_input: str = cast(
        str,
        payload.get("value", "").strip(), # pyright: ignore[reportAny]
      )

      # 1. HANDLE SELECTION ACTIONS
      if event_name == "select entry":
        if mode == "emoji_detail":
          parts = user_input.split(" - ", 1)
          code_value = parts[0].strip()
          if code_value:
            copy_to_clipboard(code_value)

          sys.exit(0)

        if mode == "emoji_search":
          parts = user_input.split(" - ", 1)
          if len(parts) == 2:
            selected_char = parts[0].strip()
            mode = "emoji_detail"
            current_emoji_char = selected_char
            response = {
              "input action": "send",
              "message": owowify(f"Encodings for {selected_char} - pick one to copy"),
              "lines": format_emoji_detail_lines(selected_char),
            }
            print(json.dumps(response), flush=True)

          continue

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

      # 2. HANDLE EMOJI MODE (prefix ':')
      if user_input.startswith(":"):
        mode = "emoji_search"
        query = user_input[1:]
        matches = search_emojis(query, all_emojis, emoji_char_set)
        msg = f"Emoji: {len(matches)} match(es)" if query else "Type an emoji name, paste an emoji, or enter a code..."
        response = {
          "input action": "send",
          "message": owowify(msg) if not query else msg,
          "lines": format_emoji_search_lines(matches) or [{"text": "", "icon": "dialog-warning"}],
        }
        print(json.dumps(response), flush=True)
        continue

      # Leaving emoji mode (input no longer starts with ':') falls through to
      # normal app/math handling below.
      if mode in ("emoji_search", "emoji_detail"):
        mode = "normal"
        current_emoji_char = ""

      # 3. HANDLE DYNAMIC SEARCH FILTERING & MATH EVALUATION
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
          name = app["name"].lower()
          owo_name = app["owo_name"].lower()
          exec_ = app["exec"].lower()

          if name == query or owo_name == query:
            return 0

          if name.startswith(query) or owo_name.startswith(query):
            return 1

          if query in name or query in owo_name:
            return 2

          # if owo_name == query:
          #   return 0
          # if owo_name.startswith(query):
          #   return 1
          # if query in owo_name:
          #   return 2
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
          msg = f"Result: {active_math_calculation}" if active_math_calculation else "Searching apps..."
          response = {
            "input action": "send",
            "message": owowify(msg),
            "lines": format_rofi_lines(active_math_calculation, current_displayed_apps),
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
