{
  pkgs,
  ...
}:
let
  cursorSrc = ./cursorImages;
  cursorName = "mew";
  "${cursorName}CursorPackage" =
    pkgs.runCommand "${cursorName}-cursor"
      {
        nativeBuildInputs = with pkgs; [
          xcursorgen
          gawk
        ];
      }
      ''
              set -e
              install -dm755 "$out/share/icons/${cursorName}/cursors"
              install -dm755 "$out/share/icons/${cursorName}/hyprcursors"

              # 1. Keep the native hyprcursor format as-is, for Hyprland's own renderer
              cp -r "${cursorSrc}/hyprcursors"/* "$out/share/icons/${cursorName}/hyprcursors/"
              cp "${cursorSrc}/manifest.hl" "$out/share/icons/${cursorName}/hyprcursors.hl" 2>/dev/null || true

              # 2. Convert each shape's meta.hl + pngs into a classic Xcursor binary
              for shapedir in "${cursorSrc}/hyprcursors"/*/; do
                shape=$(basename "$shapedir")
                meta="$shapedir/meta.hl"
                [ -f "$meta" ] || continue

                hotspot_x_frac=$(awk -F' = ' '/^hotspot_x/{print $2}' "$meta")
                hotspot_y_frac=$(awk -F' = ' '/^hotspot_y/{print $2}' "$meta")

                cfg="cfg_$shape.cursorgen"
                : > "$cfg"

                while IFS= read -r line; do
                  size=$(echo "$line" | awk -F'[ ,=]+' '{print $2}')
                  fname=$(echo "$line" | awk -F'[ ,=]+' '{print $3}')
                  delay=$(echo "$line" | awk -F'[ ,=]+' '{print $4}')

                  hx=$(awk -v f="$hotspot_x_frac" -v s="$size" 'BEGIN{printf "%d", f*s}')
                  hy=$(awk -v f="$hotspot_y_frac" -v s="$size" 'BEGIN{printf "%d", f*s}')

                  echo "$size $hx $hy $shapedir/$fname $delay" >> "$cfg"
                done < <(grep '^define_size' "$meta")

                if [ -s "$cfg" ]; then
                  xcursorgen "$cfg" "$out/share/icons/${cursorName}/cursors/$shape"
                fi
              done

              # Aliases classic Xcursor themes expect
              cd "$out/share/icons/${cursorName}/cursors"
              [ -f left_ptr ] && ln -sf left_ptr default
              [ -f arrow ] && [ ! -f left_ptr ] && ln -sf arrow left_ptr && ln -sf arrow default

              cat > "$out/share/icons/${cursorName}/index.theme" <<EOF
        [Icon Theme]
        Name="${cursorName}"
        Comment="${cursorName}"
        Inherits=Adwaita
        EOF

              chmod -R +r "$out/share/icons/${cursorName}"
      '';
in
{
  home = {
    pointerCursor = {
      name = "${cursorName}";
      size = 24;
      gtk = {
        enable = true;
      };
      x11 = {
        enable = true;
      };
      enable = true;
      package = "${cursorName}CursorPackage";
    };
  };
  dconf = {
    settings = {
      "org/gnome/desktop/interface" = {
        cursor-theme = "${cursorName}";
        cursor-size = 24;
      };
    };
  };
}
