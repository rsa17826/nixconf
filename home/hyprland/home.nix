{
  mkEditableConfig,
  userConfig,
  lib,
  root,
  ...
}:
let
  editable = mkEditableConfig [
    {
      name = "hypr";
      src = root + "/home/hyprland";
      srcStr = "${userConfig.nixConf}/home/hyprland";
      nixKey = "hypr"; # key for xdg.configFile (relative to ~/.config/)
      dest = "$HOME/.config/hypr"; # full path for the shell script
      files = [
        "hyprland.lua"
        "hyprlock.conf"
      ];
      dirs = [
        "shaders"
        "wallpapers"
        "conf"
        "scripts"
      ];
    }
  ];
in
{
  home = {
    activation = {
      enableAllScripts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        nixconf="${userConfig.nixConf}"
        chmod +x "$nixconf/home/hyprland/scripts/"*.sh
      '';
    };
    packages = [ editable.editScript ];
  };
  xdg = {
    configFile = editable.entries;
  };
  services = {
    hyprpaper = {
      enable = false;
    };
  };

  # xdg.configFile."hypr/hm.conf".text = ''
  #   plugin = hypr-darkwindow.packages.${pkgs.stdenv.hostPlatform.system}.Hypr-DarkWindow
  # '';

  # // (
  #   # Map over the files in the ./shaders directory
  #   builtins.mapAttrs (name: value: {
  #     source = ln "${userConfig.nixConf}/home/hyprland/shaders/${name}";
  #   }) (builtins.readDir ./shaders)
  # );
  #    echo "Linking hyprland settings..."

  #    mkdir -p "$HOME/.config/hypr"
  #    #rm "$HOME/.config/hypr/hyprland.conf" >& /dev/null
  #    ln -f "$HOME/nixconf/home/hyprland/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
  #  '';
  # xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;
}
