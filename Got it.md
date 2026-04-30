
---

# If you want

👉 I can generate a minimal version of the overlay
👉 or generate a version for **VSCode** instead of VSCodium
👉 or help you convert DokiTheme into an actual Nix package (fully declarative)

Just tell me which direction you prefer.
To get **Ctrl + Backspace** to work like on Windows in **zsh** on **Hyprland** running on **NixOS**, you'll need to adjust a few things. Hyprland is a dynamic tiling Wayland compositor, and it doesn't use X11, so the process differs slightly from traditional X11 setups. Here's a step-by-step guide:

### 1. **Configure `zsh` to Delete Whole Words with `Ctrl + Backspace`**

By default, **zsh** doesn't recognize **Ctrl + Backspace** to delete whole words in the same way it works on Windows. To make it behave like Windows, you can modify the **`~/.zshrc`** configuration file.

1. Open your **zsh configuration** file:

   ```bash
   nano ~/.zshrc
   ```

2. Add the following line to map **Ctrl + Backspace** to **backward-kill-word**:

   ```zsh
   bindkey '^H' backward-kill-word
   ```

   This binds **Ctrl + Backspace** (which sends `^H`) to delete the previous word in **zsh**.

3. Save the file and reload **zsh** to apply the changes:

   ```bash
   source ~/.zshrc
   ```

### 2. **Ensure Hyprland is Passing the Correct Keycodes**

Since you're using **Hyprland** (Wayland), keybinding behavior might be different than on X11. The Wayland compositor needs to be configured to pass **Ctrl + Backspace** correctly.

1. Open the **Hyprland configuration file** (typically located at `~/.config/hypr/hyprland.conf`):

   ```bash
   nano ~/.config/hypr/hyprland.conf
   ```

2. You might need to define a custom keybinding to ensure **Ctrl + Backspace** is recognized. If you don't already have a keybinding set for **Ctrl + Backspace**, add the following to your config file:

   ```plaintext
   bind = CTRL+BACKSPACE, exec, "kill-word-backward"
   ```

   This will bind **Ctrl + Backspace** to a function that kills the word backward.

3. Save the file and reload **Hyprland** to apply the new keybinding.

### 3. **Check Wayland Support for Ctrl + Backspace**

If you're still having issues with **Ctrl + Backspace** not working as expected in **Wayland** (since Wayland compositors can behave differently than X11), ensure that your terminal emulator supports it under Wayland. For example, **Alacritty**, **Kitty**, or **Foot** are good options that tend to work well on **Wayland** and should support the same keybindings.

Make sure your terminal emulator is configured to allow **Ctrl + Backspace** to delete a whole word:

* For **Alacritty**, open the config file (`~/.config/alacritty/alacritty.yml`) and ensure the keybindings for **Ctrl + Backspace** are set up like this:

  ```yaml
  key_bindings:
    - { key: Backspace, mods: Control, action: DeletePreviousWord }
  ```

### 4. **Reboot or Restart Your Session**

After making these changes, it's good to either restart your terminal session or reboot your system to ensure everything is working as expected.

---

### Summary of Steps:

1. Modify your **`~/.zshrc`** to bind **Ctrl + Backspace** to **backward-kill-word**.
2. Add a custom keybinding for **Ctrl + Backspace** in the **Hyprland** config file.
3. Make sure your terminal emulator (like **Alacritty** or **Kitty**) supports the keybinding under **Wayland**.

Let me know if you run into any issues!
Ah! Now I understand clearly — you want **a Wayland version of AutoHotkey's hotstring/hotkey functionality** on **Hyprland**, which means:

* **Intercept input** (detect key sequences in real time).
* **Modify/replace them** (like hotstrings or hotkeys).
* **Send synthetic input back** to applications.

This is tricky on Wayland because of **security restrictions** — clients cannot see or inject arbitrary input; the **compositor is the only trusted layer**. But there are a few approaches:

---

## 1️⃣ Use Hyprland's config for “hotkeys” (limited)

Hyprland has **bind commands**:

```ini
bind = KEY_A, exec, some-command
```

* Can trigger programs/scripts on key combos.
* Cannot do text replacement like AHK hotstrings.
* Only works for global hotkeys, not inline text replacement in clients.

**→ Not enough for full AHK-style hotstrings.**

---

## 2️⃣ User-space intercept + uinput (the closest AHK equivalent)

This is how people implement AutoHotkey-like functionality on Wayland:

### How it works:

