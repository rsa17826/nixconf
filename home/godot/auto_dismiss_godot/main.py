#!/usr/bin/env python3
# auto_dismiss_godot.py
import subprocess, time, tempfile, os
import cv2, numpy as np

TEMPLATE_PATH = "/home/nyix/.config/godot-dismiss/ok_btn.png" # screenshot of the OK button

def get_active_window_class() -> str:
  result = subprocess.run(
    ["hyprctl", "activewindow", "-j"],
    capture_output=True, text=True
  )
  import json
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
    cx = max_loc[0] + w // 2
    cy = max_loc[1] + h // 2
    return cx, cy
  return None

def modifier_keys_held() -> bool:
  # Check if ctrl/alt/shift/super are held via /dev/input or just skip this check
  # ydotool doesn't expose key state easily; simplest is a small delay
  return False

def click(x: int, y: int):
  # ydotool requires ydotoold running: `systemctl --user start ydotoold`
  subprocess.run(["ydotool", "mousemove", "--absolute", "-x", str(x), "-y", str(y)])
  subprocess.run(["ydotool", "click", "0xC0"]) # left click

def main():
  template = cv2.imread(TEMPLATE_PATH)
  if template is None:
    raise FileNotFoundError(f"Template not found: {TEMPLATE_PATH}")

  while True:
    if get_active_window_class() == "godot":
      screen = take_screenshot()
      match = find_template(screen, template)
      if match:
        while modifier_keys_held():
          time.sleep(0.05)
        click(*match)
        time.sleep(0.5) # debounce
    time.sleep(0.3)

if __name__ == "__main__":
  main()