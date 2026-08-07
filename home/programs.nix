{
  pkgs,
  userConfig,
  inputs,
  pkgFromInp,
  ...
}:
let
  browserSelectorPkg = pkgFromInp "browser-selector" "default";

  browserSelectorDesktop = pkgs.makeDesktopItem {
    name = "browser-selector";
    desktopName = "Browser Selector";
    genericName = "Web Browser";
    exec = "${browserSelectorPkg}/bin/browser-selector %u";
    mimeTypes = [
      # URL schemes
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "x-scheme-handler/ftp"
      "x-scheme-handler/chrome"
      "x-scheme-handler/about"
      "x-scheme-handler/unknown"

      # Web documents
      "text/html"
      "text/xml"
      "text/mhtml"
      "text/plain"
      "application/xhtml+xml"
      "application/xml"

      # PDFs (browsers handle these)
      "application/pdf"

      # Web feeds
      "application/rss+xml"
      "application/atom+xml"

      # Media (if you want browser to be the fallback)
      "audio/webm"
      "video/webm"
      "video/mp4"
      "audio/mp4"
      "audio/mp3"
    ];
    startupNotify = false;
    noDisplay = false;
  };

  newestGodot =
    version:
    pkgs.stdenv.mkDerivation {
      inherit version;
      pname = "godot-${version}";
      src = pkgs.fetchurl {
        url = "https://github.com/godotengine/godot-builds/releases/download/${version}/Godot_v${version}_linux.x86_64.zip";
        sha256 = "sha256-8+f+9IBJoRp2aQN+RAcbb+NhW1B4tM+1+PyNjDnoLzs=";
      };
      nativeBuildInputs = with pkgs; [ unzip ];
      sourceRoot = ".";
      installPhase = ''
        mkdir -p $out/bin
        chmod +x Godot_v${version}_linux.x86_64
        cp Godot_v${version}_linux.x86_64 $out/bin/godot-${version}
        ln $out/bin/godot-${version} $out/bin/godot-newest
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
  nixpkgs = {
    overlays = [
      inputs.millennium.overlays.default
      inputs.helium-flake.overlays.default
    ];
  };
  virtualisation = {
    docker = {
      enable = true;
    };
  };
  users = {
    users = {
      "${userConfig.uname}" = {
        shell = pkgs.zsh;
        isNormalUser = true;
        description = "${userConfig.uname}";
        extraGroups = [
          "networkmanager"
          "docker"
          "wheel"
          "opensnitch"
          "input"
          "audio"
          "tty"
          "video"
          "uinput"
        ];
        packages = with pkgs; [
          (newestGodot "4.7-beta2")
          xdm
          (pkgFromInp "wayland-keepass-autotype" "default")
          (pkgFromInp "multi-game-launcher" "default")
          (pkgFromInp "audio-manager" "default")
          (pkgFromInp "file-sorter" "default")
          (pkgFromInp "go-autoclicker" "default")
          (pkgFromInp "input-display" "default")
          (pkgFromInp "input-manager" "default")
          (pkgFromInp "key-modifier" "default")
          (pkgFromInp "autocorrect" "default")
          (pkgFromInp "alwaysFocusedInputBox" "default")
          (pkgFromInp "auto-screenshotter" "default")
          (pkgFromInp "macro-recorder" "default")
          (pkgFromInp "gowoify" "default")
          (pkgs.callPackage ./freenet-core/freenet-core.nix { })
          # (pkgFromInp "file-sorter" "default")
          browserSelectorPkg
          browserSelectorDesktop
          # why everything want these?
          icu
          openssl
          zlib
          inotify-info
          bandwhich
          #
          # (pkgFromInp "freenet-core" "default")
          python313Packages.wsgidav
          steam-run-free
          fluffychat
          docker
          inotify-tools
          nixd # nix language server
          (pkgs.buildGoModule {
            pname = "perkins";
            version = "1";
            src = inputs.perkins;
            vendorHash = "sha256-U9lhp3zxySA5cVwuSpOIaDca7ij/7o82YNenxZiACSI=";
          })
          opensnitch-ui
          wl-mirror
          clang-tools
          delve
          iosevka
          go
          blender
          archipelago
          gopls
          gcc
          socat
          kdlfmt
          libxkbcommon
          fzf
          (rofi.override {
            plugins = with pkgs; [
              (stdenv.mkDerivation {
                pname = "rofi-blocks";
                version = "unstable-2024-05";

                src = inputs.rofi-blocks-main;

                # --- THIS RESOLVES THE RUNTIME WARNING ---
                postPatch = ''
                  sed -i 's/\.name *= *"blocks"/&, .type = 1/' src/blocks.c
                '';

                PKG_CONFIG_ROFI_PLUGINSDIR = "${placeholder "out"}/lib/rofi";
                PKG_CONFIG_VAR_pluginsdir = "${placeholder "out"}/lib/rofi";

                nativeBuildInputs = with pkgs; [
                  pkg-config
                  meson
                  ninja
                ];

                buildInputs = with pkgs; [
                  glib
                  cairo
                  json-glib
                  rofi-unwrapped
                ];
              })
            ];
          })
          typescript
          nodejs
          (writeShellScriptBin "pixieditor" ''
            exec "/etc/profiles/per-user/${userConfig.uname}/bin/nonet" ${pkgs.pixieditor}/bin/pixieditor "$@"
          '')
          (pkgs.writeShellScriptBin "humanify" ''
            "$(${
              pkgs.fetchzip {
                url = "https://github.com/jehna/humanify/releases/download/v3.1.1/humanify-x86_64-unknown-linux-gnu.tar.gz";
                sha256 = "asdr708s1inkvb5gxmnwfqgsppa5x2shfjhvvv3y2fz8f7djmmym";
              }
            }/humanify)" "$@"
          '')
          jpexs # ffdec
          python314Packages.ruff
          deluged
          calibre
          gh
          portablemc
          dgop # process stat screen thing
          bc # fp math in bash
          gamescope
          (pkgFromInp "quickshell" "default") # widget thing
          wtype
          cliphist
          # steam
          # (steam.override { withMillennium = true; })
          losslesscut-bin # video editor
          uwsm
          # typos
          typos-lsp # spellchecker
          # keepass # password manager
          python313
          python313Packages.py7zr
          godot # programing
          stylua
          lua
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
          # (vscodium.override {
          #   commandLineArgs = "--password-store=basic --enable-blink-features=MiddleClickAutoscroll";
          # }) # text editor
          wineWow64Packages.unstableFull # windows apps
          winetricks
          unixtools.watch # watch cmd
          htop # process info
          # valent # kdeconnect
          # htop-vim
          # mission-center # task manager
          ydotool
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
          lua-language-server
          gpu-screen-recorder # screen recorder
          psmisc
          lutris-free
          faugus-launcher
          # thunar # wiztree
          # bottles
          # ulauncher
          qt6.qtdeclarative
          zenity
          libnotify
          simplex-chat-desktop # simple x chat
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
          fdupes
          dunst # notifier
          perl
          kdePackages.qtdeclarative
          gsettings-desktop-schemas
          kdePackages.kdenlive
          hicolor-icon-theme
        ];
      };
    };
  };
  services = {
    tumbler = {
      enable = true;
    };
    dbus = {
      enable = true;
      packages = with pkgs; [
        gsettings-desktop-schemas
        gtk3
      ];
    };
    gvfs = {
      enable = true;
    };
    pipewire = {
      # Enable PipeWire
      enable = true;
      wireplumber = {
        enable = true;
      };
      pulse = {
        # PulseAudio compatibility (so applications using PulseAudio work)
        enable = true;
      };
      alsa = {
        enable = true;
        support32Bit = true;
      };
      jack = {
        enable = true;
      };
    };
    pulseaudio = {
      # Disable PulseAudio itself (optional, safer on NixOS)
      enable = false;
    };
  };
  programs = {
    helium = {
      enable = true;
      flags = [
        "--remote-debugging-port=9222"
        "--password-store=basic"
        "--enable-blink-features=MiddleClickAutoscroll"
        "--enable-features=MiddleClickAutoscroll"
      ];
    };
    steam = {
      enable = true;
      package = pkgs.millennium-steam;
    };
    appimage = {
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

    hyprland = {
      enable = true;
      withUWSM = true;
      package = pkgFromInp "hyprland" "hyprland";
    };
    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
    };
    gpu-screen-recorder = {
      enable = true;
    };
  };
  environment = {
    systemPackages = with pkgs; [
      (pkgFromInp "termbar" "default")
      # nix-direnv
      # (pince.overrideAttrs (old: {
      #   postInstall = (old.postInstall or "") + ''
      #     find $out -name "HexView.py" -exec sed -i \
      #       's/if event\.modifiers/if event is not None and event.modifiers/' \
      #       {} \;
      #   '';
      # })) # cheat engine
      nethogs
      gtk3
      gdb
      tumbler
      gsettings-desktop-schemas
      glib # provides gio
      tumbler # thumbnail/icon service
      awww # wallpaper manager
      gvfs
      espeak-ng # tts
      speechd # tts
      neovim # tui text editor
      wget # cmd dl util
      # (brave.override {
      #   commandLineArgs = "--remote-debugging-port=9222 --password-store=basic --enable-blink-features=MiddleClickAutoscroll";
      # }) # web browser
      nixfmt # nix language formatter
      git # git is required
      # kdePackages.kget
      _7zz # archival tool
      nix-ld # run linux programs
      kitty # terminal emulator
      at-spi2-core
      ollama
      # albert
      # keyd # disables capslock and enables numlock
      git-filter-repo
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
      adwaita-qt
    ];
  };
}