1. **Listen to the keyboard using `evdev` / `libinput`**:

   * You need to grab `/dev/input/event*` for your keyboard.
   * Tools/libraries:

     * [libevdev](https://www.freedesktop.org/wiki/Software/libevdev/) (low-level)
     * [python-evdev](https://python-evdev.readthedocs.io/en/latest/) (Python binding)

2. **Detect hotstrings in your program**:

   * Keep a buffer of typed keys.
   * When a hotstring is detected (like `btw` → `by the way`), delete original keystrokes and send replacement.

3. **Send synthetic input via `uinput`**:

   * Create a **virtual keyboard device** using `uinput`.
   * Emit key events corresponding to replacement text.

4. **Use compositor (Hyprland) with the virtual keyboard**:

   * Hyprland sees your `uinput` device as a normal keyboard.
   * Your hotstrings appear in all clients transparently.

---

### Minimal Python example (conceptual)

```python
import evdev
from evdev import UInput, ecodes

# Grab real keyboard
device = evdev.InputDevice('/dev/input/event3')

# Create virtual keyboard
ui = UInput()

buffer = []

HOTSTRING = "btw"
REPLACEMENT = "by the way"

for event in device.read_loop():
    if event.type == ecodes.EV_KEY:
        key_event = evdev.categorize(event)
        if key_event.keystate == key_event.key_down:
            buffer.append(key_event.keycode[-1])  # 'A', 'B', etc.

            if ''.join(buffer[-len(HOTSTRING):]).lower() == HOTSTRING:
                # Send backspace to delete hotstring
                for _ in HOTSTRING:
                    ui.write(ecodes.EV_KEY, ecodes.KEY_BACKSPACE, 1)
                    ui.write(ecodes.EV_KEY, ecodes.KEY_BACKSPACE, 0)
                # Send replacement
                for char in REPLACEMENT:
                    ui.write(ecodes.EV_KEY, ecodes.ecodes[f'KEY_{char.upper()}'], 1)
                    ui.write(ecodes.EV_KEY, ecodes.ecodes[f'KEY_{char.upper()}'], 0)
                ui.syn()
```

**Notes:**

* Needs **root** or proper `uinput` permissions.
* Key mapping is tricky (`a-z`, uppercase, special chars).
* Works **globally**, not limited to a single window.
* You can expand to full AHK-like hotstrings and hotkeys.

---

## 3️⃣ Alternative: Patch Hyprland input code

* If you want **no root / no uinput**, you would need to modify Hyprland itself:

  * Intercept `keyboardKey` events in Hyprland.
  * Maintain a buffer per seat.
  * On hotstring match, inject new keys via `wl_keyboard` protocol.

* **Pros**: No root, integrated.

* **Cons**: Complex C++ development, need to maintain a fork.

---

### ✅ Summary

| Method                    | Pros                | Cons                                              |
| ------------------------- | ------------------- | ------------------------------------------------- |
| Hyprland config hotkeys   | Simple              | Cannot do hotstrings                              |
| User-space evdev + uinput | Flexible, works now | Needs root or uinput permissions, complex mapping |
| Patch Hyprland            | Rootless, native    | Hard, requires maintaining a fork                 |

---

💡 **My recommendation**:

If you want something working **today**, do **evdev + uinput** for a global AHK-like hotstring tool. Later, if you're ambitious, you can integrate it into Hyprland proper.

---

I can make you a **ready-to-use Python “hotstring engine” for Hyprland** that:

* Detects typed hotstrings.
* Deletes them.
* Replaces them with your text.
* Works globally.

Do you want me to do that next?
Perfect! Let's build a **minimal working global hotstring engine for Hyprland** using Python. This will work **today**, without touching Hyprland's source code.

It will:

* Grab your real keyboard input (`evdev`)
* Detect hotstrings (like `btw`)
* Delete the typed hotstring
* Send replacement text using a **virtual keyboard (`uinput`)**

---

## Step 1: Set up permissions

1. **Install Python and dependencies**:

```bash
sudo pacman -S python python-evdev  # Arch/Hyprland typical
# or for Debian/Ubuntu:
sudo apt install python3 python3-evdev
```

2. **Give access to `/dev/input/event*`**:

* You can run as root: `sudo python3 hotstrings.py`
* Or add your user to `input` group and allow `uinput`:

```bash
sudo usermod -aG input $USER
sudo chmod 666 /dev/uinput
```

---

## Step 2: Minimal Python hotstring engine

```python
#!/usr/bin/env python3
import evdev
from evdev import UInput, ecodes
import time

# === CONFIG ===
HOTSTRINGS = {
    "btw": "by the way",
    "omw": "on my way"
}

# Find your keyboard device
# e.g., run: python3 -m evdev.evtest
DEVICE_PATH = "/dev/input/event3"  # adjust for your keyboard

# Mapping letters to keycodes
LETTER_MAP = {c: getattr(ecodes, f'KEY_{c.upper()}') for c in "abcdefghijklmnopqrstuvwxyz"}

# === SETUP ===
keyboard = evdev.InputDevice(DEVICE_PATH)
ui = UInput()  # virtual keyboard

buffer = []

def send_text(text):
    for char in text:
        if char.lower() in LETTER_MAP:
            code = LETTER_MAP[char.lower()]
            # handle uppercase
            if char.isupper():
                ui.write(ecodes.EV_KEY, ecodes.KEY_LEFTSHIFT, 1)
                ui.write(ecodes.EV_KEY, code, 1)
                ui.write(ecodes.EV_KEY, code, 0)
                ui.write(ecodes.EV_KEY, ecodes.KEY_LEFTSHIFT, 0)
            else:
                ui.write(ecodes.EV_KEY, code, 1)
                ui.write(ecodes.EV_KEY, code, 0)
        elif char == " ":
            ui.write(ecodes.EV_KEY, ecodes.KEY_SPACE, 1)
            ui.write(ecodes.EV_KEY, ecodes.KEY_SPACE, 0)
        # add more symbols if needed
    ui.syn()

def backspace(n):
    for _ in range(n):
        ui.write(ecodes.EV_KEY, ecodes.KEY_BACKSPACE, 1)
        ui.write(ecodes.EV_KEY, ecodes.KEY_BACKSPACE, 0)
    ui.syn()

# === MAIN LOOP ===
for event in keyboard.read_loop():
    if event.type == ecodes.EV_KEY:
        key_event = evdev.categorize(event)
        if key_event.keystate == key_event.key_down:
            key_name = key_event.keycode
            if isinstance(key_name, list):
                key_name = key_name[0]
            # Only track letters and space
            if key_name.startswith("KEY_"):
                char = key_name[-1].lower()
                if char.isalpha() or char == " ":
                    buffer.append(char)

            # Check hotstrings
            for hot, replacement in HOTSTRINGS.items():
                if ''.join(buffer[-len(hot):]) == hot:
                    backspace(len(hot))
                    send_text(replacement)
```

---

## Step 3: Run it

```bash
sudo python3 hotstrings.py
```

* Type `btw` → gets replaced with `by the way`.
* Type `omw` → gets replaced with `on my way`.

---

## Step 4: Improvements you can make

1. Add **numbers, punctuation, Shift handling**.
2. Handle **multiple keyboards** or layout changes.
3. Run it as a **background daemon**.
4. Auto-detect keyboard devices with:

```python
for dev in [evdev.InputDevice(path) for path in evdev.list_devices()]:
    if "keyboard" in dev.name.lower():
        print(dev.path, dev.name)
```

---

### ✅ Notes

* This works **globally in Wayland** (Hyprland).
* **No compositor patching** required.
* Only limitation: you need **uinput permissions**.
* Performance is very good for hotstring replacements.

---

I can also make a **ready-to-run full script** that:

* Auto-detects your keyboard
* Handles letters, numbers, symbols
* Supports multiple hotstrings
* Can run as a systemd user service

This would be like a **full AutoHotkey replacement on Hyprland**.

Do you want me to make that next?
Ah — you want the **shift handling to respect the real physical Shift key state** and only inject Shift as needed. This avoids "double shift" issues when typing uppercase letters while holding Shift, and ensures that temporary shifts for lowercase letters don't interfere with a real pressed Shift.

Here's a corrected approach for your `send_text` function:

---

```python
def send_text(text, real_shift_down=False):
    """
    text: string to send
    real_shift_down: True if the real physical Shift is currently being held
    """
    for char in text:
        if char.lower() in LETTER_MAP:
            code = LETTER_MAP[char.lower()]
            char_needs_shift = char.isupper()

            # Determine if we need to press temporary shift
            temp_shift = False
            if char_needs_shift and not real_shift_down:
                # uppercase, real shift not held → press temporary shift
                ui.write(ecodes.EV_KEY, ecodes.KEY_LEFTSHIFT, 1)
                temp_shift = True
            elif not char_needs_shift and real_shift_down:
                # lowercase while real shift is held → temporarily release real shift
                ui.write(ecodes.EV_KEY, ecodes.KEY_LEFTSHIFT, 0)
                temp_shift = True  # mark as temporarily changed

            # Send the key
            ui.write(ecodes.EV_KEY, code, 1)
            ui.write(ecodes.EV_KEY, code, 0)

            # Restore shift state if we temporarily changed it
            if temp_shift:
                if char_needs_shift and not real_shift_down:
                    ui.write(ecodes.EV_KEY, ecodes.KEY_LEFTSHIFT, 0)
                elif not char_needs_shift and real_shift_down:
                    ui.write(ecodes.EV_KEY, ecodes.KEY_LEFTSHIFT, 1)

        elif char == " ":
            ui.write(ecodes.EV_KEY, ecodes.KEY_SPACE, 1)
            ui.write(ecodes.EV_KEY, ecodes.KEY_SPACE, 0)
        # Add other symbols here if needed

    ui.syn()
```

---

### ✅ How it works

1. **If character is uppercase (`char.isupper()`)**:

   * If **Shift is not physically held**, press temporary Shift for that key only.
   * If **Shift is already held**, do nothing — just send the key.

2. **If character is lowercase**:

   * If **Shift is physically held**, temporarily release it for that key.
   * If **Shift is not held**, do nothing.

3. **After each key**, restore Shift to the correct state if it was temporarily modified.

---

### Example usage

You need to **track real Shift state** from the keyboard events:

```python
real_shift_down = False

for event in keyboard.read_loop():
    if event.type == ecodes.EV_KEY:
        key_event = evdev.categorize(event)
        if key_event.keystate == key_event.key_down:
            if key_event.keycode in ["KEY_LEFTSHIFT", "KEY_RIGHTSHIFT"]:
                real_shift_down = True
        elif key_event.keystate == key_event.key_up:
            if key_event.keycode in ["KEY_LEFTSHIFT", "KEY_RIGHTSHIFT"]:
                real_shift_down = False

        # When sending text:
        send_text("Hello World", real_shift_down=real_shift_down)
```

This ensures your **hotstring replacements respect actual Shift presses**.

---

If you want, I can **rewrite your full Python hotstring engine** with this logic included, so Shift, CapsLock, numbers, and symbols all work like a proper AHK replacement.

Do you want me to do that?
Perfect! Let's rewrite your **full hotstring engine** for Hyprland with **proper Shift/CapsLock handling**, letters, numbers, and basic symbols. This will work like a minimal AutoHotkey replacement, respecting the **physical Shift state**, so hotstrings don't conflict with real key presses.

---

## Full Python Hotstring Engine

```python
#!/usr/bin/env python3
import evdev
from evdev import UInput, ecodes
import sys
import time

# === CONFIG ===
HOTSTRINGS = {
    "btw": "by the way",
    "omw": "on my way",
    "afaik": "as far as I know",
}

# Adjust this to your keyboard device
# Run: python3 -m evdev.evtest to see devices
DEVICE_PATH = "/dev/input/event3"

# Keycode mapping for letters, numbers, space, basic punctuation
LETTER_MAP = {c: getattr(ecodes, f"KEY_{c.upper()}") for c in "abcdefghijklmnopqrstuvwxyz"}
NUMBER_MAP = {str(n): getattr(ecodes, f"KEY_{n}") for n in range(10)}
SYMBOL_MAP = {
    " ": ecodes.KEY_SPACE,
    ".": ecodes.KEY_DOT,
    ",": ecodes.KEY_COMMA,
    "!": ecodes.KEY_1,  # send with shift
    "?": ecodes.KEY_SLASH,  # send with shift
    "-": ecodes.KEY_MINUS,
    "_": ecodes.KEY_MINUS,  # shift
}

# Merge letters and numbers for convenience
KEY_MAP = {**LETTER_MAP, **NUMBER_MAP, **SYMBOL_MAP}

# === SETUP DEVICES ===
try:
    keyboard = evdev.InputDevice(DEVICE_PATH)
except Exception as e:
    print(f"Failed to open device {DEVICE_PATH}: {e}")
    sys.exit(1)

ui = UInput()  # virtual keyboard

buffer = []
real_shift_down = False
real_capslock = False

# === UTILITY FUNCTIONS ===
def backspace(n):
    for _ in range(n):
        ui.write(ecodes.EV_KEY, ecodes.KEY_BACKSPACE, 1)
        ui.write(ecodes.EV_KEY, ecodes.KEY_BACKSPACE, 0)
    ui.syn()

def send_key(keycode, shift_needed=False, real_shift=False):
    """Send a key with optional temporary shift handling"""
    temp_shift = False

    # Determine if we need temporary shift
    if shift_needed and not real_shift:
        ui.write(ecodes.EV_KEY, ecodes.KEY_LEFTSHIFT, 1)
        temp_shift = True
    elif not shift_needed and real_shift:
        ui.write(ecodes.EV_KEY, ecodes.KEY_LEFTSHIFT, 0)
        temp_shift = True

    # Press and release the key
    ui.write(ecodes.EV_KEY, keycode, 1)
    ui.write(ecodes.EV_KEY, keycode, 0)

    # Restore shift state if temporarily modified
    if temp_shift:
        if shift_needed and not real_shift:
            ui.write(ecodes.EV_KEY, ecodes.KEY_LEFTSHIFT, 0)
        elif not shift_needed and real_shift:
            ui.write(ecodes.EV_KEY, ecodes.KEY_LEFTSHIFT, 1)

def send_text(text, real_shift_down=False, capslock=False):
    for char in text:
        shift_needed = False

        # Letters
        if char.lower() in LETTER_MAP:
            keycode = LETTER_MAP[char.lower()]
            if (char.isupper() and not capslock) or (char.islower() and capslock):
                shift_needed = True

        # Numbers and symbols
        elif char in NUMBER_MAP:
            keycode = NUMBER_MAP[char]
            shift_needed = False
        elif char in SYMBOL_MAP:
            keycode = SYMBOL_MAP[char]
            if char in ["!", "?","_"]:
                shift_needed = True
        else:
            continue  # skip unsupported

        send_key(keycode, shift_needed, real_shift_down)

    ui.syn()

# === MAIN LOOP ===
for event in keyboard.read_loop():
    if event.type == ecodes.EV_KEY:
        key_event = evdev.categorize(event)

        # Track real shift keys
        if key_event.keycode in ["KEY_LEFTSHIFT", "KEY_RIGHTSHIFT"]:
            real_shift_down = key_event.keystate == key_event.key_down

        # Track CapsLock
        if key_event.keycode == "KEY_CAPSLOCK" and key_event.keystate == key_event.key_down:
            real_capslock = not real_capslock

        # Only track key down events for typing
        if key_event.keystate != key_event.key_down:
            continue

        # Map letters and space into buffer for hotstring detection
        char = None
        if key_event.keycode.startswith("KEY_"):
            name = key_event.keycode[-1].lower()
            if name.isalpha() or name.isdigit() or key_event.keycode in ["KEY_SPACE"]:
                if key_event.keycode == "KEY_SPACE":
                    char = " "
                elif name.isalpha():
                    char = name
                elif name.isdigit():
                    char = name

        if char:
            buffer.append(char)

        # Check hotstrings
        for hot, replacement in HOTSTRINGS.items():
            if ''.join(buffer[-len(hot):]) == hot:
                # Remove typed hotstring
                backspace(len(hot))
                # Send replacement
                send_text(replacement, real_shift_down=real_shift_down, capslock=real_capslock)
```

---

### ✅ Features

1. **Tracks physical Shift and CapsLock**

   * Respects held Shift while sending uppercase letters
   * Temporarily modifies Shift for lowercase letters if needed

2. **Hotstrings**

   * Works globally, in any Wayland client
   * Simple dictionary, easy to add more

3. **Supports letters, numbers, space, basic punctuation**

   * Symbols like `!`, `?`, `_` handled via Shift

4. **Root / permissions**

   * Needs either root or `uinput` access
   * Can run as a systemd user service for startup

---

### Next steps

* Expand `SYMBOL_MAP` to support more punctuation (`@`, `#`, etc.)
* Add **multi-key hotstrings** like `::btw::` style triggers
* Run as **background daemon** in Hyprland

---

If you want, I can write the **systemd user service setup** next, so this hotstring engine **starts automatically when Hyprland launches** and runs globally like AHK.

Do you want me to do that?
Perfect! We can do this **fully declaratively in NixOS**, so NumLock is forced on and CapsLock is forced off at session start in **Hyprland / Wayland**, without relying on X11 or `numlockx`.

We'll use **a small systemd user service** that runs a **uinput script** at startup.

---

## 1️⃣ Create the uinput script

Let's make a simple script that **turns on NumLock and turns off CapsLock**:

```bash
# /etc/nixos/scripts/fix-locks.py
#!/usr/bin/env python3
from evdev import UInput, ecodes
import time

ui = UInput()

# Turn NumLock ON
ui.write(ecodes.EV_KEY, ecodes.KEY_NUMLOCK, 1)
ui.write(ecodes.EV_KEY, ecodes.KEY_NUMLOCK, 0)

# Turn CapsLock OFF
ui.write(ecodes.EV_KEY, ecodes.KEY_CAPSLOCK, 0)
ui.syn()
```

* Make it executable:

```bash
sudo chmod +x /etc/nixos/scripts/fix-locks.py
```

---

## 2️⃣ Create a systemd user service

```nix
# In your configuration.nix or home.nix
systemd.user.units.fix-locks.service = {
  description = "Force NumLock on and CapsLock off for Wayland sessions";
  after = [ "graphical.target" ];

  serviceConfig = {
    ExecStart = "/etc/nixos/scripts/fix-locks.py";
    Type = "oneshot";
    RemainAfterExit = true;
  };
  wantedBy = [ "default.target" ];
};
```

* This runs **once at user login**.
* Works with **Wayland (Hyprland)** because it uses uinput.

---

## 3️⃣ Ensure uinput permissions

* Add your user to the `input` group and allow uinput:

```bash
sudo usermod -aG input $USER
sudo chmod 666 /dev/uinput
```

* On NixOS, you can also declaratively enable uinput:

```nix
# configuration.nix
boot.kernelModules = [ "uinput" ];
```

---

## 4️⃣ Rebuild and enable

```bash
sudo nixos-rebuild switch
systemctl --user enable fix-locks.service
systemctl --user start fix-locks.service
```

* NumLock will be on.
* CapsLock will be off.
* Works in Hyprland / Wayland sessions.

---

✅ **Advantages**:

* Fully declarative in NixOS.
* No X11 / numlockx needed.
* Works for all Wayland compositors, including Hyprland.
* Can be extended to force LED states at login for multiple keyboards.

---

If you want, I can **rewrite it to automatically detect multiple keyboards** and enforce **NumLock on / CapsLock off** for all of them in one script — fully plug-and-play for Hyprland.

Do you want me to do that?


mkdir -p /home/nyx/.config/sops/age/ ; nix-shell -p age --run "age-keygen -o /home/nyx/.config/sops/age/keys.txt"



blackbox-terminal
environment.variables = {
    TERMINAL = "blackbox";
  };

  # Force GTK4 apps to prefer dark mode
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

bind = CTRL_ALT, T, exec, blackbox

To do this on Linux (especially NixOS), you have to change how you think about the "Input Stream."

In Windows/AHK, you are essentially "editing" a live stream. In Linux, because of the security architecture, you have to **become** the stream. To achieve exactly what you wrote—detecting the end of a sequence and then locking out the user while you fix it—you use **Kanata's `v-chords` (virtual chords)** or **`sequences`**.

Here is the "Logic Map" of how Kanata executes your pseudo-code:

---

### The Strategy: The "Instant-Release" Buffer

We will configure Kanata to:

1. **Pass keys through instantly** so you don't feel lag.
2. **Keep a "Shadow Buffer"** of what you just typed.
3. **Trigger a Macro** the moment the shadow buffer matches `tset`.
4. **Lock the hardware** (BlockInput) for a few milliseconds so your fingers can't "interrupt" the correction.

### The NixOS Configuration

Add this to your `services.kanata.keyboards.<name>.config` section:

```lisp
(defalias
  ;; This is your 'BlockInput' and 'Fix' logic
  ;; 'm-release-all' effectively blocks your physical fingers from
  ;; sending new keys until the macro finishes.
  fix_tset (macro
    (m-release-all)   ;; Block/Release physical keys
    bspc bspc bspc bspc bspc ;; {bs 5}
    t e s t spc       ;; "test "
  )
)

(defsequence
  ;; If lastKeys ends with "tset" + "spc"
  tset_trigger (t s e t spc) @fix_tset
)

```

---

### Why this works better than Espanso

* **The Lock:** The `(m-release-all)` command tells Kanata to ignore any physical state changes (your fingers pressing new keys) until the macro string is finished. It acts as your `blockinput(1)`.
* **Zero Lag:** Because we aren't using a "Look-ahead" chord here, the letters `t`, `s`, `e`, `t` appear on your screen the millisecond you touch the keys.
* **The Cleanup:** Because it's at the kernel level, the `bspc` (backspace) commands are sent to the OS faster than a human can physically press the next key.

### How to apply this to your NixOS machine

1. **Identify your keyboard:** Run `ls /dev/input/by-path/` and look for the one ending in `-kbd`.
2. **Update Config:** Put the code above into your `configuration.nix`.
3. **Rebuild:** `sudo nixos-rebuild switch`.

### One "Pro" Tip

If you have a lot of these (like a full AHK script), listing them all as `defsequence` can get messy. Most people use a **"Leader Key"** or a specific **"Typo Layer."**

**Would you like me to show you how to find your exact keyboard path `/dev/input/by-path/...` so this config actually hooks into your hardware?**


import re
import os

# Paths - Update these to your actual file locations
AHK_FILE = "./autocorrect.ahk"
NIX_FILE = "./configuration.nix"

def ahk_line_to_kanata(line):
    line = line.strip()
    # Skip comments, brackets, and empty lines
    if not line or line.startswith(';') or '{' in line or '}' in line or 'return' in line:
        return None, None

    # Regex to capture AHK hotstrings
    match = re.match(r'^:([^:]*):([^:]+)::(.*)$', line)
    if not match:
        return None, None

    options, trigger, replacement = match.groups()
    replacement = replacement.split(';')[0].strip()

    # If replacement is empty, it's an exclusion (reign -> reign)
    if not replacement:
        replacement = trigger

    # Sanitize name for Kanata alias
    safe_name = re.sub(r'[^a-zA-Z]', '_', trigger)
    alias_name = f"fix_{safe_name}"

    # Build Macro string
    # We map common symbols to Kanata names
    key_map = {';': 'semi', ',': 'comma', "'": 'squote', '.': 'dot', ' ': 'spc'}

    def get_key(char):
        return key_map.get(char, char)

    bs_str = " ".join(["bspc"] * len(trigger))
    repl_str = " ".join([get_key(c) for c in replacement])
    trig_str = " ".join([get_key(c) for c in trigger])

    alias = f"      {alias_name} (macro {bs_str} {repl_str})"
    sequence = f"      ({trig_str}) @{alias_name}"

    return alias, sequence

def update_nix_config():
    aliases = []
    sequences = []

    with open(AHK_FILE, 'r') as f:
        for line in f:
            a, s = ahk_line_to_kanata(line)
            if a:
                aliases.append(a)
                sequences.append(s)

    with open(NIX_FILE, 'r') as f:
        content = f.read()

    # Replace content between markers
    alias_block = "\n".join(aliases)
    seq_block = "\n".join(sequences)

    # Use regex to find and replace content between our markers
    content = re.sub(r'(# KANATA_ALIASES_START).*?(# KANATA_ALIASES_END)',
                     f'\\1\n{alias_block}\n      \\2', content, flags=re.DOTALL)
    content = re.sub(r'(# KANATA_SEQUENCES_START).*?(# KANATA_SEQUENCES_END)',
                     f'\\1\n{seq_block}\n      \\2', content, flags=re.DOTALL)

    with open(NIX_FILE, 'w') as f:
        f.write(content)
    print("Successfully updated configuration.nix with AHK typos!")

if __name__ == "__main__":
    update_nix_config()



    services.kanata = {
    enable = true;
    keyboards.default = {
      # This wildcard works for almost all internal/USB keyboards
      devices = [ "/dev/input/by-path/*-kbd" ];
      config = ''
        (defsrc
          a b c d e f g h i j k l m n o p q r s t u v w x y z
          caps n m , . ; ' [ ] 1 2 3 4 5 6 7 8 9 0 - = bspc spc
        )

        (defalias
          # KANATA_ALIASES_START
          # KANATA_ALIASES_END
        )

        (defsequence
          # KANATA_SEQUENCES_START
          # KANATA_SEQUENCES_END
        )

        (deflayer default
          _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
          _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
        )
      '';
    };
  };



  To make this seamless, you can use a **systemd service** and a **path unit**. This combination acts like a "file watcher" on NixOS; the moment it detects a change in `autocorrect.ahk`, it will trigger the Python script, update your `configuration.nix`, and optionally run `nixos-rebuild`.

### 1. Create the Watcher (NixOS Config)

Add this to your `configuration.nix`. This tells NixOS to monitor the file and execute your script.

```nix
systemd.paths."ahk-watcher" = {
  wantedBy = [ "multi-user.target" ];
  pathConfig = {
    PathModified = "/home/youruser/path/to/autocorrect.ahk";
  };
};

systemd.services."ahk-watcher" = {
  serviceConfig = {
    Type = "oneshot";
    User = "root"; # Script needs root to write to /etc/nixos/
    ExecStart = "${pkgs.python3}/bin/python3 /home/youruser/path/to/update_kanata.py";
  };
};

```

---

### 2. Handling the "Blocking" logic in the script

Since you want the "Direct Typo" method to feel like it has `blockinput`, we should ensure the Python script generates Kanata macros that use `(m-release-all)`.

Modified the macro line in the Python script to include this:

```python
# Updated macro string with blocking logic
# (m-release-all) clears the hardware state so the OS ignores new physical presses
# during the backspace sequence.
alias = f"      {alias_name} (macro (m-release-all) {bs_str} {repl_str})"

```

---

### 3. Verification of the `by-path` Wildcard

Using `devices = [ "/dev/input/by-path/*-kbd" ];` is excellent, but Kanata will crash if it tries to grab a device that is already being used by another driver (like a specialized RGB controller).

If you get a "device busy" error after rebuilding, you can refine the wildcard to be more specific to your hardware:

* Run: `ls /dev/input/by-path/`
* Look for the specific name of your primary keyboard (e.g., `platform-i8042-serio-0-event-kbd`).
* Use that string instead of the wildcard if the wildcard is too "greedy."

### Summary of your new "Smart" workflow:

1. **Edit** `autocorrect.ahk` (just like you did on Windows).
2. **Save** the file.
3. **Systemd** sees the change and runs the Python script.
4. **Configuration.nix** is instantly updated with the new Lisp code.
5. **Rebuild:** Run `sudo nixos-rebuild switch` to apply the new keys.

**Would you like me to add a command to the Python script so it automatically runs the `nixos-rebuild switch` for you after it updates the file?**


This is the "pro-tier" workflow for Linux. To replicate your **Win+A** functionality, we need a script that can grab the current selection, prompt you for a fix, and then trigger the pipeline (AHK file  Python script  NixOS config  Kanata).

Since you are using **Wayland** (KDE or Hyprland), we will use `wl-copy`/`wl-paste` for the clipboard and `zenity` (a lightweight tool) for the InputBox.

### 1. The "Linux Win+A" Script (`add_typo.sh`)

This script does exactly what your AHK script did: it copies the typo, asks for the replacement, appends it to `autocorrect.ahk`, and triggers the Python update.

```bash
#!/usr/bin/env bash

# 1. Grab current selection
# We use xdotool to simulate Ctrl+C
old_clip=$(wl-paste)
xdotool key ctrl+c
sleep 0.2
typo=$(wl-paste)

# 2. Show InputBox (Zenity)
# Format: ::typo::correction
entry=$(zenity --entry --title="New Hotstring" --text="Format: ::typo::correction" --entry-text="::$typo::$typo")

if [ -n "$entry" ]; then
    # 3. Append to AHK file
    echo "$entry" >> "$HOME/path/to/autocorrect.ahk"

    # 4. Trigger the Python Script immediately
    # (The systemd watcher will also see it, but this makes it instant)
    python3 "$HOME/path/to/update_kanata.py"

    # 5. Optional: Replace the highlighted typo with the correction immediately
    # Extract the correction part from ::typo::correction
    correction=$(echo "$entry" | awk -F'::' '{print $3}')
    echo -n "$correction" | wl-copy
    xdotool key ctrl+v
fi

# Restore old clipboard
echo -n "$old_clip" | wl-copy

```

---

### 2. Update the Python Script

We need to make sure the Python script can handle `nixos-rebuild` so the changes actually take effect. Add this to the bottom of the `update_kanata.py` script I gave you earlier:

```python
import subprocess

# ... (existing code) ...

def rebuild_nixos():
    print("Applying changes to NixOS...")
    # This runs the rebuild in the background
    subprocess.run(["sudo", "nixos-rebuild", "switch"], check=True)

if __name__ == "__main__":
    update_nix_config()
    rebuild_nixos()

```

---

### 3. Bind the Shortcut

Now you just need to bind `Super + A` (or `Ctrl + Alt + A`) to run `add_typo.sh`.

* **In Hyprland:**
`bind = SUPER, A, exec, ~/path/to/add_typo.sh`
* **In KDE:**
Go to **System Settings > Shortcuts > Commands** and map the script path to your preferred key.

---

### 4. The Data Flow

1. **Selection:** You highlight `tset`.
2. **Hotkey:** You hit the shortcut.
3. **Input:** A box pops up pre-filled with `::tset::tset`. You change it to `::tset::test`.
4. **Persistence:** The script writes it to `autocorrect.ahk`.
5. **Rebuild:** The Python script updates your Nix config and reloads Kanata.
6. **Immediate Fix:** The script pastes `test` over your highlighted `tset` so you don't even have to backspace it.

### Required Dependencies

Make sure these are in your `environment.systemPackages` in `configuration.nix`:

* `pkgs.wl-clipboard` (For Wayland clipboard)
* `pkgs.zenity` (For the InputBox)
* `pkgs.xdotool` (To simulate the Ctrl+C/V keypresses)

**Would you like me to refine the Python script's regex so it handles those specific `#Hotstring B0` and `return` lines in your AHK file more gracefully?**



To make this work flawlessly on NixOS, we need to handle a specific hurdle: `nixos-rebuild` requires **root** (sudo) privileges, but your shortcut script runs as a **user**.

We will solve this by allowing your user to run the specific Python script with sudo without a password, just like AHK "reloads" itself in the background on Windows.

### 1. The Improved Python Script (`update_kanata.py`)

This version is "smart." It ignores the AHK logic blocks (`{`, `}`, `return`, `#Hotstring`) but captures the raw strings.

```python
import re
import subprocess
import os

AHK_FILE = os.path.expanduser("~/autocorrect.ahk")
NIX_FILE = "/etc/nixos/configuration.nix"

def ahk_to_kanata():
    aliases = []
    sequences = []

    if not os.path.exists(AHK_FILE): return

    with open(AHK_FILE, 'r') as f:
        for line in f:
            line = line.strip()
            # Handle AHK format :options:trigger::replacement
            match = re.match(r'^:([^:]*):([^:]+)::(.*)$', line)
            if match:
                opts, trig, repl = match.groups()
                repl = repl.split(';')[0].strip() or trig # Use trig if repl is empty (exclusion)

                # Sanitize for Lisp
                name = f"fix_{re.sub(r'[^a-zA-Z]', '_', trig)}"

                # Build Lisp strings
                key_map = {';': 'semi', ',': 'comma', "'": 'squote', '.': 'dot', ' ': 'spc'}
                t_lisp = " ".join([key_map.get(c, c) for c in trig])
                r_lisp = " ".join([key_map.get(c, c) for c in repl])
                bs_lisp = " ".join(["bspc"] * len(trig))

                aliases.append(f"      {name} (macro (m-release-all) {bs_lisp} {r_lisp})")
                sequences.append(f"      ({t_lisp}) @{name}")

    # Read, Replace, Write
    with open(NIX_FILE, 'r') as f:
        content = f.read()

    content = re.sub(r'(# KANATA_ALIASES_START).*?(# KANATA_ALIASES_END)',
                     f'\\1\n{"\n".join(aliases)}\n      \\2', content, flags=re.DOTALL)yazi
    content = re.sub(r'(# KANATA_SEQUENCES_START).*?(# KANATA_SEQUENCES_END)',
                     f'\\1\n{"\n".join(sequences)}\n      \\2', content, flags=re.DOTALL)

    with open(NIX_FILE, 'w') as f:
        f.write(content)

    # Rebuild Kanata
    subprocess.run(["nixos-rebuild", "switch"], check=True)

if __name__ == "__main__":
    ahk_to_kanata()

```

---

### 2. The NixOS "Sudo-less" Permissions

Add this to your `/etc/nixos/configuration.nix` so the script can update the system without asking for your password every time you add a typo:

```nix
security.sudo.extraRules = [{
  users = [ "yourusername" ];
  commands = [{
    command = "/run/current-system/sw/bin/python3 /home/yourusername/update_kanata.py";
    options = [ "NOPASSWD" ];
  }];
}];

```

---

### 3. The "Win+A" Linux Bash Script (`add_typo.sh`)

This script uses `zenity` to show the exact InputBox you had in AHK, moves the cursor, and appends the result.

```bash
#!/usr/bin/env bash

# Grab selection
old_clip=$(wl-paste)
xdotool key ctrl+c
sleep 0.1
typo=$(wl-paste)

# Show InputBox (The 'Direct Typo' AHK style)
entry=$(zenity --entry --title="New Hotstring" \
    --text="Edit the right side to provide the correction:" \
    --entry-text="::$typo::$typo")

if [ -n "$entry" ]; then
    # Append to file
    echo "$entry" >> "$HOME/autocorrect.ahk"

    # Run the Python updater with sudo (via the NOPASSWD rule we added)
    sudo python3 "$HOME/update_kanata.py"

    # Instant fix: Paste the correction over the highlighted typo
    correction=$(echo "$entry" | awk -F'::' '{print $3}')
    echo -n "$correction" | wl-copy
    xdotool key ctrl+v
fi

# Restore clipboard
echo -n "$old_clip" | wl-copy

```

---

### 4. Implementation Steps

1. **Dependencies:** Ensure `wl-clipboard`, `zenity`, `xdotool`, and `python3` are in your system packages.
2. **Markers:** Make sure `# KANATA_ALIASES_START` etc., are in your `configuration.nix` (inside the `services.kanata` block).
3. **Keyboard Wildcard:** Ensure you use `devices = [ "/dev/input/by-path/*-kbd" ];` so it works on any keyboard you plug in.
4. **Shortcut:** Bind `Super+A` to run `/home/yourusername/add_typo.sh`.

Now, when you hit `Super+A`, you get your AHK box, you type the fix, and Kanata is instantly reloaded with the new kernel-level "Direct Typo" logic.

**Would you like me to show you how to add a notification popup that tells you when the "Reload" is complete?**



Ah, good catch—you're right. `^#a` is **Ctrl + Super + A** (Control + Win + A), not just Win + A.

Adding a notification is a great idea because `nixos-rebuild` can take a few seconds, and you want to know exactly when your new typo correction is "live" and ready to use. We can use `libnotify` (`notify-send`) to handle this.

### 1. The Final "Win+A" Linux Script (`add_typo.sh`)

I've updated the shortcut and added the notification logic.

```bash
#!/usr/bin/env bash

# 1. Grab current selection
old_clip=$(wl-paste)
xdotool key ctrl+c
sleep 0.1
typo=$(wl-paste | tr -d '\n\r') # Clean up any trailing newlines

# 2. Show InputBox (The AHK style)
# Pre-filled with your highlighted word
entry=$(zenity --entry --title="New Hotstring" \
    --text="Correction for '$typo':" \
    --entry-text="::$typo::$typo")

if [ -n "$entry" ]; then
    # Start the "Updating" notification
    notify-send "Kanata" "Applying new typo correction..." -i input-keyboard

    # 3. Append to your AHK file
    echo "$entry" >> "$HOME/autocorrect.ahk"

    # 4. Run the Python updater (Requires the NOPASSWD sudo rule)
    if sudo python3 "$HOME/update_kanata.py"; then
        # 5. Instant fix: Replace the highlighted word on your screen
        correction=$(echo "$entry" | awk -F'::' '{print $3}')
        echo -n "$correction" | wl-copy
        xdotool key ctrl+v

        # Success notification
        notify-send "Kanata" "Reloaded! '$typo' -> '$correction' is now active." -i empathy-consistent
    else
        notify-send "Kanata" "Error: Failed to rebuild configuration." -u critical
    fi
fi

# Restore old clipboard
echo -n "$old_clip" | wl-copy

```

---

### 2. Update your Keybindings

Since you specifically use `Ctrl + Super + A`:

* **In Hyprland:**
```bash
bind = CTRL_SUPER, A, exec, ~/path/to/add_typo.sh

```


* **In KDE:**
Go to **Shortcuts > Commands**, and when it asks for the key, press **Ctrl + Meta + A**.

---

### 3. The Python Success Signal

Ensure your Python script actually exits with a success code so the Bash script knows when to show the "Success" notification.

```python
# Inside update_kanata.py
try:
    # ... existing file writing logic ...
    subprocess.run(["nixos-rebuild", "switch"], check=True)
    sys.exit(0)
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)

```

### One Final "Pro" Tip for NixOS

Since `nixos-rebuild` evaluates the *entire* system, it can be slow if you have a massive configuration. If you only want to reload Kanata without checking your whole system every time, you can change the rebuild command in the Python script to:

`subprocess.run(["systemctl", "restart", "kanata-internalKeyboard.service"], check=True)`

*Note: This only works if you've already added the typos to your `configuration.nix` once. For the very first time you add a new typo, you still need a full `nixos-rebuild` to make sure Nix knows about the new string.*

**Would you like me to help you verify the `systemd` service name for Kanata on your machine so the reloads become nearly instantaneous?**


Yes — instead of injecting CSS in a browser with `@-moz-document`, you can apply a **system-wide overlay in Hyprland** much more cleanly.

Since Hyprland is a Wayland compositor, the easiest approaches are:

---

## ✅ Option 1 — Use Hyprland's built-in blur/decoration (if you just want visual effect)

If your goal is aesthetic (like tinting or styling), you can modify:

```
~/.config/hypr/hyprland.conf
```

Example:

```ini
decoration {
    blur {
        enabled = true
        size = 8
        passes = 2
    }
}

layerrule = blur, waybar
```

But this won't let you overlay an image like your CSS does.

---

## ✅ Option 2 — Create a fullscreen Wayland layer overlay (Best replacement)

Your CSS is basically creating:

* A fullscreen fixed overlay
* Always on top
* Non-interactive
* With a PNG background

On Wayland, the proper way to do this is using a **layer-shell overlay**.

The easiest tool for this:

### 🔹 Use `gtk-layer-shell` via a small GTK app

or

### 🔹 Use `wlr-layer-shell` tools like `swaybg`

The simplest drop-in solution is:

---

## 🔥 Easiest Method: Use `swaybg` as a top layer overlay

Install:

```bash
sudo pacman -S swaybg
```

Run:

```bash
swaybg -i yourimage.png -m stretch
```

But that sets background — not overlay.

---

## ⭐ Cleanest Real Solution: `gtk-layer-shell` overlay window

Install:

```bash
sudo pacman -S gtk-layer-shell
```

Then create a tiny GTK Python script:

```python
import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk
import gtk_layer_shell

win = Gtk.Window()
win.set_decorated(False)
win.set_app_paintable(True)

gtk_layer_shell.init_for_window(win)
gtk_layer_shell.set_layer(win, gtk_layer_shell.Layer.TOP)
gtk_layer_shell.set_anchor(win, gtk_layer_shell.Edge.TOP, True)
gtk_layer_shell.set_anchor(win, gtk_layer_shell.Edge.BOTTOM, True)
gtk_layer_shell.set_anchor(win, gtk_layer_shell.Edge.LEFT, True)
gtk_layer_shell.set_anchor(win, gtk_layer_shell.Edge.RIGHT, True)

win.set_opacity(0.5)
win.show_all()
Gtk.main()
```

That gives you:

* Fullscreen overlay
* Always on top
* Adjustable opacity
* System-wide

You can add your base64 PNG as a background.

---

## 🧠 Even Simpler Hack (No coding)

Use Hyprland's window rules to float and pin an image viewer:

Example:

```ini
windowrulev2 = float, class:^(imv)$
windowrulev2 = fullscreen, class:^(imv)$
windowrulev2 = pin, class:^(imv)$
windowrulev2 = noblur, class:^(imv)$
```

Then run:

```bash
imv yourimage.png
```

Set transparency inside the image or compositor.

Very quick. No scripting needed.

---

# 🎯 Recommendation

If you want:

| Goal                       | Best Method              |
| -------------------------- | ------------------------ |
| Permanent system watermark | gtk-layer-shell overlay  |
| Quick test                 | Float + pin image viewer |
| Just aesthetic effect      | Hyprland blur/tint       |

---


"editor.quickSuggestions": {
  "other": true,
  "comments": false,
  "strings": true
}


hbyecoding.claude-dev
WilliamAsaba.dev-time-tracker
// ==UserScript==
// @name        jira no setTimeout
// @version     1
// @run-at      document-start
// @author      rssaromeo
// @match       https://itp251.atlassian.net/jira/software/projects/T1/boards/67*
// @exclude     *://challenges.cloudflare.com/*
// @grant       unsafeWindow
// @license     GPLv3
// @icon        data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEgAAABICAMAAABiM0N1AAAAAXNSR0IB2cksfwAAAAlwSFlzAAAOxAAADsQBlSsOGwAAAHJQTFRFAAAAEIijAo2yAI60BYyuF4WaFIifAY6zBI2wB4usGIaZEYigIoiZCIyrE4igG4iYD4mjEomhFoedCoqpDIqnDomlBYyvE4efEYmiDYqlA42xBoytD4mkCYqqGYSUFYidC4qoC4upAo6yCoupDYqmCYur4zowOQAAACZ0Uk5TAO////9vr////1+/D/+/L+/Pf/////+f3///////H4////////+5G91rAAACgUlEQVR4nM2Y22KjIBCGidg1264liZqDadK03X3/V2wNKHMC7MpF/xthHD5mgERAqZhWhfYqH6K+Qf2qNNf625hCoFj9/gblMUi5q5jLkXLCKudgyiRm0FMK82cWJp1fLbV5VmvJbCIc0GCYaFqqlDJgADdBjncqAXYobm1xh72aFMflbysteFfdy2Yi1XGOm5HGBzQ1dq7TzEoxjeNTjQZb7VA3e1c7+ImgasAgQ9+xusNVNZIo5xmOMgihIS2PbCQIiHEUdTvhxCcS/kPomfFI2zHy2PkWmA6aNatIJpKFJyekyy02xh5Y3DI9T4aOT6VhIUrsNTFp1pf79Z4SIIVDegl6IJO6cHiL/GimIZDhgTu/BlYWCQzHMl0zBWT/T3KAhtxOuUB9FtBrpsz0RV4xsjHmW+UCaffcSy/5viMGer0/6HdFNMZBq/vjJL38H9Dqx4Fuy0Em12DbZy+9pGtiDijbglwAehyj11n0tRD3WUBm+lwulE/8h4BuA+iWAQQnteg2Xm63WQLTpnMnpjdge0Mgu/GRPsV4xdjQ94Lfi624fabhDkfUqIKNrM64Q837v8yL0prasepCgrtvw1sJpoqanGEX7b5mQboNW8eawXaWXTMfMGxub472hzWzHSn6Sg2G9+6TAyRruE71s+zAzjWaknoyJCQzwxrghH2k5FDT4eqWunuNxyN9QCGcxVod5oADbYnIUkDTGZEf1xDJnSFteQ3KdsT8zYDMQXcHxsevcLH1TrsABzkNPyA/L7b0jg704viMMlpQI96WsHknCt/3YH0kOEo9zcGkwrFK39ck72rmoehmKqo2RKlilzSy/nJKEV45CT38myJp456fezktHjN5aeMAAAAASUVORK5CYII=
// @description 2/23/2026, 12:24:20 PM
// ==/UserScript==

const st = unsafeWindow.setTimeout
var int = setInterval(()=>{
  unsafeWindow.setTimeout=(c,t)=>st(c,0)
},100)
setTimeout(()=>{
  clearInterval(int)
},5000)
[data-testid="platform-board-kit.ui.column.draggable-column.styled-wrapper"]:not(:has([data-testid="platform-card.ui.card.focus-container"])),
[data-testid="platform-board-kit.ui.swimlane.swimlane-wrapper"] *,
[data-testid="software-board.board-container.board.virtual-board.fast-virtual-list.fast-virtual-list-wrapper"] {
    /*     display: none; */
    background-color: #a000;
}
[data-testid="platform-board-kit.ui.column.draggable-column.styled-wrapper"]:last-of-type {
    display: none;
}
[data-testid="platform-board-kit.ui.column.draggable-column.styled-wrapper"] {
    flex-grow: unset;
}

[data-testid="software-board.board-container.board.virtual-board.fast-virtual-list.fast-virtual-list-wrapper"]:not(:has([data-testid="platform-card.ui.card.focus-container"])) {
    visibility: hidden;
}
[data-testid="platform-board-kit.ui.swimlane.swimlane-wrapper"]>div>div{
    pointer-events:none;
}

// ==UserScript==
// @name         Universal Shader (Instant Mutation Detection)
// @namespace    http://tampermonkey.net/
// @version      1.6
// @description  MutationObserver for instant detection + Safe CORS Fallback
// @author       Gemini
// @match        *://*/*
// @grant        GM_xmlhttpRequest
// @connect      *
// ==/UserScript==

;(function () {
  "use strict"

  const VERTEX_SHADER = `
      attribute vec2 position;
      varying vec2 vUv;
      void main() {
          vUv = position * 0.5 + 0.5;
          gl_Position = vec4(position, 0.0, 1.0);
      }
  `

  const FRAGMENT_SHADER = `
      precision highp float;
      uniform sampler2D u_texture;
      varying vec2 vUv;
      uniform float u_time;

      float rerange(float val, float low1, float high1, float low2, float high2){
          return ((val - low1) / (high1 - low1)) * (high2 - low2) + low2;
      }

      float mapToDarkeningFactor(float x) {
          return rerange(x, 0.5, 1.0, 0.8, 0.15);
      }

      void main() {
          vec3 color = texture2D(u_texture, vUv).rgb;
          float avg = (color.r + color.g + color.b) / 3.0;
          gl_FragColor = vec4(color * mapToDarkeningFactor(avg), 1.0);
      }
  `

  function fetchSafeSource(el) {
    if (el.dataset.corsFixed || el.tagName !== "IMG") return
    el.dataset.corsFixed = "true"

    GM_xmlhttpRequest({
      method: "GET",
      url: el.src,
      responseType: "blob",
      onload: function (response) {
        const blobUrl = URL.createObjectURL(response.response)
        const img = new Image()
        img.onload = () => {
          el._safeImage = img
        }
        img.src = blobUrl
      },
    })
  }

  function setupShader(el) {
    if (el.dataset.shaderActive || el.classList.contains("shader-overlay")) return
    el.dataset.shaderActive = "true"

    const canvas = document.createElement("canvas")
    canvas.classList.add("shader-overlay")
    Object.assign(canvas.style, {
      position: "absolute",
      pointerEvents: "none",
      zIndex: "9999",
      backgroundColor: "#000",
    })
    document.body.appendChild(canvas)

    const gl = canvas.getContext("webgl")
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true)

    const compile = (type, src) => {
      const s = gl.createShader(type)
      gl.shaderSource(s, src)
      gl.compileShader(s)
      return s
    }

    const program = gl.createProgram()
    gl.attachShader(program, compile(gl.VERTEX_SHADER, VERTEX_SHADER))
    gl.attachShader(program, compile(gl.FRAGMENT_SHADER, FRAGMENT_SHADER))
    gl.linkProgram(program)
    gl.useProgram(program)

    const buffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, -1, 1, 1, -1, 1, 1]), gl.STATIC_DRAW)

    const pos = gl.getAttribLocation(program, "position")
    gl.enableVertexAttribArray(pos)
    gl.vertexAttribPointer(pos, 2, gl.FLOAT, false, 0, 0)

    const texture = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, texture)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)

    function render(time) {
      if (!el.isConnected) {
        canvas.remove()
        return
      }

      const rect = el.getBoundingClientRect()
      canvas.style.top = rect.top + window.scrollY + "px"
      canvas.style.left = rect.left + window.scrollX + "px"
      canvas.style.width = rect.width + "px"
      canvas.style.height = rect.height + "px"

      let drawSource = el._safeImage || el
      let isReady = false

      if (el.tagName === "VIDEO") isReady = el.readyState >= 2
      else if (el.tagName === "IMG") isReady = drawSource.complete && drawSource.naturalWidth !== 0
      else if (el.tagName === "CANVAS") isReady = true

      if (isReady) {
        try {
          canvas.width = el.tagName === "VIDEO" ? el.videoWidth : (el.naturalWidth || el.width)
          canvas.height = el.tagName === "VIDEO" ? el.videoHeight : (el.naturalHeight || el.height)
          gl.viewport(0, 0, canvas.width, canvas.height)

          gl.bindTexture(gl.TEXTURE_2D, texture)
          gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, drawSource)

          gl.uniform1f(gl.getUniformLocation(program, "u_time"), time * 0.001)
          gl.drawArrays(gl.TRIANGLES, 0, 6)
          canvas.style.backgroundColor = "#0000"
        } catch (e) {
          if (e.name === "SecurityError") {
            canvas.style.backgroundColor = "#000"
            fetchSafeSource(el)
          }
        }
      }
      requestAnimationFrame(render)
    }
    render(0)
  }

  // --- MUTATION OBSERVER LOGIC ---
  const observer = new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      for (const node of mutation.addedNodes) {
        if (node.nodeType !== 1) continue // Skip text nodes

        // Check if the added node itself is a target
        if (["VIDEO", "IMG", "CANVAS"].includes(node.tagName)) {
            setupShader(node)
        }
        // Check if the added node contains any targets (Subtree)
        else {
            node.querySelectorAll?.("video, img, canvas").forEach(setupShader)
        }
      }
    }
  })

  // Start observing the whole document
  observer.observe(document.body, {
    childList: true,
    subtree: true
  })

  // Run once for elements already on the page when script loads
  document.querySelectorAll("video, img, canvas").forEach(setupShader)

})()



