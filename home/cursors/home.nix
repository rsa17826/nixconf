{
  pkgs,
  ...
}:
{
  home = {
    # home.pointerCursor = {
    #   name = "mew"; # The name of the cursor theme
    #   size = 24; # Default cursor size (you can adjust this)
    #   gtk.enable = true;
    #   x11.enable = true;
    #   enable = true;

    #   package = pkgs.runCommand "mew" { } ''
    #       mkdir -p $out/share/icons/mew
    #       cp -r ${./cursorImages} $out/share/icons/mew/cursors
    #       cat > $out/share/icons/mew/index.theme <<EOF
    #     [Icon Theme]
    #     Name=mew
    #     Comment=mew
    #     Hidden=false
    #     Directories=cursors
    #     Inherits=Adwaita
    #     Example=default
    #     EOF

    #       # Fix permissions just in case
    #       chmod -R +r $out/share/icons/mew
    #   '';
    # };
    pointerCursor = {
      name = "mew";
      size = 24;
      gtk = {
        enable = true;
      };
      x11 = {
        enable = true;
      };
      enable = true;

      package = pkgs.runCommand "mew-cursor" { } ''
              install -dm755 $out/share/icons/mew/cursors

              # Copy the contents of your folder directly into the cursors dir
              cp -rn ${./cursorImages}/* $out/share/icons/mew/cursors/

              # Crucial: Wayland/X11 needs a 'default' file in the cursors dir
              # Adjust 'left_ptr' to whatever your main pointer file is named in cursorImages
              if [ -f $out/share/icons/mew/cursors/left_ptr ]; then
                ln -s left_ptr $out/share/icons/mew/cursors/default
              fi

              cat > $out/share/icons/mew/index.theme <<EOF
        [Icon Theme]
        Name=mew
        Comment=mew
        Inherits=Adwaita
        EOF
      '';
    };
  };
  dconf = {
    settings = {
      "org/gnome/desktop/interface" = {
        cursor-theme = "mew";
        cursor-size = 24;
      };
    };
  };
}
