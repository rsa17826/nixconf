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
  # home.file.".config/hypr/hyprland.conf".source = ./hyprland.conf;
  # home.file.".config/hypr/shaders".source = ./shaders;
  # sudo ln -sf /home/nyx/nixconf/home/hyprland/hyprland.conf "$HOME/.config/hypr/hyprland.conf"
  home.file = {
    # Link the main Hyprland config file
    ".config/hypr/hyprland.conf".source = ln "${userConfig.nixConf}/home/hyprland/hyprland.conf";
    ".config/hypr/shaders" = {
      source = ln "${userConfig.nixConf}/home/hyprland/shaders";
      recursive = true;
    };
  };
  xdg.configFile."hypr/hm.conf".text = ''
    plugin = ${
      inputs.hypr-dynamic-cursors.packages.${pkgs.stdenv.hostPlatform.system}.hypr-dynamic-cursors
    }/lib/libhypr-dynamic-cursors.so
    
  ''; # // (
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
  # home.file.".config/hypr/hyprland.conf".source = ./hyprland.conf;
}
