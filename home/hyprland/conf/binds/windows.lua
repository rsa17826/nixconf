-- ─── Switch workspaces ─────────────────────────────────────────────────────
m.bind("#a", hl.dsp.focus({ workspace = 1 }))
m.bind("#s", hl.dsp.focus({ workspace = 2 }))
m.bind("#d", hl.dsp.focus({ workspace = 3 }))
m.bind("#f", hl.dsp.focus({ workspace = 4 }))
m.bind("#e", hl.dsp.focus({ workspace = 7 }))
m.bind("#r", hl.dsp.focus({ workspace = 8 }))

-- ─── Move windows to workspaces ────────────────────────────────────────────
m.bind("#Down", hl.dsp.window.move({ workspace = 8, follow = false }))
m.bind("#+a", hl.dsp.window.move({ workspace = 1 }))
m.bind("#+s", hl.dsp.window.move({ workspace = 2 }))
m.bind("#+d", hl.dsp.window.move({ workspace = 3 }))
m.bind("#+f", hl.dsp.window.move({ workspace = 4 }))
m.bind("#+q", hl.dsp.window.move({ workspace = 5 }))
m.bind("#+w", hl.dsp.window.move({ workspace = 6 }))
m.bind("#+e", hl.dsp.window.move({ workspace = 7 }))
m.bind("#+r", hl.dsp.window.move({ workspace = 8 }))

-- ─── Special workspace (scratchpad) ───────────────────────────────────────
m.bind("#z", hl.dsp.workspace.toggle_special("magic"))
m.bind("#+z", hl.dsp.window.move({ workspace = "special:magic" }))

-- ─── Scroll through workspaces with mouse wheel ────────────────────────────
m.bind("#mouse_down", hl.dsp.focus({ workspace = "e+1" }))
m.bind("#mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- ─── Mouse window actions ──────────────────────────────────────────────────
m.bind("#mouse:272", hl.dsp.window.drag(), { mouse = true })
m.bind("#mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ─── Scrolling layout focus ────────────────────────────────────────────────
m.bind("#q", hl.dsp.layout("focus l"))
m.bind("#w", hl.dsp.layout("focus r"))
m.bind("#Tab", hl.dsp.layout("focus l"))
m.bind("#+Tab", hl.dsp.layout("focus r"))
