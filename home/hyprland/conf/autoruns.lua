-- autoruns.lua

hl.on("hyprland.start", function()
	-- hl.exec_cmd("python -m http.server -d ~/projects/jira-project-ui/ 15432")
	hl.exec_cmd("hyprctl output create headless test_top")
	hl.exec_cmd("hyprctl output create headless test_bottom")
	hl.exec_cmd("hyprctl output create headless input_display")
	hl.exec_cmd("wl-mirror --title top test_top")
	hl.exec_cmd("wl-mirror --title bottom test_bottom")
	-- hl.exec_cmd("timeout 20 sh -c 'wl-mirror --title bottom test_bottom&wl-mirror --title top test_top'")
	hl.exec_cmd(
		"dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GTK_THEME QT_STYLE_OVERRIDE"
	)
	-- hl.exec_cmd("opensnitch-ui")
	hl.exec_cmd("systemctl --user import-environment QT_QPA_PLATFORMTHEME WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	hl.exec_cmd("~/.config/hypr/scripts/audacity-kill-dialog.sh")
	hl.exec_cmd("~/.config/hypr/scripts/random-wallpapers.sh 30")
	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("go run ~/projects/nulserv/main.go")
	-- hl.exec_cmd("job-prompt")
	hl.exec_cmd(
		"sh -c 'gpu-screen-recorder -w screen -f 60 -a default_output -r 300 -c mp4 -k hevc_vulkan -q 40000 -o ~/videos/flashback -bm cbr & echo $! > /tmp/gpu-screen-recorder-flashback.pid; wait $!'"
	)
	-- hl.exec_cmd(
	-- 	'gpu-screen-recorder -w "HDMI-A-1|input_display;halign=end;valign=end;width=30%;height=30%" -o video.mp4'
	-- )
	hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-enable-primary-paste false")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark")
	-- hl.exec_cmd("1 panel --edge=background -o background_opacity=0.2 --margin-top 30 -o background=black dgop")
	hl.exec_cmd("pkill -9 codium")
	-- hl.exec_cmd("progress-daemon")
	hl.exec_cmd("qs -p ~/nixconf/quickshell/bar/")
	hl.exec_cmd("shaderstack clear")
	hl.exec_cmd("wl-clip-persist --clipboard regular")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd(
		"wsgidav --host=127.0.0.1 --port=2143 --root=~/BACKUPS/webdav --server cheroot --config=~/BACKUPS/webdav/wsgidav.yaml"
	)
	hl.exec_cmd('sh -c "cd ~/BACKUPS && push"')
	-- hl.exec_cmd("xdm")
	hl.exec_cmd("edit-conf exit")
end)

hl.on("config.reloaded", function()
	hl.exec_cmd("shaderstack enable")
end)
-- hl.exec_cmd("~/.config/hypr/scripts/edge-focus.sh")
