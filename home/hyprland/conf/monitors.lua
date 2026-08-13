hl.monitor({
	output = "HDMI-A-1",
	mode = "1920x1080@60",
	position = "0x1052",
	scale = 1,
})
hl.monitor({
	output = "test_top",
	mode = "1920x28@61",
	position = "2000x0",
	scale = 1,
})

hl.monitor({
	output = "test_bottom",
	mode = "1920x1051@61",
	position = "2000x28",
	scale = 1,
})
hl.monitor({
	output = "input_display",
	mode = "560x142@61",
	position = "4000x4000",
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
	render_unfocused = true,
	focus_on_activate = true,
	-- no_focus = true,
	decorate = false,
	-- suppress_event = "activate",
})
-- hl.window_rule({
-- 	match = { class = "at.yrlf.wl_mirror", title = "top|bottom" },
-- 	no_focus = true,
-- })
hl.window_rule({
	match = { class = "at.yrlf.wl_mirror", title = "bottom" },
	size = { "monitor_w", "monitor_h-28" },
	move = { "0", "28" },
})
hl.window_rule({
	match = { class = "at.yrlf.wl_mirror", title = "top" },
	size = { "monitor_w", "28" },
	move = { "0", "0" },
})

for i = 1, 100 do
	hl.workspace_rule({ workspace = tostring(i), monitor = "test_bottom", enabled = true, persistent = true })
end
hl.workspace_rule({ workspace = "input_display", monitor = "input_display", enabled = true, persistent = true })

-- hl.dsp.force_renderer_reload({})

hl.window_rule({
	match = { class = "^Key Display$", title = "^Key Display$" },
	float = true,
	-- size = { "516", "142" },
	move = { "5", "905" },
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
	-- workspace = "input_display",
})