// ==UserScript==
// @name        lib:textjack
// @version     8
// @match       *://*/*
// @run-at      document-start
// @author      rssaromeo
// @license     GPLv3
// @grant       none
// ==/UserScript==

let isProcessing = false
const textJackList = []
const observedRoots = new WeakSet()

// 1. Efficient Text Processing
function processTextNode(node) {
  const originalText = node.textContent
  let newText = originalText

  // Run through all callbacks in a single pass to avoid recursion loops
  for (const cb of textJackList) {
    newText = cb(newText)
  }

  if (newText !== originalText) {
    isProcessing = true // Prevent the observer from reacting to our own change
    node.textContent = newText
    isProcessing = false
  }
}

// 2. High-speed DOM Traversal
function scan(root) {
  // TreeWalker is significantly faster than manual recursive childNodes loops
  const walker = document.createTreeWalker(
    root,
    NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT,
    null,
    false,
  )
  let currentNode

  while ((currentNode = walker.nextNode())) {
    if (currentNode.nodeType === Node.TEXT_NODE) {
      processTextNode(currentNode)
    } else if (
      currentNode.shadowRoot &&
      !observedRoots.has(currentNode.shadowRoot)
    ) {
      // Automatically catch Shadow DOMs during the scan
      observe(currentNode.shadowRoot)
      scan(currentNode.shadowRoot)
    }
  }
}

