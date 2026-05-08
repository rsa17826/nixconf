-- binds.lua

local mainMod = "SUPER"

-- ─── Media / hardware keys ─────────────────────────────────────────────────
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { repeating = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- ─── KeePass autotype ──────────────────────────────────────────────────────
hl.bind("CTRL + ALT + a", hl.dsp.exec_cmd("wayland-keepass-autotype -d ~/keepassdb/keepass.kdbx -c 30"))
hl.bind("CTRL + ALT + s", hl.dsp.exec_cmd("wayland-keepass-autotype -d ~/keepassdb/keepass.kdbx -c 30 --password-only"))
hl.bind("CTRL + ALT + d", hl.dsp.exec_cmd("wayland-keepass-autotype -d ~/keepassdb/keepass.kdbx -c 30 --otp-only"))

-- ─── Window / session actions ──────────────────────────────────────────────
-- Kill active window's process and relaunch it
hl.bind(
	"CTRL + SHIFT + SUPER + R",
	hl.dsp.exec_cmd(
		'sh -c \'PID=$(hyprctl activewindow -j | jq -r .pid); BIN=$(readlink /proc/$PID/exe); kill -9 "$PID" && sleep 0.3 && "$BIN" &\''
	)
)
-- Fullscreen
hl.bind("SUPER + c", hl.dsp.window.fullscreen())
-- hl.bind("SHIFT + ALT + RETURN", hl.dsp.window.fullscreen())

-- Note: original had both fullscreen and fullscreenstate,1 1 on SHIFT+ALT+RETURN.
-- fullscreenstate sets client=1 internal=1 — uncomment below if you want that instead:
hl.bind("SHIFT + ALT + RETURN", hl.dsp.window.fullscreen_state({ client = 1, internal = 1 }))

-- Reload / kill wtype
hl.bind("CTRL + escape", hl.dsp.exec_cmd("killall wtype ; hyprctl reload"))

-- Lock
hl.bind(mainMod .. " + l", hl.dsp.exec_cmd("hyprlock --no-fade-in"))
hl.bind("CTRL + " .. mainMod .. " + l", hl.dsp.exec_cmd("armLock"))

-- Screenshots (see screenshot.lua for the rest)
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m window"))

-- Window management
hl.bind("CTRL + SHIFT + Q", hl.dsp.window.close())
-- #TODO uwsm stop
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind("SHIFT + ALT + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())

-- Clipboard viewer
hl.bind(
	"CTRL + KP_Insert",
	hl.dsp.exec_cmd(
		"/run/current-system/sw/bin/kitten quick-access-terminal python3.14 ~/nixconf/home/cliphistViewer/main.py"
	)
)
hl.config({
	input = {
		kb_options = "caps:none,numpad:mac",
	},
})
