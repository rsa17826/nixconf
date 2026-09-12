hl.window_rule({
	match = {
		title = "^targetgun$",
	},
	pin = true,
	float = true,
	border_size = 0,
	no_blur = true,
	no_dim = true,
	no_shadow = true,
	move = { 1920 - 360, 1080 - 520 },
	opacity = "1 override",
})

-- The dots overlay: one full-screen borderless window that just shows the
-- blue dots (positioned with plain Fyne coordinates now, not per-window
-- hyprctl placement). If you want it visually see-through over whatever's
-- behind it, that's a compositor opacity rule on this title specifically —
-- e.g. (syntax depends on your `hl` wrapper; this repo's own config uses):
-- opacity = ".1 override",
-- Left off by default since Fyne still paints an opaque background here;
-- add it back if you want the translucent look and don't mind it applying
-- to the whole dots window (dots included) uniformly.
hl.window_rule({
	match = {
		title = "^targetgun-dots$",
	},
	pin = true,
	float = true,
	border_size = 0,
	no_blur = true,
	no_dim = true,
	no_shadow = true,
	no_focus = true,
})