// 3. Optimized Mutation Handler
function handleMutations(mutations) {
  if (isProcessing) return

  for (const mutation of mutations) {
    if (mutation.type === "childList") {
      mutation.addedNodes.forEach((node) => {
        if (node.nodeType === Node.TEXT_NODE) {
          processTextNode(node)
        } else if (node.nodeType === Node.ELEMENT_NODE) {
          scan(node)
        }
      })
    } else if (mutation.type === "characterData") {
      processTextNode(mutation.target)
    }
  }
}

// 4. Centralized Observer logic
function observe(target) {
  if (observedRoots.has(target)) return

  const observer = new MutationObserver(handleMutations)
  observer.observe(target, {
    childList: true,
    subtree: true,
    characterData: true,
  })
  observedRoots.add(target)
}

// --- Library Integration ---

const a = loadlib("allfuncs")

loadlib("libloader").savelib("textjack", function newTextJack(cb) {
  textJackList.push(cb)

  // Initial run if body exists
  if (document.body) {
    setup()
  }
})

function setup() {
  if (observedRoots.has(document.documentElement)) return

  // Start observing from the root HTML element to catch head/body changes
  observe(document.documentElement)
  scan(document.documentElement)
}

// Safety check for early-loading
if (document.body) {
  setup()
} else {
  a.bodyload().then(setup)
}



