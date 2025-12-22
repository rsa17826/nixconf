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
