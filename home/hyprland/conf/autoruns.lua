-- autoruns.lua

hl.exec_once("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GTK_THEME QT_STYLE_OVERRIDE")
hl.exec_once("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
hl.exec_once("gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark")
hl.exec_once("awww-daemon")
hl.exec_once("~/.config/hypr/scripts/random-wallpapers.sh 30")
hl.exec_once("pkill -9 codium")
hl.exec_once("~/.config/hypr/scripts/audacity-kill-dialog.sh")
hl.exec_once("progress-daemon")
hl.exec_once("gpu-screen-recorder -w screen -f 60 -a default_output -r 300 -c mp4 -o ~/videos/flashback")
hl.exec_once("qs -p ~/nixconf/quickshell/bar/")
hl.exec_once("python -m http.server -d ~/projects/jira-project-ui/ 15432")
-- Clipboard history
hl.exec_once("wl-paste --type text --watch cliphist store")
hl.exec_once("wl-paste --type image --watch cliphist store")
hl.exec_once("wl-clip-persist --clipboard regular")
hl.exec_once("xdm")
hl.exec_once("kitten panel --edge=background -o background_opacity=0.2 --margin-top 30 -o background=black dgop")

-- hl.exec_once("~/.config/hypr/scripts/edge-focus.sh")
