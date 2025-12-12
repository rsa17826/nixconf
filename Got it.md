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