// ==UserScript==
// @name         no * anywhere (Optimized)
// @version      15
// @match        *://*/*
// @grant        none
// ==/UserScript==

(function() {
    const rawWords = `fuck,shitshow,fucks,shitposts,pornstar,sucked,bisexual,cumdump,vagina,crap,shitload,shithole,stupidness,fuckery,retardation,horshit,smut,bitching,stupids,bumfucks,bumblefuck,fuckin,fucktard,licked,crotch,hitler,crotchless,incestuous,batshit,penis,masturbate,Goddamn,damn,enslave,slavery,socked,enslavement,murderess,molest,molestation,dicks,cockblock,scrape,perverts,cock,stupidest,boobs,stupidity,slavery,sadist,stupid,trashest,fag,bitchybitchy,erotic,cockroach,tits,murdering,bitchy,trashing,trashiest,bullshitting,cocky,cockiness,murderous,Hancock,trashy,trashcan,horny,suicide,retard,clicked,incestual,basement,rapes,thorny,virgin,murderers,murderer,murder,virgins,assholes,rapest,whore,slut,bitchest,raped,morons,amusement,cocks,incest,fingerfuck,molested,murders,trash,cockroaches,monsterfucker,intersex,Futanari,trashhero,fucked,motherfucker,bitches,bastard,fucking,hell,nasty,scum,pissed,bastards,raping,bitch,shit,fucker,scumbag,shitless,ass,badass,virginity,slave,pervert,futanari,sex,futa,Impregnating,Impregnated,trashes,murderfest,Impregnate,rapey,retards,fuckk,Cunnilingus,slaves,sexual,edgefuckfests,anal,stupider,assed,Intercourse,Fallatio,Handjob,Masturbation,Masturbating,Orgy,Prostitutes,rape,enslaved,perverted,stupidly,prostitution,sexually,bullshits,shits,porn,dick,shitty,dicking,bullshit,sexuality,retardedness,Futadomworld,asshole,pussy,sexy,murdered,cocktail,trAshed,virginal,retarded,hentai,dogshit,fricking,frick,fricker,niri,rust,webtoon`.split(',');

    // 1. Compile simple word list into ONE regex
    // This replaces all standard words in a single pass.
    const masterRegex = new RegExp(`\\b(${rawWords.join('|')})\\b`, 'gi');

    // 2. Specialized replacements (Complex logic)
    const specialReplacements = [
        [/(?<=^|[^\d\w])\*(\w+( \w+)*)\*(?=[^\w\d]|$)/gi, "$1"],
        [/what( ?ever)? the duck/gi, "what$1 the fuck"],
        [/duck(ed)? up/gi, "fuck$1 up"],
        [/R4P3/gi, "rape"],
        [/fked/gi, "fucked"],
        [/borked/gi, "fucked"],
        [/f\*ing/gi, "fucking"],
        [/b\*\*\*/gi, "bitch"],
        [/F\**CK/gi, "fuck"],
        [/(?<!\w)NSFW(?!\w)/gi, "porn"],
        // Add more manual overrides here...
    ];

    // 3. The Symbol Decoder
    // Instead of a regex for every word, we use one regex that finds
    // words containing symbols and cleans them.
    const symbolRegex = /[a-z0-9]*[%#*♥][a-z0-9%#*♥]*/gi;

    function replaceText(text) {
        if (!text || text.length < 2) return text;

        // Pass 1: Master word list
        text = text.replace(masterRegex, (matched) => matched.toLowerCase());

        // Pass 2: Special hardcoded overrides
        for (const [reg, rep] of specialReplacements) {
            text = text.replace(reg, rep);
        }

        // Pass 3: Clean symbol-censored words (e.g., f*ck -> fuck)
        // This is much faster than your original map() logic
        text = text.replace(symbolRegex, (matched) => {
            let clean = matched.replace(/[%#*♥]/g, '');
            // Optional: check if 'clean' is in our dictionary before replacing
            return clean;
        });

        return text;
    }

    // --- Title Logic ---
    function updateTitle() {
        const oldTitle = document.title;
        const newTitle = replaceText(oldTitle.replace(/(^| )\[URL\] .*/gi, ""));
        if (oldTitle !== newTitle) {
            document.title = newTitle;
        }
    }

    // Integrate with your textjack library
    if (typeof loadlib === "function") {
        loadlib("textjack")(replaceText);
    }

    // Title Observer
    const titleObserver = new MutationObserver(updateTitle);
    const titleElem = document.querySelector("title") || document.head.appendChild(document.createElement("title"));
    titleObserver.observe(titleElem, { childList: true });

})();


// ==UserScript==
// @name         no * anywhere (Ultra Optimized)
// @version      16
// @match        *://*/*
// @grant        none
// ==/UserScript==

(function() {
    // 1. The Cache - Stores { "f*ck": "fuck" }
    const textCache = new Map();
    const MAX_CACHE_SIZE = 1000; // Prevents memory leaks on infinite-scroll sites

    const rawWords = `fuck,shitshow,fucks,shitposts,pornstar,sucked,bisexual,cumdump,vagina,crap,shitload,shithole,stupidness,fuckery,retardation,horshit,smut,bitching,stupids,bumfucks,bumblefuck,fuckin,fucktard,licked,crotch,hitler,crotchless,incestuous,batshit,penis,masturbate,Goddamn,damn,enslave,slavery,socked,enslavement,murderess,molest,molestation,dicks,cockblock,scrape,perverts,cock,stupidest,boobs,stupidity,slavery,sadist,stupid,trashest,fag,bitchybitchy,erotic,cockroach,tits,murdering,bitchy,trashing,trashiest,bullshitting,cocky,cockiness,murderous,Hancock,trashy,trashcan,horny,suicide,retard,clicked,incestual,basement,rapes,thorny,virgin,murderers,murderer,murder,virgins,assholes,rapest,whore,slut,bitchest,raped,morons,amusement,cocks,incest,fingerfuck,molested,murders,trash,cockroaches,monsterfucker,intersex,Futanari,trashhero,fucked,motherfucker,bitches,bastard,fucking,hell,nasty,scum,pissed,bastards,raping,bitch,shit,fucker,scumbag,shitless,ass,badass,virginity,slave,pervert,futanari,sex,futa,Impregnating,Impregnated,trashes,murderfest,Impregnate,rapey,retards,fuckk,Cunnilingus,slaves,sexual,edgefuckfests,anal,stupider,assed,Intercourse,Fallatio,Handjob,Masturbation,Masturbating,Orgy,Prostitutes,rape,enslaved,perverted,stupidly,prostitution,sexually,bullshits,shits,porn,dick,shitty,dicking,bullshit,sexuality,retardedness,Futadomworld,asshole,pussy,sexy,murdered,cocktail,trAshed,virginal,retarded,hentai,dogshit,fricking,frick,fricker,niri,rust,webtoon`.split(',');

    const masterRegex = new RegExp(`\\b(${rawWords.join('|')})\\b`, 'gi');
    const symbolRegex = /[a-z0-9]*[%#*♥][a-z0-9%#*♥]*/gi;

    const specialReplacements = [
        [/(?<=^|[^\d\w])\*(\w+( \w+)*)\*(?=[^\w\d]|$)/gi, "$1"],
        [/what( ?ever)? the duck/gi, "what$1 the fuck"],
        [/duck(ed)? up/gi, "fuck$1 up"],
        [/R4P3/gi, "rape"],
        [/fked/gi, "fucked"],
        [/borked/gi, "fucked"],
        [/f\*ing/gi, "fucking"],
        [/b\*\*\*/gi, "bitch"],
        [/F\**CK/gi, "fuck"],
        [/(?<!\w)NSFW(?!\w)/gi, "porn"]
    ];

    function replaceText(text) {
        if (!text || text.length < 2) return text;

        // CHECK CACHE: If we've seen this exact string before, return the result immediately
        if (textCache.has(text)) {
            return textCache.get(text);
        }

        let processedText = text;

        // Pass 1: Master word list
        processedText = processedText.replace(masterRegex, (matched) => matched.toLowerCase());

        // Pass 2: Special hardcoded overrides
        for (const [reg, rep] of specialReplacements) {
            processedText = processedText.replace(reg, rep);
        }

        // Pass 3: Symbol strip
        processedText = processedText.replace(symbolRegex, (matched) => matched.replace(/[%#*♥]/g, ''));

        // SAVE TO CACHE:
        if (textCache.size > MAX_CACHE_SIZE) {
            const firstKey = textCache.keys().next().value;
            textCache.delete(firstKey); // Remove oldest entry to keep memory low
        }
        textCache.set(text, processedText);

        return processedText;
    }

    // --- Title Observer (Kept separate because titles are unique) ---
    function updateTitle() {
        const oldTitle = document.title;
        const newTitle = replaceText(oldTitle.replace(/(^| )\[URL\] .*/gi, ""));
        if (oldTitle !== newTitle) {
            document.title = newTitle;
        }
    }

    // Library Integration
    if (typeof loadlib === "function") {
        loadlib("textjack")(replaceText);
    }

    const titleObserver = new MutationObserver(updateTitle);
    const titleElem = document.querySelector("title") || document.head.appendChild(document.createElement("title"));
    titleObserver.observe(titleElem, { childList: true, characterData: true });
})();
Is there a specific site that still feels slow, or should we look into making the regex even more aggressive for specific "leetspeak" (like phuck or sh!t)?


xcursorgen


        function createProcessor(canvas, width, height) {
          const gl = canvas.getContext("webgl", {
            premultipliedAlpha: false,
          })

          canvas.width = width
          canvas.height = height
          gl.viewport(0, 0, width, height)

          function compile(type, source) {
            const shader = gl.createShader(type)
            gl.shaderSource(shader, source)
            gl.compileShader(shader)
            return shader
          }

          const program = gl.createProgram()
          gl.attachShader(
            program,
            compile(gl.VERTEX_SHADER, VERTEX_SHADER),
          )
          gl.attachShader(
            program,
            compile(gl.FRAGMENT_SHADER, FRAGMENT_SHADER),
          )
          gl.linkProgram(program)
          gl.useProgram(program)

          // Fullscreen quad
          const buffer = gl.createBuffer()
          gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
          gl.bufferData(
            gl.ARRAY_BUFFER,
            new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]),
            gl.STATIC_DRAW,
          )

          const position = gl.getAttribLocation(program, "position")
          gl.enableVertexAttribArray(position)
          gl.vertexAttribPointer(position, 2, gl.FLOAT, false, 0, 0)

          // Create texture ONCE
          const texture = gl.createTexture()
          gl.bindTexture(gl.TEXTURE_2D, texture)
          gl.texParameteri(
            gl.TEXTURE_2D,
            gl.TEXTURE_WRAP_S,
            gl.CLAMP_TO_EDGE,
          )
          gl.texParameteri(
            gl.TEXTURE_2D,
            gl.TEXTURE_WRAP_T,
            gl.CLAMP_TO_EDGE,
          )
          gl.texParameteri(
            gl.TEXTURE_2D,
            gl.TEXTURE_MIN_FILTER,
            gl.LINEAR,
          )
          gl.texParameteri(
            gl.TEXTURE_2D,
            gl.TEXTURE_MAG_FILTER,
            gl.LINEAR,
          )

          // Allocate texture memory once (null data)
          gl.texImage2D(
            gl.TEXTURE_2D,
            0,
            gl.RGBA,
            width,
            height,
            0,
            gl.RGBA,
            gl.UNSIGNED_BYTE,
            null,
          )

          const uTexture = gl.getUniformLocation(program, "u_texture")
          gl.uniform1i(uTexture, 0)

          async function process(bitmap) {
            gl.bindTexture(gl.TEXTURE_2D, texture)

            // 🔥 Fast path: replace pixels only
            gl.texSubImage2D(
              gl.TEXTURE_2D,
              0,
              0,
              0,
              gl.RGBA,
              gl.UNSIGNED_BYTE,
              bitmap,
            )

            gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4)

            return new Promise((resolve) =>
              canvas.toBlob(resolve, "image/jpeg", 0.95),
            )
          }

          return { process }
        }
        async function processAll(blobs) {
          // Decode in parallel (CPU side)
          const bitmaps = await Promise.all(
            blobs.map((b) =>
              createImageBitmap(b, { imageOrientation: "flipY" }),
            ),
          )

          const width = bitmaps[0].width
          const height = bitmaps[0].height

          const processor = createProcessor(canvas, width, height)

          const results = []

          for (const bitmap of bitmaps) {
            const output = await processor.process(bitmap)
            results.push(output)
          }

          return results
        }

        return (await processAll([res.response])).map(
          URL.createObjectURL,
        )




// ==UserScript==
// @name         WebGL Video Shader Filter
// @namespace    shader.filter
// @version      1.0
// @match        *://*.youtube.com/*
// @match        *://*.twitch.tv/*
// @grant        none
// ==/UserScript==

(function () {
  'use strict';

  function waitForVideo() {
    return new Promise(resolve => {
      const check = () => {
        const v = document.querySelector("video");
        if (v && v.readyState >= 2) resolve(v);
        else requestAnimationFrame(check);
      };
      check();
    });
  }

  waitForVideo().then(video => {
    const canvas = document.createElement("canvas");
    canvas.style.position = "fixed";
    canvas.style.top = "0";
    canvas.style.left = "0";
    canvas.style.width = "100%";
    canvas.style.height = "100%";
    canvas.style.pointerEvents = "none";
    canvas.style.zIndex = "999999";

    document.body.appendChild(canvas);

    const gl = canvas.getContext("webgl", {
      premultipliedAlpha: false
    });

    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true);

    const VERTEX_SHADER = `
      attribute vec2 position;
      varying vec2 vUv;
      void main() {
          vUv = position * 0.5 + 0.5;
          gl_Position = vec4(position, 0.0, 1.0);
      }
    `;

    const FRAGMENT_SHADER = `
      precision highp float;
      uniform sampler2D u_texture;
      varying vec2 vUv;

      float rerange(float val, float low1, float high1, float low2, float high2){
          return ((val - low1) / (high1 - low1)) * (high2 - low2) + low2;
      }

      float mapToDarkeningFactor(float x) {
          return rerange(x, 0.5, 1.0, 0.8, 0.15);
      }

      void main() {
          vec3 color = texture2D(u_texture, vUv).rgb;
          float avg = (color.r + color.g + color.b) / 3.0;
          gl_FragColor = vec4(color * mapToDarkeningFactor(avg), 1.0);
      }
    `;

    function compile(type, source) {
      const shader = gl.createShader(type);
      gl.shaderSource(shader, source);
      gl.compileShader(shader);
      return shader;
    }

    const program = gl.createProgram();
    gl.attachShader(program, compile(gl.VERTEX_SHADER, VERTEX_SHADER));
    gl.attachShader(program, compile(gl.FRAGMENT_SHADER, FRAGMENT_SHADER));
    gl.linkProgram(program);
    gl.useProgram(program);

    const buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    gl.bufferData(
      gl.ARRAY_BUFFER,
      new Float32Array([
        -1, -1,
         1, -1,
        -1,  1,
         1,  1,
      ]),
      gl.STATIC_DRAW
    );

    const position = gl.getAttribLocation(program, "position");
    gl.enableVertexAttribArray(position);
    gl.vertexAttribPointer(position, 2, gl.FLOAT, false, 0, 0);

    const texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    const uTexture = gl.getUniformLocation(program, "u_texture");
    gl.uniform1i(uTexture, 0);

    function render() {
      if (video.videoWidth === 0) {
        requestAnimationFrame(render);
        return;
      }

      if (canvas.width !== video.videoWidth ||
          canvas.height !== video.videoHeight) {
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
        gl.viewport(0, 0, canvas.width, canvas.height);
      }

      gl.bindTexture(gl.TEXTURE_2D, texture);
      gl.texImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGBA,
        gl.RGBA,
        gl.UNSIGNED_BYTE,
        video
      );

      gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

      requestAnimationFrame(render);
    }

    render();
  });

})();



Alright — if you want to **parse KeePassXC’s auto-type sequence yourself** and implement `{DELAY}`, `{TAB}`, `{ENTER}`, `{TOTP}`, etc. in a Wayland script using `wtype`, here’s how to do it cleanly.

We’ll let:

* **KeePassXC** store the sequence
* Your script fetch it via CLI
* Your script parse and execute it token by token

---

# 🔧 Step 1 — Get the sequence from KeePassXC

You can extract the auto-type sequence like this:

```bash
keepassxc-cli show -a autotype /path/to/db.kdbx "Entry Name"
```

If you need window matching:

```bash
win=$(hyprctl activewindow -j | jq -r '.title')
entry=$(keepassxc-cli locate /path/to/db.kdbx "$win" | head -n1)
sequence=$(keepassxc-cli show -a autotype /path/to/db.kdbx "$entry")
```

Now `$sequence` contains something like:

```
{USERNAME}{TAB}{PASSWORD}{ENTER}{DELAY 2000}{TOTP}{ENTER}
```

---

# 🔧 Step 2 — Replace field placeholders first

Fetch the fields:

```bash
username=$(keepassxc-cli show -a username /path/to/db.kdbx "$entry")
password=$(keepassxc-cli show -a password /path/to/db.kdbx "$entry")
totp=$(keepassxc-cli show -a totp /path/to/db.kdbx "$entry" 2>/dev/null)
```

Then substitute:

```bash
sequence=${sequence//\{USERNAME\}/$username}
sequence=${sequence//\{PASSWORD\}/$password}
sequence=${sequence//\{TOTP\}/$totp}
```

Now you're left with:

```
actualuser{TAB}actualpass{ENTER}{DELAY 2000}123456{ENTER}
```

---

# 🔧 Step 3 — Token Parser

Here’s a minimal but working Bash parser:

```bash
#!/usr/bin/env bash

parse_and_type() {
    local input="$1"

    while [[ -n "$input" ]]; do
        if [[ "$input" =~ ^\{DELAY[[:space:]]+([0-9]+)\} ]]; then
            ms="${BASH_REMATCH[1]}"
            sleep "$(bc <<< "scale=3; $ms/1000")"
            input="${input#\{DELAY $ms\}}"

        elif [[ "$input" =~ ^\{TAB\} ]]; then
            wtype -k Tab
            input="${input#\{TAB\}}"

        elif [[ "$input" =~ ^\{ENTER\} ]]; then
            wtype -k Return
            input="${input#\{ENTER\}}"

        elif [[ "$input" =~ ^\{SPACE\} ]]; then
            wtype " "
            input="${input#\{SPACE\}}"

        elif [[ "$input" =~ ^\{ ]]; then
            # Unknown token — strip safely
            input="${input#\{}"
            input="${input#*\}}"

        else
            # Normal character
            char="${input:0:1}"
            wtype "$char"
            input="${input:1}"
        fi
    done
}

parse_and_type "$sequence"
```

---

# 🧠 What This Supports

✔ `{USERNAME}`
✔ `{PASSWORD}`
✔ `{TOTP}`
✔ `{TAB}`
✔ `{ENTER}`
✔ `{DELAY 2000}`
✔ Raw text

---

# ⚠️ Important Notes

### 1️⃣ Use `wtype -k` for special keys

Examples:

```
wtype -k Tab
wtype -k Return
wtype -k Escape
```

### 2️⃣ Don’t use `wtype "$fullstring"`

You must send character-by-character if you want delay handling.

### 3️⃣ `{DELAY=0}`

KeePass has both:

```
{DELAY 2000}
{DELAY=0}
```

Add support like:

```bash
elif [[ "$input" =~ ^\{DELAY=([0-9]+)\} ]]; then
    ms="${BASH_REMATCH[1]}"
    sleep "$(bc <<< "scale=3; $ms/1000")"
    input="${input#\{DELAY=$ms\}}"
```

---

# 🚀 Result

Now your script:

1. Gets matching entry
2. Reads KeePassXC’s defined auto-type sequence
3. Expands credentials
4. Interprets tokens
5. Sends proper delayed keystrokes via `wtype`

Fully Wayland-native.
No X11.
Delays work.
OTP-after-reload works.

---

If you want, I can next give you:

* A fully polished Nix/Home-Manager module version
* Or a faster parser written in awk instead of bash loops (cleaner + less fragile)
* Or window-class matching instead of title matching (more reliable in Hyprland)


Short answer: **not directly like that** in Hyprland.

Hyprland keybinds (`bind = ...`) do not support inline scripting with variables like:

```
bind ^!a={
  uname,passwd,kpotp,seq=...
}
```

Hyprland can only:

* run commands (`exec`)
* dispatch built-in actions
* pass static arguments

So you’ll need to move that logic into a **separate script**, then call it from a bind.

---

# ✅ Proper Way: Use a Script + `wtype` + KeePassXC CLI

Since you're on **Hyprland (Wayland)**, using `wtype` is correct.

The right way is:

### 1️⃣ Create a script

Example: `~/.local/bin/kpxc-autotype`

```bash
#!/usr/bin/env bash

# Get active window title (Hyprland JSON)
winTitle=$(hyprctl activewindow -j | jq -r '.title')

# Query KeePassXC CLI for matching entry
# (adjust search logic to your DB setup)
entry=$(keepassxc-cli locate /path/to/db.kdbx "$winTitle" | head -n1)

# Extract fields
username=$(keepassxc-cli show -a username /path/to/db.kdbx "$entry")
password=$(keepassxc-cli show -a password /path/to/db.kdbx "$entry")
otp=$(keepassxc-cli show -a totp /path/to/db.kdbx "$entry" 2>/dev/null)

# Type it
wtype "$username"
wtype $'\t'
wtype "$password"

# Optional OTP
if [ -n "$otp" ]; then
  wtype $'\t'
  wtype "$otp"
fi

wtype $'\n'
```

Make executable:

```bash
chmod +x ~/.local/bin/kpxc-autotype
```

---

### 2️⃣ Hyprland bind

In `hyprland.conf`:

```
bind = CTRL+ALT, A, exec, ~/.local/bin/kpxc-autotype
```

---

# ⚠️ Important Things

### 🔐 1. KeePassXC CLI needs DB access

You’ll either:

* Enter password each time
* Use `--key-file`
* Or use `--pw-stdin` with a gpg-agent setup
* Or unlock DB in GUI and use `--no-password` (less secure)

### 🧠 2. `jq` required

Install it in Nix:

```nix
environment.systemPackages = with pkgs; [
  jq
  wtype
  keepassxc
];
```

---

# 🚀 Better Option (Much Simpler)

Instead of manually scripting:

In **KeePassXC GUI → Settings → Auto-Type**

* Set custom auto-type command to:

```
wtype {USERNAME}{TAB}{PASSWORD}{ENTER}
```

That works in Hyprland without needing CLI at all.

KeePassXC will replace `{USERNAME}` etc before calling `wtype`.

This is cleaner and avoids handling your DB password manually.

---

# ❗ Why Your Inline Idea Won’t Work

Hyprland:

* ❌ does not support variable assignments
* ❌ does not support inline Lua/bash blocks
* ❌ cannot substitute custom variables like `{username}`
* ❌ cannot evaluate expressions

It only launches external commands.

---

# 🏆 Cleanest Way Overall (Recommended)

For Hyprland:

**KeePassXC → set auto-type command to:**

```
wtype {USERNAME}{TAB}{PASSWORD}{ENTER}
```

No scripts.
No CLI.
No DB password handling.
No jq.
Fully Wayland-native.

---

If you'd like, tell me:

* Are you using GUI KeePassXC unlocked?
* Do you want window-title matching?
* Do you want OTP included?
* Are you using Home-Manager?

I can give you a minimal Nix-native setup tailored to your config.


Here’s a **practical way to *send the current HTML5 `video.currentTime` from Brave to your shell*** and format it into a human‑friendly time — *even if Brave’s MPRIS doesn’t report rate*.

---

## 🛠️ Step‑by‑Step: Get Video Time from Brave to Shell

### 1) **Launch Brave with a debugging port**

You need to start Brave with the **remote debugging port enabled** so you can query it from your shell:

```bashbrave --remote-debugging-port=9222 &
```

This opens Brave so external tools can talk to it using the **Chrome DevTools Protocol (CDP)**. ([Brave Help Center][1])

> If you already have Brave running, you’ll need to restart it with that flag.

---

### 2) **Find the tab’s debugging session**

Get the list of open debugging targets (tabs):

```bash
curl -s http://localhost:9222/json
```

This returns a JSON array of tabs; look for the one with your video page and copy its `"id"` (e.g., `"sessionId":"XYZ..."`).
Call it something like:

```
SESSION_ID="your-session-id-here"
```

---

### 3) **Query the video currentTime via CDP**

Once you have the session ID, use this curl request to *evaluate JavaScript* inside that tab:

```bash
curl -s -X POST \
  -H "Content-Type: application/json" \
  --data "{\"expression\":\"document.querySelector('video').currentTime\"}" \
  http://localhost:9222/json/session/$SESSION_ID/Runtime.evaluate
```

This will return JSON containing the actual video playback time in seconds as a number — *accurate at 2× playback*.

---

### 4) **Format the result into HH:MM:SS**

You can wrap it in a shell helper like this:

```bash
SESSION_ID="your-session-id"
raw=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    --data "{\"expression\":\"document.querySelector('video').currentTime\"}" \
    http://localhost:9222/json/session/$SESSION_ID/Runtime.evaluate)

# Extract the numeric value (e.g. result.value)
seconds=$(echo "$raw" | jq -r '.result.value')

# Turn it into HH:MM:SS
printf "%02d:%02d:%02d\n" $(($seconds/3600)) $(($seconds%3600/60)) $(($seconds%60))
```

---

## 🚀 Result

Running that command prints the *correct video position* even when playback speed isn’t 1× — something `playerctl` can’t report from Brave’s MPRIS due to missing rate info. ([Lightrun][2])

---

## ⚠️ Notes

* Remote debugging must be enabled when starting Brave.
* This works for *any HTML5 video* on the page that you can reach with `document.querySelector('video')`.
* If the page has multiple `<video>`s, you may need a more specific selector.

---

If you want, I can help turn this into a **watch script** that continually prints the current video time (like `top`/`watch`) so you can *monitor it live as it plays*.

[1]: https://support.brave.com/hc/en-us/articles/360044860011-How-Do-I-Use-Command-Line-Flags-in-Brave?utm_source=chatgpt.com "How Do I Use Command Line Flags in Brave? - Brave Help Center"
[2]: https://lightrun.com/answers/brave-brave-browser-remote-debugging-should-be-proxied-and-enabled-by-default?utm_source=chatgpt.com "Remote debugging should be proxied and enabled by default"


only allow connections frof first connected ip pwashare
decoration {
    screen_shader = /path/to/your_shader.frag
}
https://github.com/loqusion/hyprshade


// ==UserScript==
// @name        no nano
// @version     1
// @run-at      document-start
// @author      rssaromeo
// @match       https://gemini.google.com/*
// @match       https://claude.ai/*
// @exclude     *://challenges.cloudflare.com/*
// @grant       none
// @license     GPLv3
// @icon        data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEgAAABICAMAAABiM0N1AAAAAXNSR0IB2cksfwAAAAlwSFlzAAAOxAAADsQBlSsOGwAAAHJQTFRFAAAAEIijAo2yAI60BYyuF4WaFIifAY6zBI2wB4usGIaZEYigIoiZCIyrE4igG4iYD4mjEomhFoedCoqpDIqnDomlBYyvE4efEYmiDYqlA42xBoytD4mkCYqqGYSUFYidC4qoC4upAo6yCoupDYqmCYur4zowOQAAACZ0Uk5TAO////9vr////1+/D/+/L+/Pf/////+f3///////H4////////+5G91rAAACgUlEQVR4nM2Y22KjIBCGidg1264liZqDadK03X3/V2wNKHMC7MpF/xthHD5mgERAqZhWhfYqH6K+Qf2qNNf625hCoFj9/gblMUi5q5jLkXLCKudgyiRm0FMK82cWJp1fLbV5VmvJbCIc0GCYaFqqlDJgADdBjncqAXYobm1xh72aFMflbysteFfdy2Yi1XGOm5HGBzQ1dq7TzEoxjeNTjQZb7VA3e1c7+ImgasAgQ9+xusNVNZIo5xmOMgihIS2PbCQIiHEUdTvhxCcS/kPomfFI2zHy2PkWmA6aNatIJpKFJyekyy02xh5Y3DI9T4aOT6VhIUrsNTFp1pf79Z4SIIVDegl6IJO6cHiL/GimIZDhgTu/BlYWCQzHMl0zBWT/T3KAhtxOuUB9FtBrpsz0RV4xsjHmW+UCaffcSy/5viMGer0/6HdFNMZBq/vjJL38H9Dqx4Fuy0Em12DbZy+9pGtiDijbglwAehyj11n0tRD3WUBm+lwulE/8h4BuA+iWAQQnteg2Xm63WQLTpnMnpjdge0Mgu/GRPsV4xdjQ94Lfi624fabhDkfUqIKNrM64Q837v8yL0prasepCgrtvw1sJpoqanGEX7b5mQboNW8eawXaWXTMfMGxub472hzWzHSn6Sg2G9+6TAyRruE71s+zAzjWaknoyJCQzwxrghH2k5FDT4eqWunuNxyN9QCGcxVod5oADbYnIUkDTGZEf1xDJnSFteQ3KdsT8zYDMQXcHxsevcLH1TrsABzkNPyA/L7b0jg704viMMlpQI96WsHknCt/3YH0kOEo9zcGkwrFK39ck72rmoehmKqo2RKlilzSy/nJKEV45CT38myJp456fezktHjN5aeMAAAAASUVORK5CYII=
// @description 3/20/2026, 9:52:06 AM
// ==/UserScript==

loadlib("textjack")((e)=>e.replace(/(?<!\w)(?:nano|vim?)(?!\w)/g, "nvim").replace(/(?<!\w)(?:notepad|code)(?!\w)/g, "codium"))


// ==UserScript==
// @name         Universal Code Fixer (+ Hyprland)
// @match        *://*/*
// @require      https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js
// @require      https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-bash.min.js
// @require      https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-nix.min.js
// @require      https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-gdscript.min.js
// @require      https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-toml.min.js
// @resource     PRISM_CSS https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-dark.min.css
// @grant        GM_addStyle
// @grant        GM_getResourceText
// ==/UserScript==

(function() {
    'use strict';

    GM_addStyle(GM_getResourceText("PRISM_CSS")+`
    .token.variable { color: #c678dd !important; } /* Purple variables */
.token.keyword { color: #e06c75 !important; }  /* Reddish keywords */`);

    // 1. Define Hyprland Syntax manually since it's a niche language
// 1. Refined Hyprland Syntax
Prism.languages.hyprlang = {
    'comment': /#.*/,
    // Variables like $mainMod
    'variable': /\$[a-zA-Z0-9_]+/,
    // Keywords only at the start of the line or after a semicolon
    'keyword': {
        pattern: /(^|;|^\s*)\b(?:exec-once|exec|bind[a-z]*|monitor|workspace|windowrule[s]?|bezier|animation|input|gestures|general|decoration|animations|dwindle|master|misc|plugin|device)\b/m,
        lookbehind: true
    },
    // The "next", "prev", "insert" arguments
    'symbol': /\b(?:next|prev|insert|upstream|downstream)\b/,
    'punctuation': /[=,]/,
    'string': {
        pattern: /"(?:\\.|[^\\"])*"|'(?:\\.|[^\\'])*'/,
        greedy: true
    }
};

    function highlightEverything() {
        const blocks = document.querySelectorAll('code[data-test-id="code-content"], .code-container');

        blocks.forEach(block => {
            if (block.dataset.prismFixed === "true") return;

            const rawCode = block.innerText;
            let lang = 'bash';

            // Logic to detect Hyprland
            if (rawCode.includes('exec-once') || rawCode.includes('monitor=') || rawCode.includes('bind =')) {
                lang = 'hyprlang';
            } else if (rawCode.includes('pkgs.') || rawCode.includes('let')||/(?<!)with [\-\w]+;/.test(rawCode)) {
                lang = 'nix';
            } else if (rawCode.includes('func ') || rawCode.includes('extends ')) {
                lang = 'gdscript';
            }

            if (Prism.languages[lang]) {
                block.innerHTML = Prism.highlight(rawCode, Prism.languages[lang], lang);
                block.className = `language-${lang} fixed-code`;
                block.dataset.prismFixed = "true";
            }
        });
    }

    setInterval(highlightEverything, 1500);
})();



