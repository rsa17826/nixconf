{
  config,
  pkgs,
  uname,
  lib,
  ...
}:
{
  home.username = uname;
  home.homeDirectory = "/home/${uname}";
  xsession.numlock.enable = true;
  imports = [
    ./vscode/conf.nix
    ./hyprland/conf.nix
    ./waybar/conf.nix
    ./fish/conf.nix
    ./shellScripts/conf.nix
    ./impermanence/conf.nix
    ./cursors/conf.nix
    ./disko/conf.nix
  ];
  #wayland.windowManager.hyprland = {
  #  # Whether to enable Hyprland wayland compositor
  #  enable = true;
  #  # The hyprland package to use
  #  package = pkgs.hyprland;
  #  # Whether to enable XWayland
  #  xwayland.enable = true;
  #
  #    # Optional
  #    # Whether to enable hyprland-session.target on hyprland startup
  #    systemd.enable = true;
  #  };
  #xdg.configFile."hypr/autostart.conf".text = ''
  #  ${pkgs.waybar}/bin/waybar &
  #  ${pkgs.networkmanagerapplet}/bin/nm-applet &
  #'';
  home.stateVersion = "25.11"; # Please read the comment before changing.
  programs = {
    kitty = {
      enable = true; # required for the default Hyprland config
    };

    anyrun = {
      enable = true;
      config = {
        x = {
          fraction = 0.5;
        };
        y = {
          fraction = 0.3;
        };
        width = {
          fraction = 0.3;
        };
        hideIcons = false;
        ignoreExclusiveZones = false;
        layer = "overlay";
        hidePluginInfo = false;
        closeOnClick = false;
        showResultsImmediately = true;
        maxEntries = null;

        plugins = [
          "${pkgs.anyrun}/lib/libapplications.so"
          "${pkgs.anyrun}/lib/libsymbols.so"
          #"${pkgs.anyrun}/lib/libshell.so"
          #"${pkgs.anyrun}/lib/libdictionary.so"
        ];
      };

      # Inline comments are supported for language injection into
      # multi-line strings with Treesitter! (Depends on your editor)
      extraCss = /* css */ ''
        .some_class {
          background: red;
        }
      '';

      extraConfigFiles."some-plugin.ron".text = ''
        Config(
          // for any other plugin
          // this file will be put in ~/.config/anyrun/some-plugin.ron
          // refer to docs of xdg.configFile for available options
        )
      '';
    };
    # hyprland = {
    #   enable = true;
    # };
    home-manager.enable = true;
  };

  # Optional, hint Electron apps to use Wayland:
  # home.sessionVariables.NIXOS_OZONE_WL = "1";

  #home.file.".icons/mew".source = lib.mkForce ./cursors;

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {

  };
  # home.packages = [
  #   (pkgs.writeShellScriptBin "nix-env" ''
  #     echo "nix-env is deprecated. Use nix profile or Home Manager."
  #     exit 1
  #   '')
  # ];

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/nyx/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "codium";
    VISUAL = "codium";
  };

  # Let Home Manager install and manage itself.
  imports = [
    # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix
    ./programs.nix
    ./nix/base.nix
    ./nix/plasma.nix
    # ./hardware-configuration.nix
  ];

  # Bootloader.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda"; # Install GRUB into the MBR
  };
  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    # Core X11
    xorg.libX11
    xorg.libXcursor
    xorg.libXext
    xorg.libXi
    xorg.libXinerama
    xorg.libXrandr
    xorg.libxcb

    # Input & fonts
    libxkbcommon
    fontconfig

    # Wayland (fallback)
    wayland

    # Graphics
    libGL
    vulkan-loader
  ];

  nix.gc.automatic = true;
  nix.gc.dates = "daily"; # or "daily"

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  security.sudo.extraRules = [
    {
      groups = [ "users" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/reboot";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
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
  environment.etc."mysecrets/github_token.env" = {
    source = "/etc/mysecrets/github_token.env"; # do not overwrite
    user = "root";
    group = "root";
    mode = "0400"; # root-only read
    enable = true;
  };
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
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        settings = {
          main = {
            capslock = "overload(control, esc)";
            # numlock = "repeat";
          };
        };
      };
    };
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
  # TODO
  # might do something
  # virtualisation.virtualbox.guest.enable = true;
  console.useXkbConfig = true;
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      sansSerif = [ "JetBrainsMono Nerd Font Propo" ];
      serif = [ "JetBrainsMono Nerd Font Propo" ];
      monospace = [ "JetBrainsMono Nerd Font Mono" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
  nixpkgs.overlays = [
    (import ./overlays/vscodium.nix)
    (import ./overlays/vscodium-dokitheme.nix)
  ];

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # xdg.portal = {
  #   enable = true;
  #   extraPortals = [
  #     pkgs.xdg-desktop-portal-hyprland
  #     pkgs.xdg-desktop-portal-gtk # Necessary for fallback
  #   ];
  #   config.common.default = "*"; # Or "hyprland;gtk"
  # };
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  # TODO
  # uinput things
  hardware.uinput.enable = true;
  programs.mouse-actions.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # sudo codium --no-sandbox --user-data-dir "/home/${uname}/.config/VSCodium/"
  networking.hostName = "${uname}";
  system.stateVersion = "25.05"; # Did you read the comment?
  services.opensnitch.enable = true;
  security.sudo.enable = true;
}
