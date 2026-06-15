-- hl.window_rule({
-- 	match = { class = "^codium$", title = "vex-plus-plus - VSCodium" },
-- 	scrolling_width = 0.3,
-- 	workspace = "3",
-- })

-- window_rules.lua

-- Suppress maximize requests from all windows
hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

-- yad: float, unmaximize, pin, center
hl.window_rule({
	name = "a",
	match = { class = "^yad$" },
	float = true,
	fullscreen = false,
	pin = true,
	center = true,
})

-- XWayland drag fix: no focus on empty-class floating windows
hl.window_rule({
	name = "fix-xwayland-drags",
	match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
	no_focus = true,
})

-- zenity: keep focused and centered
hl.window_rule({
	name = "alwaysFocusedInputBox",
	match = { class = "^alwaysFocusedInputBox$" },
	fullscreen = false,
	pin = true,
	float = true,
	stay_focused = true,
	focus_on_activate = true,
	allows_input = true,
	center = true,
})
hl.window_rule({
	name = "fzenity",
	match = { class = "^zenity$" },
	fullscreen = false,
	pin = true,
	stay_focused = true,
	focus_on_activate = true,
	allows_input = true,
	center = true,
	workspace = "special",
})

-- XDM main window → workspace 8 silent
hl.window_rule({
	name = "asd",
	match = { class = "^xdman-Main$", title = "^Xtreme Download Manager$" },
	workspace = "8 silent",
	-- workspace = { 1, 8, "silent" },
})

-- hyprland-run popup: float, bottom-left area
hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = { "20", "monitor_h-120" },
	float = true,
})

-- Codium: tile on workspace 1 (excluding file dialogs)
hl.window_rule({
	match = { class = "^codium$", title = "negative:^(Save As|Open (File|Folder))$", float = false },
	workspace = "1",
	-- workspace = { 0, 1 },
})

-- Codium: file dialogs → float, centered, large
hl.window_rule({
	match = { class = "^codium$", title = "^(Save As|Open (File|Folder))$" },
	float = true,
	center = true,
	size = { "monitor_w*0.8", "monitor_h*0.8" },
	-- move = { "(monitor_w*0.5)-(monitor_w*0.8/2)", "(monitor_h*0.5)-(monitor_h*0.8/2)" },
	dim_around = true,
	stay_focused = false,
})

-- LosslessCut: file open dialog → float, centered, large
hl.window_rule({
	match = { class = "^Losslesscut$", title = "^(Open file)$" },
	float = true,
	center = true,
	size = { "monitor_w*0.8", "monitor_h*0.8" },
	-- move = { "(monitor_w*0.5)-(monitor_w*0.8/2)", "(monitor_h*0.5)-(monitor_h*0.8/2)" },
	dim_around = true,
	stay_focused = false,
})

-- Global Progress: full opacity, floating
hl.window_rule({
	match = { title = "^Global Progress$" },
	opacity = "1.0 override 1.0 override",
	float = true,
})

-- Brave: Save As → float
hl.window_rule({
	match = { class = "^brave-browser$", title = "^Save As$" },
	float = true,
})

-- Brave: Save File dialog → float, centered, large
hl.window_rule({
	match = { class = "^brave$", title = "^Save File$" },
	float = true,
	center = true,
	size = { "monitor_w*0.8", "monitor_h*0.8" },
	-- move = { "(monitor_w*0.5)-(monitor_w*0.8/2)", "(monitor_h*0.5)-(monitor_h*0.8/2)" },
	dim_around = true,
	stay_focused = false,
})

hl.window_rule({
	match = { class = "^Key Display$", title = "^Key Display$" },
	float = true,
	-- size = { "516", "142" },
	move = { "5", "933" },
	dim_around = false,
	no_initial_focus = true,
	pin = true,
	suppress_event = "activatefocus activate",
	stay_focused = false,
	allows_input = false,
	decorate = false,
	focus_on_activate = false,
	no_anim = true,
	no_blur = true,
	no_dim = true,
	no_focus = true,
	no_follow_mouse = true,
	no_shadow = true,
	opaque = false,
	opacity = "0.8 override",
	render_unfocused = true,
})

-- Beatblock: fullscreen
hl.window_rule({
	match = { class = "^Beatblock$", title = "^Beatblock$" },
	fullscreen = true,
})

-- Brave browser → workspace 2
hl.window_rule({
	match = { class = "^brave-browser$" },
	workspace = "2",
	-- workspace = { 1, 2 },
})

-- Eets (steam game)
hl.window_rule({
	match = { class = "^steam_app_default$", title = "^Eets$" },
	no_max_size = true,
	fullscreen = true,
	-- #TODO string
	-- fullscreen_state = { client = 2, internal = 0 },
})

