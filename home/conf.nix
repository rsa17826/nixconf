{
  userConfig,
  inputs,
  config,
  hostName,
  lib,
  pkgs,
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
    ./sops/conf.nix
    ./copyparty/conf.nix
    ./firewall/conf.nix
    ./brave/conf.nix
    ./syncthing/conf.nix
    # ./tts/conf.nix
  ];
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
    };
    systemd-boot = {
      enable = true;
      configurationLimit = 35;
    };
  };
  services = {
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
    keyd = {
      enable = true;
      keyboards = {
        default = {
          ids = [ "*" ];
          settings = {
            main = {
              numlock = "noop";
              capslock = "overload(control, esc)";
              # numlock = "repeat";
            };
          };
        };
      };
    };
    # opensnitch = {
    #   enable = true;
    # };

  };
  services.journald.storage = "persistent";

  nix = {
    settings = {
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };
    # 1. This pins the 'nixpkgs' flake to your system's input
    registry.nixpkgs.flake = inputs.nixpkgs;

    # 2. This maps the legacy <nixpkgs> path to your flake's nixpkgs
    # (Fixes older tools that don't know about flakes yet)
    nixPath = [ "nixpkgs=${inputs.nixpkgs.outPath}" ];
  };
  nixpkgs.config = {
    allowUnfreePredicate =
      pkg:
      builtins.elem (pkgs.lib.getName pkg) [
        "nvidia-x11"
        "nvidia-settings"
        "nvidia-persistenced"
        "steam"
        "steam-original"
        "steam-unwrapped"
      ];
  };
  nix.settings = {
    auto-optimise-store = true;
  };
  nix.gc = {
    persistent = true;
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };
  # Use latest kernel.
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  # boot.kernelPackages = pkgs.linuxPackages;
  boot.kernelPackages = pkgs.linuxPackages;
  environment.variables = {
    EDITOR = "nvim";
    SOPS_EDITOR = "codium --wait";
    VISUAL = "nvim";
    HYPRCURSOR_THEME = "mew";
    QT_STYLE_OVERRIDE = "adwaita-dark";
  };
  # systemd.services.numlock = {
  #   description = "Enable NumLock at startup";
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = "yes";
  #     ExecStart = "setleds +num";
  #   };
  # };
  console.useXkbConfig = true;
  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [ "JetBrainsMono Nerd Font Propo" ];
        serif = [ "JetBrainsMono Nerd Font Propo" ];
        monospace = [ "JetBrainsMono Nerd Font Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
  security = {
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
              command = "/etc/profiles/per-user/${userConfig.uname}/bin/pashare";
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

    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    # Configure network proxy if necessary
    # networking.proxy.default = "http://user:password@proxy:port/";
    # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Enable CUPS to print documents.
    # services.printing.enable = true;

    # Enable sound with pipewire.
    rtkit.enable = true;
  };
  hardware = {
    graphics = {
      enable32Bit = true;
      enable = true;
    };
    nvidia = {
      # Modesetting is required for most modern Wayland/X11 setups
      modesetting.enable = true;

      # This is the line Nix is complaining about:
      # Set to false because you have a Maxwell (GM200) GPU.
      open = false;

      # Enable the Nvidia settings menu
      nvidiaSettings = true;

      # Optionally, specify the package to ensure you stay on a compatible version
      package = config.boot.kernelPackages.nvidiaPackages.production;
    };
    # TODO
    # uinput things
    uinput.enable = true;
  };
  programs = {
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Core X11
        libX11
        libXcursor
        libXext
        libXi
        libXinerama
        libXrandr
        libxcb

        # Input & fonts
        libxkbcommon
        fontconfig

        # Wayland (fallback)
        wayland

        # Graphics
        libGL
        vulkan-loader
      ];
    };
    mouse-actions.enable = true;
  };
  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
  systemd.services.nix-custom-gc = {
    description = "Custom GFS Garbage Collection";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/etc/profiles/per-user/nyix/bin/customGC";
    };
  };

  systemd.timers.nix-custom-gc = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # sudo codium --no-sandbox --user-data-dir "/home/${userConfig.uname}/.config/VSCodium/"
  networking.hostName = "${hostName}";
  system = {
    stateVersion = "25.05";
  };

  #  fileSystems."/data" =
  #    { device = "/dev/disk/by-uuid/A801-0866";
  #      fsType = "ext4";
  #    };
  # services.kanata = {
  #   enable = true;

  #   keyboards.default = {
  #     devices = [
  #       "/dev/input/by-path/*-event-kbd"
  #     ];

  #     config = ''
  #       (defsrc
  #         a b c d e f g h i j k l m n o p q r s t u v w x y z
  #         spc bspc
  #       )

  #       ;; passthrough base layer (REQUIRED)
  #       (deflayer base
  #         a b c d e f g h i j k l m n o p q r s t u v w x y z
  #         spc bspc
  #       )

  #       ;; AHK-style text expansion
  #       (defseq
  #         (i n s s t e a d spc) (instead spc)
  #         (s u j e s t i o n s spc) (suggestions spc)
  #         (s u j e s t i o n spc) (suggestion spc)
  #         (b u t i f i e r spc) (beautifier spc)
  #         (p r o p i g a t o r spc) (propagator spc)
  #         (m u n i t e s spc) (minutes spc)
  #         (m i n i t s spc) (minutes spc)
  #       )
  #     '';
  #   };
  # };
}