#!/usr/bin/env python3
import time
import math
from pynput import mouse

# Configuration
SCROLL_FACTOR = 0.02  # Base speed multiplier

scrolling = False
start_pos = (0, 0)

def on_click(x, y, button, pressed):
    global scrolling, start_pos
    if button == mouse.Button.middle:
        if pressed:
            scrolling = True
            start_pos = (x, y)
        else:
            scrolling = False

def on_move(x, y):
    if not scrolling:
        return
    dx = x - start_pos[0]
    dy = y - start_pos[1]

    # distance from start
    distance = math.hypot(dx, dy)
    # Scroll speed proportional to distance
    scroll_x = int(dx * SCROLL_FACTOR)
    scroll_y = int(dy * SCROLL_FACTOR)

    # Generate scroll events
    # Negative y is up, positive is down
    mouse_controller.scroll(-scroll_y, -scroll_x)

mouse_controller = mouse.Controller()

with mouse.Listener(on_click=on_click, on_move=on_move) as listener:
    listener.join()
To find duplicate files in a folder and replace them with symlinks, you typically combine a **duplicate finder** with a **script that links duplicates to one “original” file**.

Here’s a clean, practical way to do it on Linux/macOS:

---

## 🧰 Step 1: Install a duplicate finder

The most common tool is **`fdupes`**.

