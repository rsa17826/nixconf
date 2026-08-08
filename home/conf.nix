{
  userConfig,
  inputs,
  hostName,
  lib,
  pkgs,
  listDir,
  ...
}:
let
  sudoKeepVars = [
    "EDITOR"
    "VISUAL"
    "NIXOS_LABEL_VERSION"
    "NIXOS_LABEL"
  ];
in
{
  imports = [
    ./alias.nix

  ]
  ++ (listDir ./. (p: ./${p}/conf.nix));
  services = {
    gnome = {
      at-spi2-core = {
        enable = true;
      };
    };

    udev = {
      extraRules = ''
        KERNEL=="uinput", GROUP="input", MODE="0660"
        KERNEL=="tty0", GROUP="tty", MODE="0660"
      '';
      # ACTION=="add", SUBSYSTEM=="leds", KERNEL=="*::scrolllock", GROUP="video", MODE="0664"
    };

    speechd = {
      # Enable the Speech Dispatcher daemon
      enable = true;
    };

    udisks2 = {
      enable = true;
    };
    xserver = {
      videoDrivers = [ "nvidia" ];
    };
    journald = {
      # keyd = {
      #   enable = true;
      #   keyboards = {
      #     default = {
      #       ids = [ "*" ];
      #       settings = {
      #         main = {
      #           numlock = "noop";
      #           capslock = "overload(control, esc)";
      #           # numlock = "repeat";
      #         };
      #       };
      #     };
      #   };
      # };
      # opensnitch = {
      #   enable = true;
      # };

      storage = "persistent";
    };
    resolved = {
      enable = false;
    };
  };
  boot = {
    kernel = {
      sysctl = {
        "kernel.yama.ptrace_scope" = 0;
        "kernel.core_pattern" = "|/bin/false";
        "vm.swappiness" = 10;
      };
    };

    kernelModules = [ "uinput" ];

    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      systemd-boot = {
        enable = true;
        configurationLimit = 35;
      };
    };
    # boot = {
    #   # Use latest kernel.
    #   # kernelPackages = pkgs.linuxPackages_latest;
    #   # kernelPackages = pkgs.linuxPackages;
    # };
    kernelPackages = pkgs.linuxPackages;
    tmp = {
      cleanOnBoot = true;
    };
  };
  security = {
    pam = {
      services = {
        hyprlock = {
          text = ''
            auth include login
          '';
        };
      };
    };
    # wrappers = {
    #   pince = {
    #     source = "${pkgs.pince}/bin/pince";
    #     capabilities = "cap_sys_ptrace+eip";
    #     owner = "root";
    #     group = "root";
    #   };
    # };

    sudo = {
      extraConfig = ''
        Defaults env_keep += "${lib.concatStringsSep " " sudoKeepVars}"
      '';
      extraRules = [
        {
          groups = [ "users" ];
          commands = [
            {
              command = "/run/current-system/sw/bin/shutdown";
              options = [ "NOPASSWD" ];
            }
            {
              command = "/run/current-system/sw/bin/reboot";
              options = [ "NOPASSWD" ];
            }
          ];
        }
        {
          users = [ "${userConfig.uname}" ];
          commands = [
            {
              command = "/run/current-system/sw/bin/nixos-rebuild";
              options = [ "NOPASSWD" ];
            }
            {
              command = "/etc/profiles/per-user/${userConfig.uname}/bin/pwashare";
              options = [ "NOPASSWD" ];
            }
            {
              command = "/etc/profiles/per-user/nyx/bin/githubNotifications";
              options = [
                "NOPASSWD"
                # "NOEXEC"
              ];
            }
          ];
        }
      ];
      enable = true;
    };
    # networking = {
    #   wireless = {
    #     enable = true;
    #   };
    #   proxy = {
    #     # Enables wireless support via wpa_supplicant.
    #     # Configure network proxy if necessary
    #     default = "http://user:password@proxy:port/";
    #     noProxy = "127.0.0.1,localhost,internal.domain";
    #   };
    # };
    # services = {
    #   printing = {
    #     # Enable CUPS to print documents.
    #     enable = true;
    #   };
    # };
    # rtkit = {
    #   # Enable sound with pipewire.
    #   enable = true;
    # };
  };
  nixpkgs = {
    overlays = [
      (final: prev: {
        pkgsi686Linux = prev.pkgsi686Linux.extend (
          _: p: {
            openldap = p.openldap.overrideAttrs (_: {
              doCheck = false;
            });
          }
        );
      })
    ];
    config = {
      allowUnfreePredicate =
        pkg:
        builtins.elem (pkgs.lib.getName pkg) [
          "cuda_cccl"
          "cuda_cudart"
          "nvidia-x11"
          "nvidia-settings"
          "nvidia-persistenced"
          "nvidia-kernel-modules"
          "steam"
          "steam-original"
          "steam-unwrapped"
        ];
    };
  };
  nix = {
    registry = {
      nixpkgs = {
        # 1. This pins the 'nixpkgs' flake to your system's input
        flake = inputs.nixpkgs;
      };
    };

    # 2. This maps the legacy <nixpkgs> path to your flake's nixpkgs
    # (Fixes older tools that don't know about flakes yet)
    nixPath = [ "nixpkgs=${inputs.nixpkgs.outPath}" ];
    settings = {
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];

      auto-optimise-store = true;
    };
  };

  environment = {
    variables = {
      EDITOR = "nvim";
      SOPS_EDITOR = "codium --wait";
      VISUAL = "nvim";
      HYPRCURSOR_THEME = "mew";
      # QT_STYLE_OVERRIDE = "adwaita-dark";
    };
  };
  console = {
    useXkbConfig = true;
  };
  fonts = {
    packages =
      with pkgs;
      with nerd-fonts;
      [
        jetbrains-mono
        hack
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
      ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [
          "Hack Nerd Font Propo"
          "JetBrainsMono Nerd Font Propo"
          "Noto Sans CJK JP"
          "Noto Sans CJK KR"
          "Noto Sans CJK SC"
          "Noto Sans CJK TC"
        ];
        serif = [
          "Hack Nerd Font Propo"
          "JetBrainsMono Nerd Font Propo"
          "Noto Serif CJK JP"
          "Noto Serif CJK KR"
          "Noto Serif CJK SC"
          "Noto Serif CJK TC"
        ];
        monospace = [
          "Hack Nerd Font Mono"
          "JetBrainsMono Nerd Font Mono"
          "Noto Sans Mono CJK JP"
          "Noto Sans Mono CJK KR"
          "Noto Sans Mono CJK SC"
          "Noto Sans Mono CJK TC"
        ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
  hardware = {
    graphics = {
      enable32Bit = true;
      enable = true;
    };
    nvidia-container-toolkit = {
      enable = true;
    };
    nvidia = {
      modesetting = {
        # Modesetting is required for most modern Wayland/X11 setups
        enable = true;
      };

      # This is the line Nix is complaining about:
      # Set to false because you have a Maxwell (GM200) GPU.
      open = false;

      # Enable the Nvidia settings menu
      nvidiaSettings = true;

      # Optionally, specify the package to ensure you stay on a compatible version
      package = pkgs.linuxPackages_6_18.nvidiaPackages.legacy_580;
    };
    uinput = {
      # TODO
      # uinput things
      enable = true;
    };
  };
  programs = {
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Core X11
        libX11
        libXcursor
        libXext
        libSM
        libICE
        libXrender
        libXi
        libXinerama
        libXrandr
        libxcb
        libXxf86vm
        # Input & fonts
        libxkbcommon
        fontconfig

        # Wayland (fallback)
        wayland

        # Graphics
        libGL
        vulkan-loader

        glibc
        icu
        gcc
        zlib
        openssl

        libdecor
        # Audio
        libpulseaudio
        alsa-lib

        libvorbis
        libogg
        libGLU
        gtk3
        pango
        harfbuzz
        at-spi2-atk
        cairo
        gdk-pixbuf
        glib
      ];
    };
  };
  systemd = {
    services = {
      # nix-custom-gc = {
      #   description = "Custom GFS Garbage Collection";
      #   serviceConfig = {
      #     Type = "oneshot";
      #     ExecStart = "/etc/profiles/per-user/nyix/bin/customGC";
      #   };
      # };
    };
    user = {
      services = {
        dynamicRebinds = {
          wantedBy = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];

          serviceConfig = {
            ExecStart = "/home/nyix/projects/dynamicRebinds/dynamicRebinds";
            Restart = "on-failure";
            RestartSec = "5s";
            KillMode = "mixed";
          };
        };
        input-manager = {
          description = "Input Manager";
          wantedBy = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];

          serviceConfig = {
            ExecStart = "/etc/profiles/per-user/${userConfig.uname}/bin/input-manager k \"id:usb-0c45_USB_Wired_Keyboard-event-kbd\" m \"id:usb-04d9_USB_Gaming_Mouse-event-mouse\" k \"id:usb-04d9_USB_Gaming_Mouse-if01-event-kbd\" maxX 1920 maxY 1080";
            Restart = "on-failure";
            RestartSec = "5s";
            KillMode = "mixed";
          };
        };
        macro-recorder = {
          wantedBy = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          path = with pkgs; [
            xdg-utils
            # vscodium
          ];

          serviceConfig = {
            Environment = "PATH=/etc/profiles/per-user/${userConfig.uname}/bin:/run/current-system/sw/bin/:/home/${userConfig.uname}/.nix-profile/bin/";
            ExecStart = "/etc/profiles/per-user/${userConfig.uname}/bin/macro-recorder";
            Restart = "on-failure";
            RestartSec = "5s";
            KillMode = "mixed";
            PassEnvironment = [
              "DISPLAY"
              "WAYLAND_DISPLAY"
              "XDG_CURRENT_DESKTOP"
              "DBUS_SESSION_BUS_ADDRESS"
              # "PATH"
            ];
          };
        };
        autocorrect = {
          description = "Autocorrect Daemon";
          wantedBy = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];

          serviceConfig = {
            ExecStart = "/etc/profiles/per-user/${userConfig.uname}/bin/autocorrect --capsHasBeenDisabled";
            Restart = "on-failure";
            RestartSec = "5s";
            KillMode = "mixed";
          };
        };
        autoclicker = {
          description = "Autoclicker Daemon";
          wantedBy = [ "graphical-session.target" ];
          after = [
            "graphical-session.target"
            "input-manager.service"
          ];
          requires = [ "input-manager.service" ];

          serviceConfig = {
            ExecStart = "/etc/profiles/per-user/${userConfig.uname}/bin/go-autoclicker startAutoclicker";
            Restart = "on-failure";
            RestartSec = "2s";
          };
        };
      };
    };
    # timers = {
    #   nix-custom-gc = {
    #     wantedBy = [ "timers.target" ];
    #     timerConfig = {
    #       OnCalendar = "daily";
    #       Persistent = true;
    #     };
    #   };
    # };
  };
  networking = {
    hostName = "${hostName}";
  };
  system = {
    stateVersion = "25.05";
  };
}
