{
  pkgs,
  userConfig,
  inputs,
  ...
}:
{
  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
      extraPkgs = pkgs: [
        pkgs.python312
        pkgs.python314
      ];
    };
  };
  programs = {
    hyprland = {
      enable = true;
    };
    firefox = {
      enable = true;
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  users.users."${userConfig.uname}" = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "${userConfig.uname}";
    extraGroups = [
      "networkmanager"
      "wheel"
      "opensnitch"
      "input"
      "audio"
    ];
    packages = with pkgs; [
      inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default # widget thing
      wtype
      # typos
      typos-lsp # spellchecker
      # keepass # password manager
      python313
      python313Packages.py7zr
      godot # programing
      # appimage-run
      # firejail
      motrix # download manager
      # nix-tree
      kid3 # audio tagger
      yt-dlp # media downloader
      # syncthingtray
      syncthing # file sync
      mp3gain # audio volume normilizer
      python314
      filen-desktop # cloud storage
      javaPackages.compiler.temurin-bin.jre-25 # for running java apps
      file # like die
      # opensnitch-ui # firewall
      vscodium # text editor
      # wineWowPackages.unstableFull # windows apps
      # autokey # x11 only
      unixtools.watch # watch cmd
      htop # process info
      # htop-vim
      # mission-center # task manager
      vlc # media player
      nicotine-plus # soulseek
      conky # like rainmeter
      wl-clipboard # clipboard cli tool
      # wl-clipboard-rs # what is the difference?
      wl-clicker # autoclicker
      # see if can change to scrolllock/z
      magic-wormhole # file transfer
      jq # json parser
      nil # nix language server
      # testing
      cascadia-code # font
      texlivePackages.cascadiamono-otf
      gpu-screen-recorder # screen recorder
      lutris-free
      faugus-launcher
      # thunar # wiztree
      # bottles
      # https://github.com/anyrun-org/anyrun
      # ulauncher
      qt6.qtdeclarative
      zenity
      libnotify
      simplex-chat-desktop # simple x chat
      copyq # clipboard manager
      # openshot-qt # vid editor
      # pay-respects
      imagemagick
      shfmt # shell formatter
      cfm # tui file manager
      keepassxc # password manager
      grim
      slurp
      tesseract5 # ocr
      thunar # gui file manager
      yazi # tui file manager
      hyprshot
      gnome-themes-extra
      adwaita-icon-theme
      python313Packages.black
      audacity
      (callPackage ./progress-daemon/progress-daemon.nix { })
      (callPackage ./winspy/winspy.nix { })
      goldberg-emu
      deno
      zuban
      libreoffice
      (
        let
          version = "8.0.29";
        in
        pkgs.stdenv.mkDerivation {
          pname = "xdm";
          inherit version;

          src = pkgs.fetchurl {
            url = "https://github.com/subhra74/xdm/releases/download/${version}/xdman_gtk-8.0.29-1-x86_64.pkg.tar.zst";
            sha256 = "sha256-ffFONhkbc41FhI1Wes+aifAmv1KQME/lA3pSoeTEKuw=";
          };

          # We need these to extract .zst and fix the binaries

          sourceRoot = ".";

          nativeBuildInputs = [
            pkgs.zstd
            pkgs.autoPatchelfHook
            pkgs.makeWrapper
          ];

          buildInputs = with pkgs; [
            gtk3
            nss
            nspr
            libX11
            libXrender
            libXtst
            alsa-lib
            at-spi2-atk
            lttng-ust
            libkrb5
            icu
            openssl
            cairo
            dbus
            expat
            fontconfig
            gdk-pixbuf
            glib
            pango
            libdrm
            mesa
          ];
          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin

            # Copy the opt folder (where xdm-app lives)
            if [ -d "opt" ]; then
              cp -r opt $out/
            fi

            # Copy the usr folder (for icons/desktop files)
            if [ -d "usr" ]; then
              cp -r usr/* $out/
            fi

            # The actual binary is xdm-app, not xdman
            chmod +x $out/opt/xdman/xdm-app

            # Link it so you can run 'xdman' or 'xdm-app' from the terminal
            ln -sf $out/opt/xdman/xdm-app $out/bin/xdman
            ln -sf $out/opt/xdman/xdm-app $out/bin/xdm-app

            runHook postInstall
          '';
        }
      )
    ];
  };
  programs.gpu-screen-recorder.enable = true;
  environment.systemPackages = with pkgs; [
    neovim # tui text editor
    wget # cmd dl util
    brave # web browser
    nixfmt # nix language formatter
    git # git is required
    # kdePackages.kget
    p7zip # archival tool
    nix-ld # run linux programs
    kitty # terminal emulator
    # rofi
    # albert
    keyd # disables capslock and enables numlock
    anyrun # application launcher

    nix-output-monitor # nix update formatter
    cascadia-code # font
    swaynotificationcenter # notification daemon

    # waybar
    nerd-fonts.jetbrains-mono # Matches your JetBrainsMono NFP
    font-awesome # For additional icons
    wlogout # For the power menu click
    pavucontrol # For audio control
    ly # tui login manager
    sops # secrets manager
    direnv
    copyparty
    home-manager
    pulseaudio
    pipewire
    wireplumber
    hyprlock # lockscreen
    killall
  ];
  services.pipewire = {
    # Enable PipeWire
    enable = true;
    wireplumber.enable = true;

    # PulseAudio compatibility (so applications using PulseAudio work)
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
  };

  # Disable PulseAudio itself (optional, safer on NixOS)
  services.pulseaudio.enable = false;
}