* On Ubuntu/Debian:

  ```bash
  sudo apt install fdupes
  ```
* On macOS (with Homebrew):

  ```bash
  brew install fdupes
  ```

---

## 🔍 Step 2: Find duplicates

Run:

```bash
fdupes -r /path/to/folder
```

This outputs groups of duplicate files.

---

## 🔗 Step 3: Replace duplicates with symlinks

⚠️ Be careful: this modifies files. Test on a copy first.

Here’s a simple script:

```bash
fdupes -r /path/to/folder | while read file; do
  if [ -z "$file" ]; then
    unset original
    continue
  fi

  if [ -z "$original" ]; then
    original="$file"
  else
    rm "$file"
    ln -s "$original" "$file"
  fi
done
```

---

## 🧠 How it works

* `fdupes` prints duplicates in groups (separated by blank lines)
* First file = **original**
* Others = deleted and replaced with **symlinks to original**

---

## ✅ Safer alternative (interactive)

You can review before linking:

```bash
fdupes -r /path/to/folder
```

Then manually:

```bash
ln -s original duplicate
```

---

## ⚡ Better tool (more control)

Try **`rdfind`**, which can automatically replace duplicates:

```bash
rdfind -makesymlinks true /path/to/folder
```

---

## 🚨 Important notes

* Symlinks break if the original file is moved/deleted
* Hard links (`ln` without `-s`) are often safer if same filesystem:

  ```bash
  rdfind -makehardlinks true /path/to/folder
  ```
