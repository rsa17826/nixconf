-- hyprland.lua
-- Main config entry point. Use require() to load sub-files.
-- Each require() is its own scope so errors in one don't kill others.

local mainMod = "SUPER"

-- ─── Monitor ───────────────────────────────────────────────────────────────
hl.monitor({
  name       = "",          -- catch-all for any monitor
  resolution = "preferred",
  position   = "auto",
  scale      = 1,
})

-- ─── Environment variables ─────────────────────────────────────────────────
hl.env("GTK_THEME",              "Adwaita:dark")
hl.env("ADW_DEBUG_COLOR_SCHEME", "prefer-dark")
hl.env("QT_QPA_PLATFORMTHEME",   "gtk3")
hl.env("XCURSOR_SIZE",           "24")
hl.env("HYPRCURSOR_SIZE",        "24")
hl.env("XCURSOR_THEME",          "24")
hl.env("HYPRCURSOR_THEME",       "mew")

-- ─── Core config ───────────────────────────────────────────────────────────
hl.config({
  general = {
    layout       = "scrolling",
    gaps_in      = 2,
    gaps_out     = 0,
    border_size  = 2,
    active_border_color   = "rgba(000000ee) rgba(ff00ffee) 45deg",
    inactive_border_color = "rgba(000000ee) rgba(ff00ffee) 45deg",
    resize_on_border = false,
    allow_tearing    = false,
  },

  input = {
    numlock_by_default = true,
    kb_layout          = "us",
    follow_mouse       = 1,
    sensitivity        = 0,
    touchpad = {
      natural_scroll = true,
    },
  },

  cursor = {
    no_hardware_cursors = true,
  },

  debug = {
    damage_tracking = 0,
  },

  misc = {
    middle_click_paste         = false,
    focus_on_activate          = true,
    force_default_wallpaper    = -1,
    disable_hyprland_logo      = false,
    initial_workspace_tracking = true,
  },

  decoration = {
    rounding       = 10,
    rounding_power = 2,
    active_opacity   = 1.0,
    inactive_opacity = 0.5,
    shadow = {
      enabled      = true,
      range        = 4,
      render_power = 3,
      color        = "rgba(1a1a1aee)",
    },
    blur = {
      enabled   = true,
      size      = 3,
      passes    = 1,
      xray      = false,
      vibrancy  = 0.1696,
    },
  },

  animations = {
    enabled = false,
  },

  dwindle = {
    pseudotile     = true,
    preserve_split = true,
  },

  binds = {
    allow_workspace_cycles = true,
  },

  -- Scrolling layout (was plugin:hyprscrolling in old config)
  scrolling = {
    column_width     = 1.0,
    focus_fit_method = 0,
  },
})

-- ─── Per-device input ──────────────────────────────────────────────────────
hl.device({
  name        = "epic-mouse-v1",
  sensitivity = -0.5,
})

-- ─── Gestures ──────────────────────────────────────────────────────────────
-- Old: gesture = 3, horizontal, workspace
hl.gesture({
  fingers    = 3,
  direction  = "horizontal",
  dispatcher = hl.dsp.workspace("e+1"),  -- swipe right = next workspace
})

-- ─── Sub-configs ───────────────────────────────────────────────────────────
require("autoruns")
require("window rules")
require("windows")
require("binds")
require("launcher")
require("screenshot")
require("dynamic cursors")
