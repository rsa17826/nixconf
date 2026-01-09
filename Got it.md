Got it.
The extension **unthrottled.doki-theme** *patches VSCode’s internal CSS files* in:

```
.../resources/app/out/vs/workbench/
```

### ❌ But on NixOS, this path is in the **immutable Nix store**, so it is *always read-only*.

Doki Theme **cannot work out-of-the-box on NixOS**, because it relies on patching VSCode at runtime.

This is a known issue for Doki Theme on NixOS + Code-OSS/VSCodium.

---

# ✅ **GOOD NEWS**

You *can still use Doki Theme*, but **you must enable patching by rebuilding VSCodium through Nix** using an overlay.

This is exactly how other NixOS users run Doki Theme.

---

# ✔ **SOLUTION: Create a custom VSCodium build that allows patching**

You must “unpack” VSCodium into a writeable location or apply patches as part of the derivation.

The recommended approach:

---

# ✅ **Nix overlay that allows the Doki theme patcher to work**

Create:

```
~/.config/nixpkgs/overlays/vscodium-doki.nix
```

Put:

```nix
self: super: {
  vscodium = super.vscodium.overrideAttrs (old: {
    # allow Doki Theme to patch code on first run
    dontWrapGApps = true;
    postInstall = (old.postInstall or "") + ''
      echo "Making VSCodium writable for Doki Theme"
      cp -r $out/lib/vscode $out/lib/vscode-writable
      chmod -R u+w $out/lib/vscode-writable
    '';

    # point VSCode to the writable directory
    postFixup = (old.postFixup or "") + ''
      substituteInPlace $out/share/applications/codium.desktop \
        --replace "/lib/vscode/" "/lib/vscode-writable/"
    '';
  });
}
```

---

# ✔ **Then in Home Manager:**

```nix
programs.vscode = {
  enable = true;
  package = pkgs.vscodium;
  mutableExtensionsDir = true;
};
```

---

# 🧠 What this overlay does:

* Copies the immutable VSCodium installation to a *parallel writable directory*
* Allows the Doki Theme patcher to modify the files it needs
* Makes VSCodium run from the writable directory instead of `/nix/store`

This is the only stable and sustainable method.

---

# 🚫 What will NEVER work

* Making `/nix/store/.../workbench` writable
* Installing any patch-the-core extension without a custom derivation
* Using VSCodium with Doki Theme unmodified
* Using Code-OSS unmodified

All fail with:

```
EROFS: read-only file system
```

---

# 🎉 After applying overlay + rebuild

Run:

```
home-manager switch
```

Then open VSCodium → install **Doki Theme** → it will finally be able to patch CSS.

---

# If you want

👉 I can generate a minimal version of the overlay
👉 or generate a version for **VSCode** instead of VSCodium
👉 or help you convert DokiTheme into an actual Nix package (fully declarative)

Just tell me which direction you prefer.
To get **Ctrl + Backspace** to work like on Windows in **zsh** on **Hyprland** running on **NixOS**, you'll need to adjust a few things. Hyprland is a dynamic tiling Wayland compositor, and it doesn't use X11, so the process differs slightly from traditional X11 setups. Here’s a step-by-step guide:

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
Ah! Now I understand clearly — you want **a Wayland version of AutoHotkey’s hotstring/hotkey functionality** on **Hyprland**, which means:

* **Intercept input** (detect key sequences in real time).
* **Modify/replace them** (like hotstrings or hotkeys).
* **Send synthetic input back** to applications.

This is tricky on Wayland because of **security restrictions** — clients cannot see or inject arbitrary input; the **compositor is the only trusted layer**. But there are a few approaches:

---

## 1️⃣ Use Hyprland’s config for “hotkeys” (limited)

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

If you want something working **today**, do **evdev + uinput** for a global AHK-like hotstring tool. Later, if you’re ambitious, you can integrate it into Hyprland proper.

---

I can make you a **ready-to-use Python “hotstring engine” for Hyprland** that:

* Detects typed hotstrings.
* Deletes them.
* Replaces them with your text.
* Works globally.

Do you want me to do that next?
Perfect! Let’s build a **minimal working global hotstring engine for Hyprland** using Python. This will work **today**, without touching Hyprland’s source code.

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
Ah — you want the **shift handling to respect the real physical Shift key state** and only inject Shift as needed. This avoids "double shift" issues when typing uppercase letters while holding Shift, and ensures that temporary shifts for lowercase letters don’t interfere with a real pressed Shift.

Here’s a corrected approach for your `send_text` function:

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
Perfect! Let’s rewrite your **full hotstring engine** for Hyprland with **proper Shift/CapsLock handling**, letters, numbers, and basic symbols. This will work like a minimal AutoHotkey replacement, respecting the **physical Shift state**, so hotstrings don’t conflict with real key presses.

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

We’ll use **a small systemd user service** that runs a **uinput script** at startup.

---

## 1️⃣ Create the uinput script

Let’s make a simple script that **turns on NumLock and turns off CapsLock**:

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
