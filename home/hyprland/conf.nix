{
  uname,
  ...
}:

{
  home.activation.copy-hyprland-settings = ''
    echo "Copying hyprland settings..."
    mkdir -p "$HOME/.config/hypr/"
    mkdir -p "$HOME/.config/hypr/shaders"
    cp -f ${./hyprland.conf} "$HOME/.config/hypr/hyprland.conf"
    # sudo cp -fr ${./shaders} "$HOME/.config/hypr/shaders"
  '';
}
