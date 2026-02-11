{
  uname,
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
  # home.activation.copy-hyprland-settings = ''
  #   echo "Linking hyprland settings..."
  #   mkdir -p "$HOME/.config/hypr"
  #   rm "$HOME/.config/hypr/hyprland.conf"
  #   ln -sf "${./hyprland.conf}" "$HOME/.config/hypr/hyprland.conf"
  # '';
  home.file.".config/hypr/hyprland.conf".source = ./hyprland.conf;
}
