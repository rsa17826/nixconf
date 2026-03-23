{ lib, stdenv, fetchurl, makeWrapper, autoPatchelfHook, 
  webkitgtk_4_1, libayatana-appindicator, gtk3, glib-networking }:

stdenv.mkDerivation rec {
  pname = "portmaster";
  version = "1.6.4"; # Update this to the latest stable version

  # Portmaster has multiple binaries; usually, you'd fetch the 'core' and 'ui'
  src = fetchurl {
    url = "https://updates.safing.io/latest/linux_amd64/core/portmaster-core_v${version}";
    sha256 = "0000000000000000000000000000000000000000000000000000"; # Replace with actual hash
  };

  # For a full conversion, you'd also fetch the UI binary and the Icon
  icon = fetchurl {
    url = "https://raw.githubusercontent.com/safing/portmaster-packaging/master/linux/portmaster_logo.png";
    sha256 = "sha256-7LAmJZUllK+G07U3YjY8HiJ8K5YE/JyUI2gvyHqSqVc="; 
  };

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];
  buildInputs = [ webkitgtk_4_1 libayatana-appindicator gtk3 glib-networking ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin $out/share/applications $out/share/pixmaps

    # Install Core
    cp $src $out/bin/portmaster-core
    chmod +x $out/bin/portmaster-core

    # Install Icon
    cp $icon $out/share/pixmaps/portmaster.png

    # Create Desktop Item
    cat <<EOF > $out/share/applications/portmaster.desktop
    [Desktop Entry]
    Name=Portmaster
    GenericName=Application Firewall
    Exec=$out/bin/portmaster-ui --with-prompts --with-notifications
    Icon=portmaster
    Terminal=false
    Type=Application
    Categories=System;Security;
    EOF
  '';

  postFixup = ''
    # Wrap UI with necessary env variables (from your script)
    wrapProgram $out/bin/portmaster-ui \
      --set WEBKIT_DISABLE_COMPOSITING_MODE 1 \
      --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules"
  '';
}