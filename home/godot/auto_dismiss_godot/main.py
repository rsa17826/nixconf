#!/usr/bin/env python3
import subprocess, time, tempfile, os, sys, json
import cv2, numpy as np

TEMPLATE_PATH = sys.argv[1] if len(sys.argv) > 1 else ""


def get_active_window_class() -> str:
  result = subprocess.run(
    ["hyprctl", "activewindow", "-j"], capture_output=True, text=True
  )
  try:
    return json.loads(result.stdout).get("class", "")
  except Exception:
    return ""


def take_screenshot() -> np.ndarray:
  with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as f:
    path = f.name
  subprocess.run(["grim", path], check=True)
  img = cv2.imread(path)
  os.unlink(path)
  return img


def find_template(screen: np.ndarray, template: np.ndarray, threshold=0.85):
  result = cv2.matchTemplate(screen, template, cv2.TM_CCOEFF_NORMED)
  _, max_val, _, max_loc = cv2.minMaxLoc(result)
  if max_val >= threshold:
    h, w = template.shape[:2]
    return max_loc[0] + w // 2, max_loc[1] + h // 2
  return None


def click(x: int, y: int):
  subprocess.run(
    ["ydotool", "mousemove", "--absolute", "-x", str(x // 2), "-y", str(y // 2)]
  )
  subprocess.run(["ydotool", "click", "0xC0"])


import evdev

MODIFIERS = {
  evdev.ecodes.KEY_LEFTCTRL,
  evdev.ecodes.KEY_RIGHTCTRL,
  evdev.ecodes.KEY_LEFTALT,
  evdev.ecodes.KEY_RIGHTALT,
  evdev.ecodes.KEY_LEFTSHIFT,
  evdev.ecodes.KEY_RIGHTSHIFT,
  evdev.ecodes.KEY_LEFTMETA,
  evdev.ecodes.KEY_RIGHTMETA,
}


def any_modifier_held() -> bool:
  for path in evdev.list_devices():
    try:
      dev = evdev.InputDevice(path)
      if MODIFIERS & set(dev.active_keys()):
        return True
    except Exception:
      pass
  return False


def main():
  template = cv2.imread(TEMPLATE_PATH)
  if template is None:
    raise FileNotFoundError(f"Template not found: {TEMPLATE_PATH}")
  print(f"Template loaded: {template.shape}", flush=True)

  while True:
    wclass = get_active_window_class()
    print(f"class={wclass}", flush=True)
    if wclass == "Godot":
      screen = take_screenshot()
      match = find_template(screen, template)
      print(f"Godot focused, match={match}", flush=True)
      if match:
        while any_modifier_held():
          time.sleep(0.05)
        time.sleep(0.1)
        click(*match)
        time.sleep(0.5)
    time.sleep(0.3)


if __name__ == "__main__":
  main()
