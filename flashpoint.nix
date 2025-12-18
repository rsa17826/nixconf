{
  pkgs ? import <nixpkgs> { },
}:

(pkgs.buildFHSEnv {
  name = "flashpoint";
  targetPkgs =
    pkgs:
    (with pkgs; [
      # Shell utils
      toybox
      # Electron for the launcher.
      electron
      # Flashpoint requirements
      pipewire
      pulseaudio
      gtk3
      gtk2
      nss
      php
      wine
      xorg.libX11
      xorg.libXt
      xorg.libXcomposite
      # ldd requirements
      mesa # libgbm
      glib
      nspr
      at-spi2-atk
      cups
      dbus
      libdrm
      pango
      cairo
      expat
      libxkbcommon
      alsa-lib
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      xorg.libxcb
      udev
    ]);
}).env