* Always back up before bulk operations

---

If you want, I can give you:

* a **version that keeps newest/oldest file**
* or a **dry-run preview script** so nothing is deleted first





let lastTarget = null
let lastPos = { x: 0, y: 0 }

const HOVER_DELAY = 0
const MOVE_THRESHOLD = 4 // px (ignore tiny jitters)

onmousemove = (e) => {
  const dx = Math.abs(e.clientX - lastPos.x)
  const dy = Math.abs(e.clientY - lastPos.y)

  // Ignore tiny mouse jitter
  if (dx < MOVE_THRESHOLD && dy < MOVE_THRESHOLD) return

  lastPos = { x: e.clientX, y: e.clientY }

  const el = document.elementFromPoint(e.clientX, e.clientY)
  if (!el) return

  const target = resolveTarget(el)
  if (!target || target === lastTarget) return

  lastTarget = target
  applyFocus(target)
}

function resolveTarget(el) {
  // 1. Direct real inputs (search box etc)
  if (el.matches('textarea, input, [contenteditable="true"]')) {
    return el
  }

  // 2. Terminal
  const terminal = el.closest(".terminal")
  if (terminal) {
    return terminal.querySelector(".xterm-helper-textarea")
  }

  // 3. Editor (Monaco)
  const editor = el.closest(".monaco-editor")
  if (editor) {
    return editor.querySelector(".native-edit-context")
  }

  // 4. Search / input panels
  const inputBox = el.closest(".inputbox, .search-view")
  if (inputBox) {
    return inputBox.querySelector("textarea, input")
  }

  // 5. Generic fallback
  return el.closest('[role="textbox"], [contenteditable="true"]')
}

function applyFocus(target) {
  if (!target) return

  // Avoid unnecessary focus calls
  if (document.activeElement === target) return

  requestAnimationFrame(() => {
    target.focus()
  })
}



nix flake update --option access-tokens "github.com=$(gh auth token)"
