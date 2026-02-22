{
  pkgs,
  ...
}:
{
  home.pointerCursor = {
    name = "mew"; # The name of the cursor theme
    size = 48; # Default cursor size (you can adjust this)
    gtk.enable = true;
    x11.enable = true;
    enable = true;

    package = pkgs.runCommand "mew" { } ''
        mkdir -p $out/share/icons/mew
        cp -r ${./cursorImages} $out/share/icons/mew/cursors
        cat > $out/share/icons/mew/index.theme <<EOF
      [Icon Theme]
      Name=mew
      Comment=mew
      Hidden=false
      Directories=cursors
      Inherits=Adwaita
      Example=default
      EOF

        # Fix permissions just in case
        chmod -R +r $out/share/icons/mew
    '';
  };
  # ???
  # dconf.settings = {
  #   "org/gnome/desktop/interface" = {
  #     cursor-theme = "mew";
  #     cursor-size = 48;
  #   };
  # };
}
