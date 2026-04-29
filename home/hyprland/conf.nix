{
  ln,
  inputs,
  pkgs,
  userConfig,
  pkgFromInp,
  config,
  lib,
  ...
}:
{
  home.activation.enableAllScripts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    nixconf="${userConfig.nixConf}"
    chmod +x "$nixconf/home/hyprland/scripts/"*.sh
  '';
  # xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;
  # xdg.configFile."hypr/shaders".source = ./shaders;
  # sudo ln -sf /home/nyx/nixconf/home/hyprland/hyprland.conf "$HOME/.config/hypr/hyprland.conf"
  xdg.configFile = {
    "hypr/hyprland.conf".source = ln "${userConfig.nixConf}/home/hyprland/hyprland.conf";
    "hypr/hyprlock.conf".source = ln "${userConfig.nixConf}/home/hyprland/hyprlock.conf";
    "hypr/hyprpaper.conf".source = ln "${userConfig.nixConf}/home/hyprland/hyprpaper.conf";
    "hypr/shaders" = {
      source = ln "${userConfig.nixConf}/home/hyprland/shaders";
      recursive = true;
    };
    "hypr/wallpapers" = {
      source = ln "${userConfig.nixConf}/home/hyprland/wallpapers";
      recursive = true;
    };
    "hypr/conf" = {
      source = ln "${userConfig.nixConf}/home/hyprland/conf";
      recursive = true;
    };
    "hypr/scripts" = {
      source = ln "${userConfig.nixConf}/home/hyprland/scripts";
      recursive = true;
    };
  };
  xdg.configFile."hypr/hm.conf".text = ''
    plugin = ${(pkgFromInp "hypr-dynamic-cursors" "hypr-dynamic-cursors")}/lib/libhypr-dynamic-cursors.so
  '';
  services.hyprpaper = {
    enable = true;
  };
  security.pam.services.hyprlock = {
    text = ''
      auth include login
    '';
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
