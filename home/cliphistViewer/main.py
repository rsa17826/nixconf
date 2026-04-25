#!/usr/bin/env python3
"""
cliphist-picker: a keyboard-driven TUI clipboard history picker.
Designed for Hyprland / Wayland. Requires cliphist + wl-clipboard.

Keys:
  Up/Down     — navigate
  Enter       — copy selected item and exit
  Esc         — quit without copying
  Backspace   — delete last filter character
  Any text    — start/continue filtering
"""

import curses
import subprocess
import sys

# ── helpers ──────────────────────────────────────────────────────────────────

def get_history() -> list[str]:
  try:
    result = subprocess.run(
      ["cliphist", "list"],
      capture_output=True,
      text=True,
      check=True,
    )
    lines = result.stdout.strip().split("\n")
    return [l for l in lines if l.strip()]
  except subprocess.CalledProcessError:
    return []
  except FileNotFoundError:
    sys.exit("cliphist not found — is it installed?")


def decode_and_copy(raw_line: str) -> None:
  """Pipe the raw cliphist list line through `cliphist decode | wl-copy`."""
  decoded = subprocess.run(
    ["cliphist", "decode"],
    input=raw_line.encode(),
    capture_output=True,
  )
  _ = subprocess.run(["wl-copy"], input=decoded.stdout, check=False)


def preview(raw_line: str, width: int) -> str:
  """Return the human-readable part of a cliphist list line, truncated."""
  # cliphist list format:  <id>\t<preview text>
  parts = raw_line.split("\t", 1)
  text = parts[1] if len(parts) == 2 else raw_line
  # collapse newlines for display
  text = text.replace("\n", "↵ ").replace("\r", "")
  return text[: width - 1]


# ── colour pairs ─────────────────────────────────────────────────────────────

C_NORMAL = 0
C_SELECTED = 1 # highlighted row
C_FILTER = 2    # search bar text
C_STATUS = 3    # bottom status bar
C_COUNT = 4     # item count in status bar
C_EMPTY = 5     # "no results" message
C_MATCH = 6     # matched substring in a normal row
C_MATCH_SEL = 7 # matched substring in the selected row


def init_colors() -> None:
  curses.use_default_colors()
  curses.init_pair(C_SELECTED,  curses.COLOR_BLACK,  curses.COLOR_CYAN)
  curses.init_pair(C_FILTER,    curses.COLOR_CYAN,   -1)
  curses.init_pair(C_STATUS,    curses.COLOR_BLACK,  curses.COLOR_WHITE)
  curses.init_pair(C_COUNT,     curses.COLOR_YELLOW, curses.COLOR_WHITE)
  curses.init_pair(C_EMPTY,     curses.COLOR_RED,    -1)
  curses.init_pair(C_MATCH,     curses.COLOR_YELLOW, -1)
  curses.init_pair(C_MATCH_SEL, curses.COLOR_YELLOW, curses.COLOR_CYAN)


# ── main TUI loop ─────────────────────────────────────────────────────────────