-- HyprSpy: pin, float
-- hl.window_rule({
-- 	match = { title = "^HyprSpy$" },
-- 	pin = true,
-- 	float = true,
-- })
hl.window_rule({
	match = { class = "steam_app_4555180|steam_app_3910870|steam_app_2533590|steam_app_4225220|steam_app_4182710" }, -- Find this using the 'hyprctl clients' command
	suppress_event = "fullscreen maximize",
	fullscreen_state = "1 2",
})
-- hl.on("window.fullscreen", function(w)
-- 	-- 2 means the window just entered true fullscreen internally
-- 	if w.fullscreen == 2 then
-- 		hl.dispatch(hl.dsp.window.fullscreen_state({
-- 			internal = 1, -- Force Hyprland to maximize it instead
-- 			client = 2, -- Tell the app "Yes, you are fullscreen"
-- 			window = w, -- Target this specific window
-- 		}))
-- 	end
-- end)
hl.monitor({
	output = "HDMI-A-1",
	mode = "1920x1080@60",
	position = "0x0",
	scale = 1,
})
-- hl.monitor({
-- 	output = "test_top",
-- 	mode = "1920x28@60",
-- 	position = "1920x0",
-- 	scale = 1,
-- })

hl.monitor({
	output = "test_bottom",
	mode = "1920x1050@60",
	-- position = "0x28",
	position = "1920x28",
	scale = 1,
})
hl.window_rule({
	match = { title = ".*" },
	monitor = "test_bottom",
})
hl.window_rule({
	match = { class = "at.yrlf.wl_mirror", title = "top|bottom" },
	float = true,
	pin = true,
	dim_around = false,
	stay_focused = false,
	monitor = "HDMI-A-1",
	opacity = "1 override",
	no_anim = true,
	no_blur = true,
	no_dim = true,
	no_shadow = true,
	-- focus_on_activate = false,
	-- no_focus = true,
	decorate = false,
})
hl.window_rule({
	match = { class = "at.yrlf.wl_mirror", title = "bottom" },
	size = { "monitor_w", "monitor_h-28" },
	move = { "0", "28" },
})
-- hl.window_rule({
-- 	match = { class = "at.yrlf.wl_mirror", title = "top" },
-- 	size = { "monitor_w", "28" },
-- 	move = { "0", "150" },
-- })
for i = 1, 100 do
	hl.workspace_rule({ workspace = tostring(i), monitor = "test_bottom", enabled = true, persistent = true })
end

-- Browser Selector (Tk): pin, float, centered, large
hl.window_rule({
	match = { class = "^Tk$", title = "^Browser Selector$" },
	pin = true,
	float = true,
	center = true,
	size = { "monitor_w*0.8", "monitor_h*0.8" },
	-- move = { "(monitor_w*0.5)-(monitor_w*0.8/2)", "(monitor_h*0.5)-(monitor_h*0.8/2)" },
	dim_around = true,
	stay_focused = false,
})

hl.window_rule({
	match = { class = "^Audacity$" },
	scrolling_width = 1.0,
})
hl.window_rule({
	match = { title = "^Kid3$", class = "^org.kde.kid3$" },
	scrolling_width = 1.0,
})
hl.window_rule({
	match = { class = "^Godot$" },
	scrolling_width = 0.7,
})

hl.window_rule({
	name = "asddasd",
	match = { class = "^steam$" },
	workspace = "3 silent",
})
hl.window_rule({
	name = "Mathbreakers",
	match = { class = "^mathbreakers.exe$" },
	suppress_event = "fullscreen activatefocus activate fullscreenoutput",
	scrolling_width = 1,
	workspace = "3 silent",
	content = "none",
})
hl.window_rule({
	name = "hjhhkMathasdbreakers",
	match = {
		class = "^Mathbreakers$",
		-- title = "^kitten$",
	},
	pin = true,
	float = true,
	no_focus = true,
	no_initial_focus = true,
	size = { "0940.0", "200" },
	move = { "0", "30" },
	border_size = 0,
})
hl.window_rule({
	name = "math-hidden",
	match = { class = "^Mathbreakers$", tag = "math_hide" },
	opacity = "0 override",
})
hl.window_rule({
	name = "math-visible",
	match = { class = "^Mathbreakers$" },
	opacity = "1 override",
})
-- hl.window_rule({
-- 	name = "asdd",
-- 	match = { class = "^xdman-Main$" },
-- 	workspace = "8 silent",
-- 	-- workspace = {1,8, "silent"},
-- })

-- hl.window_rule({
-- 	match = { class = "^codium$", title = "vex-plus-plus - VSCodium" },
-- 	scrolling_width = 0.3,
-- 	workspace = "3",
-- })
