{
  pkgs,
  userConfig,
  inputs,
  pkgFromInp,
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
      package = pkgFromInp "hyprland" "hyprland";
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
      gamescope
      (pkgFromInp "quickshell" "default") # widget thing
      wtype
      cliphist
      steam
      # typos
      typos-lsp # spellchecker
      # keepass # password manager
      python313
      python313Packages.py7zr
      godot # programing
      # appimage-run
      # firejail
      # motrix # download manager
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
      wineWow64Packages.unstableFull # windows apps
      winetricks
      unixtools.watch # watch cmd
      htop # process info
      # htop-vim
      # mission-center # task manager
      vlc # media player
      nicotine-plus # soulseek
      conky # like rainmeter
      wl-clipboard # clipboard cli tool
      dxvk
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
      # (pkgs.writeShellScriptBin "godot47" ''exec ${
      #   (pkgs.stdenv.mkDerivation rec {
      #     version = "4.7-dev2";
      #     pname = "godot-${version}";
      #     src = pkgs.fetchurl {
      #       url = "https://github.com/godotengine/godot-builds/releases/download/${version}/Godot_v${version}_linux.x86_64.zip";
      #       sha256 = "00g3iidkcr068ayy6r77zpmpnl4c66q1gcqid0klc1hbxmdw5psp";
      #     };
      #     nativeBuildInputs = with pkgs; [ unzip ];
      #     sourceRoot = ".";
      #     installPhase = "mkdir -p $out/bin; chmod +x Godot_v${version}_linux.x86_64; cp Godot_v* $out/bin/godot";
      #   })
      # }/bin/godot "$@"'')
      (
        let
          godot-4-7-dev2 = pkgs.stdenv.mkDerivation rec {

            version = "4.7-dev2";
            pname = "godot-${version}";
            src = pkgs.fetchurl {
              url = "https://github.com/godotengine/godot-builds/releases/download/${version}/Godot_v${version}_linux.x86_64.zip";
              sha256 = "00g3iidkcr068ayy6r77zpmpnl4c66q1gcqid0klc1hbxmdw5psp";
            };
            nativeBuildInputs = with pkgs; [ unzip ];
            sourceRoot = ".";
            installPhase = ''
              mkdir -p $out/bin
              chmod +x Godot_v${version}_linux.x86_64
              cp Godot_v${version}_linux.x86_64 $out/bin/godot-${version}
            '';
          };
        in
        godot-4-7-dev2
      )

      # (
      #   let
      #     version = "7.2.11";
      #   in
      #   pkgs.stdenv.mkDerivation {
      #     pname = "xdm";
      #     inherit version;

      #     src = pkgs.fetchurl {
      #       url = "https://github.com/subhra74/xdm/releases/download/${version}/xdman.jar";
      #       sha256 = "sha256-FAQTZReX2XsTxfGi8MUo2m5G02Ur02q9dDsaadxhBDg=";
      #       # url = "https://github.com/subhra74/xdm/releases/download/${version}/xdman_gtk-8.0.29-1-x86_64.pkg.tar.zst";
      #       # sha256 = "sha256-ffFONhkbc41FhI1Wes+aifAmv1KQME/lA3pSoeTEKuw=";
      #     };

      #     # We need these to extract .zst and fix the binaries

      #     sourceRoot = ".";
      #     autoPatchelfIgnoreMissingDeps = [ "liblttng-ust.so.0" ];
      #     nativeBuildInputs = [
      #       pkgs.zstd
      #       pkgs.autoPatchelfHook
      #       pkgs.makeWrapper
      #     ];

      #     buildInputs = with pkgs; [
      #       gtk3
      #       nss
      #       nspr
      #       libX11
      #       libXrender
      #       libXtst
      #       alsa-lib
      #       at-spi2-atk
      #       lttng-ust
      #       libkrb5
      #       icu
      #       openssl
      #       cairo
      #       dbus
      #       expat
      #       fontconfig
      #       gdk-pixbuf
      #       glib
      #       pango
      #       libdrm
      #       mesa
      #     ];
      #     installPhase = ''
      #       runHook preInstall

      #       mkdir -p $out/bin

      #       # Copy the opt folder (where xdm-app lives)
      #       if [ -d "opt" ]; then
      #         cp -r opt $out/
      #       fi

      #       # Copy the usr folder (for icons/desktop files)
      #       if [ -d "usr" ]; then
      #         cp -r usr/* $out/
      #       fi

      #       # The actual binary is xdm-app, not xdman
      #       chmod +x $out/opt/xdman/xdm-app

      #       # Link it so you can run 'xdman' or 'xdm-app' from the terminal
      #       ln -sf $out/opt/xdman/xdm-app $out/bin/xdman
      #       ln -sf $out/opt/xdman/xdm-app $out/bin/xdm-app

      #       runHook postInstall
      #     '';
      #     postFixup = ''
      #       wrapProgram $out/opt/xdman/xdm-app \
      #         --set GDK_PIXBUF_MODULE_FILE "${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache" \
      #         --prefix LD_LIBRARY_PATH : ${
      #           pkgs.lib.makeLibraryPath (
      #             with pkgs;
      #             [
      #               gtk3
      #               glib
      #               cairo
      #               pango
      #               gdk-pixbuf
      #               atk
      #               at-spi2-atk
      #               librsvg
      #               libX11
      #               libXcomposite
      #               libXcursor
      #               libXdamage
      #               libXext
      #               libXfixes
      #               libXi
      #               libXrender
      #               libXtst
      #               libxkbcommon
      #               mesa
      #               # The fix for the libssl error:
      #               openssl
      #               zlib
      #               libkrb5
      #             ]
      #           )
      #         }
      #     '';
      #   }
      # )
      (
        let
          # Define the version and fetch the jar
          xdm-jar = fetchurl {
            url = "https://github.com/joselmm/xdm-2023/raw/main/xdman.jar";
            sha256 = "00wr708s1inkvb5gxmnwfqgsppa5x2shfjhvvv3y2fz8f7djmmym"; # See note below
          };
        in
        writeShellScriptBin "xdm" ''
          ${pkgs.jdk}/bin/java -jar ${xdm-jar} "$@"
        ''
      )
      jdk # Ensure a JDK/JRE is also in your system path
      xemu # xbox emu
      wl-clip-persist # keep clip past app death
    ];
  };
  programs.gpu-screen-recorder.enable = true;
  environment.systemPackages =
    (
      let
        # 1. Fetch the binary AND make it executable
        portmaster-bin = pkgs.stdenv.mkDerivation {
          name = "portmaster-binary";
          src = pkgs.fetchurl {
            url = "https://updates.safing.io/latest/linux_amd64/start/portmaster-start";
            sha256 = "0n1g4qvb8aqsbb294kzwb9c91dlgs5irish4z4jqssmdkxbqqxy6"; # Use the hash from nix-prefetch-url
          };
          phases = [ "installPhase" ];
          installPhase = ''
            mkdir -p $out/bin
            cp $src $out/bin/portmaster-start
            chmod +x $out/bin/portmaster-start
          '';
        };

        # 2. Put that executable binary inside the FHS environment
        portmaster-pkg = pkgs.buildFHSEnv {
          name = "portmaster-start";
          targetPkgs =
            pkgs: with pkgs; [
              wget
              curl
              glibc
              zlib
              nss
              nspr
              atk
              at-spi2-atk
              libX11
              libxcb
              libXcomposite
              libXdamage
              libXext
              libXfixes
              libXrandr
              mesa
              expat
              iptables
              iproute2
            ];
          runScript = pkgs.writeScript "portmaster-wrapper" ''
            export PORTMASTER_DATA="$HOME/.local/share/portmaster"
            mkdir -p "$PORTMASTER_DATA"
            exec ${portmaster-bin}/bin/portmaster-start "$@"
          '';
        };
      in
      [
        # portmaster-bin
        # portmaster-pkg
      ]
    )
    ++ (with pkgs; [
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
      losslesscut-bin
      eza # ls
      swappy # image editor
    ]);
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.hack
  ];

  # This is crucial for the system to "see" them
  fonts.fontconfig.enable = true;
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
