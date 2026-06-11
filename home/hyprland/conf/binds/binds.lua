-- binds.lua

-- ─── Media / hardware keys ─────────────────────────────────────────────────
m.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
m.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
m.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
m.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
m.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { repeating = true })
m.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { repeating = true })
m.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
m.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
m.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
m.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- ─── KeePass autotype ──────────────────────────────────────────────────────
m.bind("^!a", hl.dsp.exec_cmd("wayland-keepass-autotype -d ~/keepassdb/keepass.kdbx -c 30"))
m.bind("^!s", hl.dsp.exec_cmd("wayland-keepass-autotype -d ~/keepassdb/keepass.kdbx -c 30 --password-only"))
m.bind("^!d", hl.dsp.exec_cmd("wayland-keepass-autotype -d ~/keepassdb/keepass.kdbx -c 30 --otp-only"))

-- ─── Window / session actions ──────────────────────────────────────────────
-- Kill active window's process and relaunch it (preserving D-Bus/portal env)
m.bind("^+#r", hl.dsp.exec_cmd("~/.config/hypr/scripts/relaunch-active.sh"))
-- Fullscreen
m.bind("#c", hl.dsp.window.fullscreen_state({ internal = 0, client = 0 }))
-- m.bind("#c", hl.dsp.window.fullscreen())
-- m.bind("SHIFT + ALT + RETURN", hl.dsp.window.fullscreen())

-- Note: original had both fullscreen and fullscreenstate,1 1 on SHIFT+ALT+RETURN.
-- fullscreenstate sets client=1 internal=1 — uncomment below if you want that instead:
m.bind("+!\n", hl.dsp.window.fullscreen_state({ client = 1, internal = 1 }))

-- Lock
m.bind("#l", hl.dsp.exec_cmd("shaderstack disable && hyprlock --no-fade-in && shaderstack enable"))
-- m.bind("^#l", hl.dsp.exec_cmd("armLock"))

-- Window management
m.bind("^+Q", hl.dsp.window.close())

m.bind("#M", hl.dsp.exit())
m.bind("+!spc", hl.dsp.window.float({ action = "toggle" }))
m.bind("#P", hl.dsp.window.pseudo())

-- Clipboard viewer
m.bind(
	"^kp0",
	hl.dsp.exec_cmd(
		"/run/current-system/sw/bin/kitten quick-access-terminal python3.14 ~/nixconf/home/cliphistViewer/main.py"
	)
)
m.bind("^ins", hl.dsp.exec_cmd("pkill input-display || input-display s"))
hl.config({
	input = {
		kb_options = "caps:none,numpad:mac",
	},
})
