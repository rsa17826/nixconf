hl.window_rule({
	match = { class = "^codium$", title = "vex-plus-plus - VSCodium" },
	scrolling_width = 0.3,
	workspace = "3",
})

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
hl.window_rule({
	match = { title = "^HyprSpy$" },
	pin = true,
	float = true,
})

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

-- hl.window_rule({
-- 	name = "asdd",
-- 	match = { class = "^xdman-Main$" },
-- 	workspace = "8 silent",
-- })
hl.window_rule({
	match = { class = "^codium$", title = "vex-plus-plus - VSCodium" },
	scrolling_width = 0.3,
	workspace = "3",
})