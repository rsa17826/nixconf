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
    if ls "$nixconf/home/hyprland/scripts/"*.sh &>/dev/null; then
      chmod +x "$nixconf/home/hyprland/scripts/"*.sh
    fi
  '';
  # xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;
  # xdg.configFile."hypr/shaders".source = ./shaders;
  # sudo ln -sf /home/nyx/nixconf/home/hyprland/hyprland.conf "$HOME/.config/hypr/hyprland.conf"
  xdg.configFile = {
    "hypr/hyprland.conf".source = ln "${userConfig.nixConf}/home/hyprland/hyprland.conf";
    "hypr/hyprlock.conf".source = ln "${userConfig.nixConf}/home/hyprland/hyprlock.conf";
    "hypr/shaders" = {
      source = ln "${userConfig.nixConf}/home/hyprland/shaders";
      recursive = true;
    };
    "hypr/wallpapers" = {
      source = ln "${userConfig.nixConf}/home/hyprland/wallpapers";
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
    settings = {
      preload = [
        "~/.config/hypr/wallpapers/bafkreibsnx3lvxw4lq26nmqv6q7stdor3xs5scfobdcyukayz6v23lnk4i.webp"
        "~/.config/hypr/wallpapers/wallpaper.png"
        "~/.config/hypr/wallpapers/videoframe_940409.png"
      ];
      wallpaper = [
        # By display
        # {
        #   monitor = "DP-2";
        #   path = "~/wallpapers/wallpaper2.jpg";
        # }
        # By default/fallback
        {
          monitor = "";
          path = "~/.config/hypr/wallpapers/videoframe_940409.png";
        }
      ];
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
