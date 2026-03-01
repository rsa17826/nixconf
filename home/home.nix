{
  config,
  pkgs,
  userConfig,
  inputs,
  ...
}:
let
  gtkExtraConfig = {
    gtk-application-prefer-dark-theme = 1;
    gtk-enable-animations = 0;
  };
in
{
  home.username = userConfig.uname;
  home.homeDirectory = "/home/${userConfig.uname}";
  xsession.numlock.enable = true;
  _module.args = {
    ln = config.lib.file.mkOutOfStoreSymlink;
  };
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ./vscode/conf.nix
    ./hyprland/conf.nix
    # ./waybar/conf.nix
    ./cursors/conf.nix
    ./zsh/plugins.nix
    # ./git/conf.nix
  ];
  services.playerctld.enable = true;
  xdg = {
    enable = true;
    dataHome = "/home/${userConfig.uname}/.local/share";
    configHome = "/home/${userConfig.uname}/.config";
    cacheHome = "/home/${userConfig.uname}/.cache";
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

      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-hyprland
      ];

      config = {
        common = {
          default = [
            "hyprland"
            "gtk"
          ];
        };
      };
    };
  };
  home.stateVersion = "25.11"; # Please read the comment before changing.
  programs = {
    kitty = {
      enable = true; # required for the default Hyprland config
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
    gtk3.extraConfig = gtkExtraConfig;
    gtk4.extraConfig = gtkExtraConfig;
  };

  qt = {
    enable = true;

    platformTheme.name = "gtk";

    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  home.sessionVariables = {
    EDITOR = "codium";
    VISUAL = "codium";
    HYPRCURSOR_THEME = "mew";
    QT_STYLE_OVERRIDE = "adwaita-dark";
  };

  # Bootloader.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
}
