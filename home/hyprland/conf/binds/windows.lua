-- windows.lua

local mainMod = "SUPER"

-- ─── Switch workspaces ─────────────────────────────────────────────────────
hl.bind(mainMod .. " + a", hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + s", hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + d", hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + f", hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + e", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + r", hl.dsp.focus({ workspace = 8 }))

-- ─── Move windows to workspaces ────────────────────────────────────────────
hl.bind("SUPER + Down", hl.dsp.window.move({ workspace = 8, follow = false }))
hl.bind(mainMod .. " + SHIFT + a", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + SHIFT + s", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + SHIFT + d", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + SHIFT + f", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + SHIFT + q", hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + SHIFT + w", hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + SHIFT + e", hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + SHIFT + r", hl.dsp.window.move({ workspace = 8 }))

-- ─── Special workspace (scratchpad) ───────────────────────────────────────
hl.bind(mainMod .. " + z", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + z", hl.dsp.window.move({ workspace = "special:magic" }))

-- ─── Scroll through workspaces with mouse wheel ────────────────────────────
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- ─── Mouse window actions ──────────────────────────────────────────────────
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ─── Scrolling layout focus ────────────────────────────────────────────────
hl.bind(mainMod .. " + q", hl.dsp.layout("focus l"))
hl.bind(mainMod .. " + w", hl.dsp.layout("focus r"))
hl.bind(mainMod .. " + Tab", hl.dsp.layout("focus l"))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.layout("focus r"))
