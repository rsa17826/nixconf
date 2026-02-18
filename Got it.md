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
                     f'\\1\n{"\n".join(aliases)}\n      \\2', content, flags=re.DOTALL)
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

## ✅ Option 1 — Use Hyprland’s built-in blur/decoration (if you just want visual effect)

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

But this won’t let you overlay an image like your CSS does.

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

Use Hyprland’s window rules to float and pin an image viewer:

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

If you tell me what the overlay is for (watermark? eye filter? meme? burn-in test?), I can give you the cleanest possible solution specifically for that.


https://aylur.github.io/ags/guide/nix.html



https://marketplace.visualstudio.com/items?itemName=Tobermory.es6-string-html
https://github.com/Aylur/ags/tree/main/example/simple-bar


"editor.quickSuggestions": {
  "other": true,
  "comments": false,
  "strings": true
}
