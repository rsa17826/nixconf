{
  ln,
  inputs,
  pkgs,
  userConfig,
  config,
  ...
}:
{
  # home.activation.copy-hyprland-settings = ''
  #   echo "Copying hyprland settings..."
  #   mkdir -p "$HOME/.config/hypr/"
  #   mkdir -p "$HOME/.config/hypr/shaders"
  #   cp -f ${./hyprland.conf} "$HOME/.config/hypr/hyprland.conf"
  #   # sudo cp -fr ${./shaders} "$HOME/.config/hypr/shaders"
  # '';
  # xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;
  # xdg.configFile."hypr/shaders".source = ./shaders;
  # sudo ln -sf /home/nyx/nixconf/home/hyprland/hyprland.conf "$HOME/.config/hypr/hyprland.conf"
  xdg.configFile = {
    # Link the main Hyprland config file
    "hypr/hyprland.conf".source = ln "${userConfig.nixConf}/home/hyprland/hyprland.conf";
    "hypr/shaders" = {
      source = ln "${userConfig.nixConf}/home/hyprland/shaders";
      recursive = true;
    };
  };
  # xdg.configFile."hypr/hm.conf".text = ''
  #   plugin = ${
  #     inputs.hypr-dynamic-cursors.packages.${pkgs.stdenv.hostPlatform.system}.hypr-dynamic-cursors
  #   }/lib/libhypr-dynamic-cursors.so
  # '';
  xdg.configFile."hypr/hm.conf".text = ''
    plugin = hypr-darkwindow.packages.${pkgs.stdenv.hostPlatform.system}.Hypr-DarkWindow
  '';

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
