{
  pkgs,
  userConfig,
  inputs,
  pkgFromInp,
  ...
}:
let
  newestGodot =
    version:
    pkgs.stdenv.mkDerivation {
      inherit version;
      pname = "godot-${version}";
      src = pkgs.fetchurl {
        url = "https://github.com/godotengine/godot-builds/releases/download/${version}/Godot_v${version}_linux.x86_64.zip";
        sha256 = "sha256-+UtyBhZjrXOOpNWbGMnsZQXkMYsO4mGyVSeFqLjVOkY=";
      };
      nativeBuildInputs = with pkgs; [ unzip ];
      sourceRoot = ".";
      installPhase = ''
        mkdir -p $out/bin
        chmod +x Godot_v${version}_linux.x86_64
        cp Godot_v${version}_linux.x86_64 $out/bin/godot-${version}
        ln $out/bin/godot-${version} $out/bin/newestGodot
      '';
    };
  xdm = pkgs.writeShellScriptBin "xdm" ''
    ${pkgs.jdk}/bin/java -jar ${
      (pkgs.fetchurl {
        url = "https://github.com/joselmm/xdm-2023/raw/main/xdman.jar";
        sha256 = "00wr708s1inkvb5gxmnwfqgsppa5x2shfjhvvv3y2fz8f7djmmym";
      })
    } "$@"
  '';
  # (
  #     let
  #       # 1. Fetch the binary AND make it executable
  #       portmaster-bin = pkgs.stdenv.mkDerivation {
  #         name = "portmaster-binary";
  #         src = pkgs.fetchurl {
  #           url = "https://updates.safing.io/latest/linux_amd64/start/portmaster-start";
  #           sha256 = "0n1g4qvb8aqsbb294kzwb9c91dlgs5irish4z4jqssmdkxbqqxy6"; # Use the hash from nix-prefetch-url
  #         };
  #         phases = [ "installPhase" ];
  #         installPhase = ''
  #           mkdir -p $out/bin
  #           cp $src $out/bin/portmaster-start
  #           chmod +x $out/bin/portmaster-start
  #         '';
  #       };

  #       # 2. Put that executable binary inside the FHS environment
  #       portmaster-pkg = pkgs.buildFHSEnv {
  #         name = "portmaster-start";
  #         targetPkgs =
  #           pkgs: with pkgs; [
  #             wget
  #             curl
  #             glibc
  #             zlib
  #             nss
  #             nspr
  #             atk
  #             at-spi2-atk
  #             libX11
  #             libxcb
  #             libXcomposite
  #             libXdamage
  #             libXext
  #             libXfixes
  #             libXrandr
  #             mesa
  #             expat
  #             iptables
  #             iproute2
  #           ];
  #         runScript = pkgs.writeScript "portmaster-wrapper" ''
  #           export PORTMASTER_DATA="$HOME/.local/share/portmaster"
  #           mkdir -p "$PORTMASTER_DATA"
  #           exec ${portmaster-bin}/bin/portmaster-start "$@"
  #         '';
  #       };
  #     in
  #     [
  #       # portmaster-bin
  #       # portmaster-pkg
  #     ]
  #   )
in
{
  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
      extraPkgs =
        pkgs: with pkgs; [
          python312
          python314
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
      (newestGodot "4.7-dev4")
      xdm
      (pkgFromInp "wayland-keepass-autotype" "default")
      (pkgFromInp "multi-game-launcher" "default")
      (pkgFromInp "audio-manager" "default")
      #
      typescript
      nodejs
      jpexs # ffdec
      deluged
      calibre
      gh
      portablemc
      niri
      gamescope
      (pkgFromInp "quickshell" "default") # widget thing
      wtype
      cliphist
      steam
      losslesscut-bin # video editor
      uwsm
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
      jdk
      xemu # xbox emu
      wl-clip-persist # keep clip past app death
      # blender
      ffmpeg
    ];
  };
  programs.gpu-screen-recorder.enable = true;
  environment.systemPackages = with pkgs; [
    # nix-direnv
    espeak-ng # tts
    speechd # tts
    neovim # tui text editor
    wget # cmd dl util
    brave # web browser
    nixfmt # nix language formatter
    git # git is required
    # kdePackages.kget
    _7zz # archival tool
    nix-ld # run linux programs
    kitty # terminal emulator
    # rofi
    # albert
    keyd # disables capslock and enables numlock
    anyrun # application launcher
    nix-output-monitor # nix update formatter
    cascadia-code # font
    swaynotificationcenter # notification daemon
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
    satty # image editor
    ncdu
    shellcheck
    lazygit
    # nginx
    unbound-with-systemd
  ];
  fonts.packages = with pkgs; with nerd-fonts; [
    jetbrains-mono
    hack
  ];

  # This is crucial for the system to "see" them
  fonts.fontconfig.enable = true;
  services = {
    # Enable PipeWire
    pipewire.enable = true;
    pipewire.wireplumber.enable = true;

    # PulseAudio compatibility (so applications using PulseAudio work)
    pipewire.pulse.enable = true;
    pipewire.alsa.enable = true;
    pipewire.alsa.support32Bit = true;
    pipewire.jack.enable = true;

    # Disable PulseAudio itself (optional, safer on NixOS)
    pulseaudio.enable = false;
  };
}
