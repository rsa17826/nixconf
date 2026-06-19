-- ─── Switch workspaces ─────────────────────────────────────────────────────
m.bind("#a", hl.dsp.focus({ workspace = 1 }))
m.bind("#s", hl.dsp.focus({ workspace = 2 }))
m.bind("#d", hl.dsp.focus({ workspace = 3 }))
m.bind("#f", hl.dsp.focus({ workspace = 4 }))
m.bind("#e", hl.dsp.focus({ workspace = 7 }))
m.bind("#r", hl.dsp.focus({ workspace = 8 }))

-- ─── Move windows to workspaces ────────────────────────────────────────────
m.bind("#+a", hl.dsp.window.move({ workspace = 1 }))
m.bind("#+s", hl.dsp.window.move({ workspace = 2 }))
m.bind("#+d", hl.dsp.window.move({ workspace = 3 }))
m.bind("#+f", hl.dsp.window.move({ workspace = 4 }))
-- m.bind("#+q", hl.dsp.window.move({ workspace = 5 }))
-- m.bind("#+w", hl.dsp.window.move({ workspace = 6 }))
m.bind("#+e", hl.dsp.window.move({ workspace = 7 }))
-- ─── Scroll through workspaces with mouse wheel ────────────────────────────
m.bind("#mouse_down", hl.dsp.focus({ workspace = "e+1" }))
m.bind("#mouse_up", hl.dsp.focus({ workspace = "e-1" }))
m.bind("#+z", hl.dsp.window.move({ workspace = "special:magic" }))

m.bind("#Down", hl.dsp.window.move({ workspace = 8, follow = false }))

m.bind("#+r", hl.dsp.window.move({ workspace = 8 }))

-- ─── Special workspace (scratchpad) ───────────────────────────────────────
m.bind("#z", hl.dsp.workspace.toggle_special("magic"))

-- ─── Mouse window actions ──────────────────────────────────────────────────
m.bind("#mouse:272", hl.dsp.window.drag(), { mouse = true })
m.bind("#mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ─── Scrolling layout focus ────────────────────────────────────────────────
m.bind("#q", hl.dsp.layout("focus l"))
m.bind("#w", hl.dsp.layout("focus r"))
m.bind("#Tab", hl.dsp.layout("focus l"))
m.bind("#+Tab", hl.dsp.layout("focus r"))

-- -- ─── Focus sub-workspace in current group ────────────────────────────────────
-- m.bind("#a", sw.focus(1))
-- m.bind("#s", sw.focus(2))
-- m.bind("#d", sw.focus(3))
-- m.bind("#f", sw.focus(4))
-- m.bind("#e", sw.focus(5))

-- -- ─── Move active window to sub-workspace in current group ────────────────────
-- m.bind("#+a", sw.move(1))
-- m.bind("#+s", sw.move(2))
-- m.bind("#+d", sw.move(3))
-- m.bind("#+f", sw.move(4))

-- -- ─── Switch groups (ALT + SUPER + number) ────────────────────────────────────
-- -- Jumps to group N, landing on the same sub-ws slot you were on.
-- m.bind("#1", sw.switch_group(1)) -- general dev
-- m.bind("#2", sw.switch_group(2)) -- godot
-- m.bind("#3", sw.switch_group(3)) -- free

-- -- ─── Move window to a different group ────────────────────────────────────────
-- m.bind("#+1", sw.move_to_group(1))
-- m.bind("#+2", sw.move_to_group(2))
-- m.bind("#+3", sw.move_to_group(3))

-- -- ─── Cycle groups ────────────────────────────────────────────────────────────
-- m.bind("#grave", sw.next_group(3))
-- m.bind("#+grave", sw.prev_group(3))
-- m.bind("#mouse_down", sw.next_group(1))
-- m.bind("#mouse_up", sw.prev_group(-1))

-- ─── Scroll through sub-workspaces ───────────────────────────────────────────
-- m.bind("#mouse_down", sw.focus_relative(1))
-- m.bind("#mouse_up",   sw.focus_relative(-1))