def run(stdscr: curses._CursesWindow) -> None:
  _ = curses.curs_set(0)
  init_colors()
  stdscr.keypad(True)

  all_items = get_history()
  filtered: list[str] = all_items[:]
  selected = 0
  scroll_top = 0
  filter_text = ""

  def apply_filter() -> None:
    nonlocal filtered, selected, scroll_top
    q = filter_text.lower()
    filtered = [i for i in all_items if q in i.lower()]
    selected = 0
    scroll_top = 0

  def clamp_scroll(list_h: int) -> None:
    nonlocal scroll_top
    if selected < scroll_top:
      scroll_top = selected
    elif selected >= scroll_top + list_h:
      scroll_top = selected - list_h + 1

  while True:
    stdscr.erase()
    h, w = stdscr.getmaxyx()

    # Writing exactly w chars to the last column moves the cursor off-screen
    # and raises _curses.error. Safe limit for all rows is w-1; for the last
    # row we use addnstr (which simply stops) rather than addstr.
    safe_w = max(1, w - 1)

    def safe_addstr(row: int, col: int, text: str, attr: int = 0) -> None:
      """addstr that never touches the bottom-right corner."""
      clipped = text[: safe_w - col]
      if not clipped:
        return
      try:
        if attr:
            stdscr.addstr(row, col, clipped, attr)
        else:
            stdscr.addstr(row, col, clipped)
      except curses.error:
        pass

    # ── search bar (row 0) ───────────────────────────────────────────────
    prompt = "  Search: "
    cursor = filter_text + "█"
    bar_text = (prompt + cursor).ljust(safe_w)[:safe_w]
    safe_addstr(0, 0, bar_text, curses.color_pair(C_FILTER))

    # ── item list (rows 1 … h-2) ─────────────────────────────────────────
    list_h = max(1, h - 2)
    clamp_scroll(list_h)

    if not filtered:
      safe_addstr(2, 0, "  no matches", curses.color_pair(C_EMPTY))
    else:
      for rel, item in enumerate(filtered[scroll_top : scroll_top + list_h]):
        row   = rel + 1
        abs_i = rel + scroll_top
        is_selected = abs_i == selected
        base_attr   = curses.color_pair(C_SELECTED) if is_selected else 0
        match_attr  = curses.color_pair(C_MATCH_SEL if is_selected else C_MATCH) | curses.A_BOLD

        line = ("  " + preview(item, safe_w - 2)).ljust(safe_w)[:safe_w]

        if not filter_text:
          safe_addstr(row, 0, line, base_attr)
        else:
          lo = line.lower().find(filter_text.lower())
          if lo == -1:
            safe_addstr(row, 0, line, base_attr)
          else:
            hi = lo + len(filter_text)
            safe_addstr(row, 0,  line[:lo],   base_attr)
            safe_addstr(row, lo, line[lo:hi],  match_attr)
            safe_addstr(row, hi, line[hi:],    base_attr)

    # ── status bar (last row) ────────────────────────────────────────────
    count_str = f" {selected + 1}/{len(filtered)} " if filtered else " 0/0 "
    hint = "  ↑↓ navigate   enter copy   esc quit"
    sb_full = (count_str + hint).ljust(safe_w)[:safe_w]
    safe_addstr(h - 1, 0, sb_full, curses.color_pair(C_STATUS))
    if safe_w > len(count_str) + 4:
      safe_addstr(h - 1, 0, count_str, curses.color_pair(C_COUNT))

    stdscr.refresh()

    # ── input handling ───────────────────────────────────────────────────
    try:
      key: str = stdscr.get_wch()
    except curses.error:
      continue

    # --- navigation & actions ---
    if key == "\x1b" or key == 27:
      return

    elif key in ("\n", "\r", curses.KEY_ENTER): # Enter → copy
      if filtered:
        decode_and_copy(filtered[selected])
      return

    elif key == curses.KEY_UP:
      if selected > 0:
        selected -= 1

    elif key == curses.KEY_DOWN:
      if selected < len(filtered) - 1:
        selected += 1

    elif key == curses.KEY_PPAGE: # Page Up
      selected = max(0, selected - list_h)

    elif key == curses.KEY_NPAGE: # Page Down
      selected = min(len(filtered) - 1, selected + list_h)

    elif key == curses.KEY_HOME:
      selected = 0

    elif key == curses.KEY_END:
      selected = max(0, len(filtered) - 1)

    # --- filter editing ---
    elif key in (curses.KEY_BACKSPACE, "\x7f", "\x08"):
      if filter_text:
        filter_text = filter_text[:-1]
        apply_filter()

    elif key == "\x15": # Ctrl-U clear line
      filter_text = ""
      apply_filter()

    elif isinstance(key, str) and key.isprintable() and len(key) == 1:
      # Guard: skip raw control characters that curses sometimes surfaces
      if ord(key) >= 32:
        filter_text += key
        apply_filter()


def main() -> None:
  import os

  _ = os.environ.setdefault("ESCDELAY", "0")
  try:
    curses.wrapper(run)
  except KeyboardInterrupt:
    pass


if __name__ == "__main__":
  main()