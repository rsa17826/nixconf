-- hyprland.lua
-- Main config entry point. Use require() to load sub-files.
-- Each require() is its own scope so errors in one don't kill others.

-- do
-- m={}
-- function bind(keys, func, args?{}){
--   next=0
--   while keys[next] in '#!+^'{
--     nk+=({"#":"super","!":"alt","+":"shift","^":"control"})
--     if keys[next+1]
--     nk+=' + '
--     next+=1
--   }
--   nk+=keys[next::]
--   -- allow hl bind
--   hl.bind(nk, func, args)
-- }
-- end

-- Global table accessible everywhere

-- ─── Monitor ───────────────────────────────────────────────────────────────
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
})

-- ─── Environment variables ─────────────────────────────────────────────────
hl.env("GTK_THEME", "Adwaita:dark")
hl.env("ADW_DEBUG_COLOR_SCHEME", "prefer-dark")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "24")
hl.env("HYPRCURSOR_THEME", "mew")
hl.env("YDOTOOL_SOCKET", "/tmp/.ydotool_socket")
hl.env("GONOPROXY", "github.com/rsa17826/*")
hl.env("GOPRIVATE", "github.com/rsa17826/*")

-- ─── Core config ───────────────────────────────────────────────────────────
hl.config({
	general = {
		-- asd=
		layout = "scrolling",
		gaps_in = 0,
		gaps_out = 0,
		border_size = 2,
		col = {
			active_border = { colors = { "rgba(000000ee)", "rgba(ff00ffee)" }, angle = 45 },
			inactive_border = { colors = { "rgba(000000ee)", "rgba(ff00ffee)" }, angle = 45 },
		},
		resize_on_border = false,
		allow_tearing = false,
	},

	input = {
		numlock_by_default = true,
		kb_layout = "us",
		follow_mouse = 1,
		sensitivity = 0,
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
		middle_click_paste = false,
		focus_on_activate = true,
		force_default_wallpaper = -1,
		disable_hyprland_logo = false,
		initial_workspace_tracking = true,
	},

	decoration = {
		rounding = 10,
		rounding_power = 2,
		active_opacity = 1.0,
		inactive_opacity = 0.5,
		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = "rgba(1a1a1aee)",
		},
		blur = {
			enabled = true,
			size = 3,
			passes = 1,
			xray = false,
			vibrancy = 0.1696,
		},
	},

	animations = {
		enabled = true,
	},

	dwindle = {
		-- pseudotile     = true,
		preserve_split = true,
	},

	binds = {
		allow_workspace_cycles = true,
	},

	scrolling = {
		column_width = 0.5,
		fullscreen_on_one_column = true,
		focus_fit_method = 1,
	},
})
-- ─── Per-device input ──────────────────────────────────────────────────────
hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})

-- ─── Gestures ──────────────────────────────────────────────────────────────
-- Old: gesture = 3, horizontal, workspace
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

hl.animation({ leaf = "global", enabled = false, speed = 10, bezier = "default" })

-- hl.curve("bounce", { type = "bezier", points = { { 0.68, -0.55 }, { 0.265, 1.55 } } })
-- hl.animation({ leaf = "windowsMove", enabled = true, speed = 2, bezier = "bounce" })

-- ─── Sub-configs ───────────────────────────────────────────────────────────
-- Get the config directory path (usually ~/.config/hypr)
local config_dir = os.getenv("XDG_CONFIG_HOME") .. "/hypr/"
local conf_path = "conf/"

-- Function to auto-require
local function auto_require(dir)
	-- Use 'find' to get all .lua files in the directory recursively
	local handle = io.popen("find " .. config_dir .. dir .. ' -name "*.lua"')
	if not handle then
		return
	end

	local result = handle:read("*a")
	handle:close()

	for file in string.gmatch(result, "([^%\n]+)") do
		-- 1. Remove the full path to make it relative to the config root
		-- 2. Remove the .lua extension
		local module = file:gsub(config_dir, ""):gsub("%.lua$", "")

		-- Don't require 'init' files or you might loop
		if not module:match("init$") and not module:match("/_") and not module:match("/helpers/") then
			require(module)
		end
	end
end
local handle = io.popen("find " .. config_dir .. conf_path .. 'helpers/ -name "*.lua"')
if not handle then
	return
end

local result = handle:read("*a")
handle:close()

for file in string.gmatch(result, "([^%\n]+)") do
	-- 1. Remove the full path to make it relative to the config root
	-- 2. Remove the .lua extension
	local module = file:gsub(config_dir, ""):gsub("%.lua$", "")

	-- Don't require 'init' files or you might loop
	if not module:match("init$") and not module:match("/_") then
		require(module)
	end
end
auto_require(conf_path)
