-- autoruns.lua

hl.on("hyprland.start", function ()
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GTK_THEME QT_STYLE_OVERRIDE")
  hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
  hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("~/.config/hypr/scripts/random-wallpapers.sh 30")
  hl.exec_cmd("pkill -9 codium")
  hl.exec_cmd("~/.config/hypr/scripts/audacity-kill-dialog.sh")
  hl.exec_cmd("progress-daemon")
  hl.exec_cmd("gpu-screen-recorder -w screen -f 60 -a default_output -r 300 -c mp4 -o ~/videos/flashback")
  hl.exec_cmd("qs -p ~/nixconf/quickshell/bar/")
  hl.exec_cmd("python -m http.server -d ~/projects/jira-project-ui/ 15432")
  -- Clipboard history
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
  hl.exec_cmd("wl-clip-persist --clipboard regular")
  hl.exec_cmd("xdm")
  hl.exec_cmd("kitten panel --edge=background -o background_opacity=0.2 --margin-top 30 -o background=black dgop")
  end)


-- hl.exec_cmd("~/.config/hypr/scripts/edge-focus.sh")
