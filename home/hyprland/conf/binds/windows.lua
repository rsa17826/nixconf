-- windows.lua

local mainMod = "SUPER"

-- ─── Switch workspaces ─────────────────────────────────────────────────────
hl.bind(mainMod .. " + a", hl.dsp.workspace(1))
hl.bind(mainMod .. " + s", hl.dsp.workspace(2))
hl.bind(mainMod .. " + d", hl.dsp.workspace(3))
hl.bind(mainMod .. " + f", hl.dsp.workspace(4))
hl.bind(mainMod .. " + e", hl.dsp.workspace(7))
hl.bind(mainMod .. " + r", hl.dsp.workspace(8))

-- ─── Move windows to workspaces ────────────────────────────────────────────
hl.bind("SUPER + Down",          hl.dsp.window.move_to_workspace(8, { silent = true }))
hl.bind(mainMod .. " + SHIFT + a", hl.dsp.window.move_to_workspace(1))
hl.bind(mainMod .. " + SHIFT + s", hl.dsp.window.move_to_workspace(2))
hl.bind(mainMod .. " + SHIFT + d", hl.dsp.window.move_to_workspace(3))
hl.bind(mainMod .. " + SHIFT + f", hl.dsp.window.move_to_workspace(4))
hl.bind(mainMod .. " + SHIFT + q", hl.dsp.window.move_to_workspace(5))
hl.bind(mainMod .. " + SHIFT + w", hl.dsp.window.move_to_workspace(6))
hl.bind(mainMod .. " + SHIFT + e", hl.dsp.window.move_to_workspace(7))
hl.bind(mainMod .. " + SHIFT + r", hl.dsp.window.move_to_workspace(8))

-- ─── Special workspace (scratchpad) ───────────────────────────────────────
hl.bind(mainMod .. " + z",        hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + z", hl.dsp.window.move_to_workspace("special:magic"))

-- ─── Scroll through workspaces with mouse wheel ────────────────────────────
hl.bind(mainMod .. " + mouse_down", hl.dsp.workspace("e+1"))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.workspace("e-1"))

-- ─── Mouse window actions ──────────────────────────────────────────────────
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.move())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

-- ─── Scrolling layout focus ────────────────────────────────────────────────
hl.bind(mainMod .. " + q",        hl.dsp.layout("focus l"))
hl.bind(mainMod .. " + w",        hl.dsp.layout("focus r"))
hl.bind(mainMod .. " + Tab",      hl.dsp.layout("focus l"))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.layout("focus r"))
