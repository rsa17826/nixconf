{
  config,
  pkgs,
  userConfig,
  inputs,
  lib,
  listDir,
  ...
}:
let
  gtkExtraConfig = {
    gtk-application-prefer-dark-theme = 1;
    gtk-enable-animations = 0;
  };
in
{
  home = {
    username = userConfig.uname;
    homeDirectory = "/home/${userConfig.uname}";
    stateVersion = "26.05";

    sessionVariables = {
      EDITOR = "nvim";
      SOPS_EDITOR = "codium --wait";
      VISUAL = "nvim";
      HYPRCURSOR_THEME = "mew";
      QT_STYLE_OVERRIDE = "adwaita-dark";
      ADW_DISABLE_PORTAL = "0";
      GTK_THEME = "Adwaita-dark";
      GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
      GTK_USE_PORTAL = "1";
    };
  };
  _module = {
    args = {
      ln = config.lib.file.mkOutOfStoreSymlink;
      mkEditableConfig = import ./home/editconf/a.nix { inherit pkgs lib; };
    };
  };
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ]
  ++ (listDir ./. (p: ./${p}/home.nix));
  systemd = {
    user = {
      services = {
        swaync = {
          Service = {
            Restart = lib.mkForce "no";
          };
          Install = {
            # Also, prevent Home Manager from trying to start them during activation
            WantedBy = lib.mkForce [ ];
          };
        };
        xdg-desktop-portal-gtk = {
          Service = {
            Restart = lib.mkForce "no";
          };
          Install = {
            WantedBy = lib.mkForce [ ];
          };
        };
      };
    };
  };
  services = {
    swaync = {
      enable = true;
    };
    playerctld = {
      enable = true;
    };
  };
  xdg = {
    enable = true;
    dataHome = "/home/${userConfig.uname}/.local/share";
    configHome = "/home/${userConfig.uname}/.config";
    cacheHome = "/home/${userConfig.uname}/.cache";
    desktopEntries = {
      kitty-audd = {
        name = "audd";
        genericName = "audio download";
        exec = "kitty sh -c \"audd && exit\"";
        icon = "utilities-terminal";
        categories = [ "Utility" ];
        terminal = false;
      };
      kitty-vidd = {
        name = "vidd";
        genericName = "video download";
        exec = "kitty sh -c \"vidd && exit\"";
        icon = "utilities-terminal";
        categories = [ "Utility" ];
        terminal = false;
      };
    };
    # desktopEntries.yazi = {
    #   name = "Yazi";
    #   exec = "kitty -e yazi %u"; # Replace 'kitty' with your terminal (alacritty, foot, etc.)
    #   terminal = false;
    #   mimeType = [ "inode/directory" ];
    #   categories = [
    #     "System"
    #     "FileTools"
    #     "FileManager"
    #   ];
    # };

    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = [ "thunar.desktop" ];
        # "inode/directory" = [ "yazi.desktop" ];
      };
    };

    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
      ];
      config = {
        common = {
          default = [
            "hyprland"
            "gtk"
          ];
        };
        vscodium = {
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        };
      };

      # enable = true;
      # config.common.default = "*";
      # extraPortals = with pkgs; [
      #   xdg-desktop-portal-gtk
      #   xdg-desktop-portal-hyprland
      # ];

      # config = {
      #   # common.default = [
      #   #   "hyprland"
      #   # ];
      #   # gtk.default = [
      #   #   "gtk"
      #   # ];
      # };
    };
  };
  programs = {
    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
    };
    kitty = {
      enable = true;
    };
    home-manager = {
      enable = true;
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
          # "${pkgs.anyrun}/lib/libsymbols.so"
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
  };

  # Optional, hint Electron apps to use Wayland:
  # home.sessionVariables.NIXOS_OZONE_WL = "1";

  #home.file.".icons/mew".source = lib.mkForce ./cursors;

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.

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
  gtk = {
    enable = true;

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    gtk3 = {
      extraConfig = gtkExtraConfig;
    };
    gtk4 = {
      extraConfig = gtkExtraConfig;
      # gtk4.theme = config.gtk.theme;
      theme = null;
    };
  };

  qt = {
    enable = true;
    platformTheme = {
      name = "gtk2";
    };
    style = {
      name = "adwaita-dark";
      package = pkgs.symlinkJoin {
        name = "adwaita-qt-all";
        paths = with pkgs; [
          adwaita-qt
          adwaita-qt6
        ];
      };
    };
  };
  dconf = {
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };

  # Bootloader.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
}
