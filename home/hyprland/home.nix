{
  pkgs,
  userConfig,
  lib,
  root,
  ...
}:
let
  mkEditableConfig = import (root + "/home/editconf/a.nix") { inherit pkgs lib; };

  editable = mkEditableConfig [
    {
      name = "hypr";
      src = root + "/home/hyprland";
      srcStr = "${userConfig.nixConf}/home/hyprland";
      dest = "hypr";
      files = [
        "hyprland.conf"
        "hyprland.lua"
        "hyprlock.conf"
        "hyprpaper.conf"
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
    configFile = editable.xdgEntries;
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
