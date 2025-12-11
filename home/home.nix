{
  config,
  pkgs,
  uname,
  ...
}:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = uname;
  home.homeDirectory = "/home/${uname}";
  xsession.numlock.enable = true;
  wayland.windowManager.hyprland = {
    # Whether to enable Hyprland wayland compositor
    enable = true;
    # The hyprland package to use
    package = pkgs.hyprland;
    # Whether to enable XWayland
    xwayland.enable = true;

    # Optional
    # Whether to enable hyprland-session.target on hyprland startup
    systemd.enable = true;
  };
  #xdg.configFile."hypr/autostart.conf".text = ''
  #  ${pkgs.waybar}/bin/waybar &
  #  ${pkgs.networkmanagerapplet}/bin/nm-applet &
  #'';

  # VS Code

  home.stateVersion = "25.11"; # Please read the comment before changing.
  programs = {
    kitty = {
      enable = true; # required for the default Hyprland config
    };
    hyprland = {
      enable = true;
    };
    home-manager.enable = true;
    vscode = {
      enable = true;
      package = pkgs.vscodium;
      mutableExtensionsDir = false;

      profiles.default = {
        extensions = [

        ];
        userSettings = {
          # force = true;
          "editor.tabSizea" = 30;
          "files.trimTrailingWhitespace" = true;
        };
      };
    };
  };

  # Optional, hint Electron apps to use Wayland:
  # home.sessionVariables.NIXOS_OZONE_WL = "1";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.opensnitch-ui
    pkgs.vscodium
  ];
  # systemd.user.services.albert = {
  #   description = "Albert Launcher";
  #   after = [ "graphical.target" ];

  #   serviceConfig = {
  #     ExecStart = "${pkgs.makeWrapper}/bin/makeWrapper ${pkgs.albert}/bin/albert /home/username/bin/albert-launch.sh --set QT_QPA_PLATFORMTHEME gtk2 --set QT_STYLE_OVERRIDE Fusion";
  #     Restart = "always";
  #     Environment = "DISPLAY=:0";
  #   };

  #   wantedBy = [ "default.target" ];
  # };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

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
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.

}
