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
  home.pointerCursor = {
    name = "mew"; # The name of the cursor theme
    size = 48; # Default cursor size (you can adjust this)
    gtk.enable = true;
    x11.enable = true;
    enable = true;

    package = pkgs.runCommand "mew" { } ''
        mkdir -p $out/share/icons/mew
        cp -r ${./cursors} $out/share/icons/mew/cursors
        cat > $out/share/icons/mew/index.theme <<EOF
      [Icon Theme]
      Name=mew
      Comment=Custom cursor theme
      Hidden=false
      Directories=cursors
      EOF
    '';
  };

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

}
