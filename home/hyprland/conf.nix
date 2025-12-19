{
  uname,
  ...
}:

{
  home.activation.copy-hyprland-settings = ''
    echo "Copying hyprland settings..."
    mkdir -p "$HOME/.config/hypr/"
    cp -f ${./hyprland.conf} "$HOME/.config/hypr/hyprland.conf"
  '';
}
