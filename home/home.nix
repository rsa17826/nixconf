{
  config,
  pkgs,
  userConfig,
  inputs,
  ...
}:
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
    ./waybar/conf.nix
    ./cursors/conf.nix
    ./sops/conf.nix
    ./zsh/plugins.nix
    ./git/conf.nix
    ./keepass/conf.nix
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
  xdg.enable = true;
  xdg.dataHome = "/home/${userConfig.uname}/.local/share";
  xdg.configHome = "/home/${userConfig.uname}/.config";
  xdg.cacheHome = "/home/${userConfig.uname}/.cache";
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
      name = "Adwaita-dark"; # Or any dark theme like "catppuccin-mocha"
      package = pkgs.gnome-themes-extra;
    };
    # This line tells apps to "Prefer Dark" via dconf
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };
  home.sessionVariables = {
    EDITOR = "codium";
    VISUAL = "codium";
    HYPRCURSOR_THEME = "mew";
  };

  # Bootloader.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
}
