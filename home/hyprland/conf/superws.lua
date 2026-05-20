-- superws.lua
-- Super-workspace navigation + window routing via native Hyprland Lua API.
-- No subprocesses, no external daemons.

local sw = {}

local SIZE = 10 -- workspaces per group
local route_map = {
	-- Group-agnostic: same sub-ws regardless of which group you're in
	["brave-browser"] = 2,
	["firefox"] = 2,
	["vscodium"] = 1,
	["code"] = 1,
	["godot"] = 1,
	["godot_editor"] = 1,
	["kitty"] = 3,
	["foot"] = 3,
}

hl.on("window.open", function(win)
	local class = (win.class or ""):lower()
	local ws = hl.get_active_workspace()
	if not ws then
		return
	end

	local group = math.floor((ws.id - 1) / SIZE)

	-- ── group-specific overrides ──────────────────────────────────────────
	-- e.g. in group 2 (godot), send codium to sub-ws 2 instead of sub-ws 1
	if group == 1 then -- group 2 is index 1 (0-based)
		if class == "vscodium" or class == "code" then
			hl.dispatch(hl.dsp.window.move({ workspace = group * SIZE + 2, follow = false }))
			return
		end
	end

	-- ── default routing from map ──────────────────────────────────────────
	local sub = route_map[class]
	if not sub then
		return
	end

	local target = group * SIZE + sub
	if win.workspace and win.workspace.id == target then
		return
	end
	hl.dispatch(hl.dsp.window.move({ workspace = target, follow = false }))
end)
-- ── helpers ──────────────────────────────────────────────────────────────────

local function active_id()
	-- hl.get_active_workspace() is a native call: instant, no subprocess.
	local ws = hl.get_active_workspace()
	return ws and ws.id or 1
end

local function current_group()
	return math.floor((active_id() - 1) / SIZE)
end

local function current_sub()
	return ((active_id() - 1) % SIZE) + 1
end

-- ── navigation API ───────────────────────────────────────────────────────────

function sw.focus(sub)
	return function()
		hl.dispatch(hl.dsp.focus({ workspace = current_group() * SIZE + sub }))
	end
end

function sw.move(sub)
	return function()
		hl.dispatch(hl.dsp.window.move({ workspace = current_group() * SIZE + sub }))
	end
end

function sw.move_silent(sub)
	return function()
		hl.dispatch(hl.dsp.window.move({ workspace = current_group() * SIZE + sub, follow = false }))
	end
end

function sw.switch_group(n)
	return function()
		hl.dispatch(hl.dsp.focus({ workspace = (n - 1) * SIZE + current_sub() }))
	end
end

function sw.move_to_group(n)
	return function()
		hl.dispatch(hl.dsp.window.move({ workspace = (n - 1) * SIZE + 1 }))
	end
end

function sw.next_group(max_groups)
	max_groups = max_groups or 5
	return function()
		local g = (current_group() + 1) % max_groups
		hl.dispatch(hl.dsp.focus({ workspace = g * SIZE + current_sub() }))
	end
end

function sw.prev_group(max_groups)
	max_groups = max_groups or 5
	return function()
		local g = (current_group() - 1 + max_groups) % max_groups
		hl.dispatch(hl.dsp.focus({ workspace = g * SIZE + current_sub() }))
	end
end

function sw.focus_relative(delta)
	return function()
		local sub = math.max(1, math.min(SIZE, current_sub() + delta))
		hl.dispatch(hl.dsp.focus({ workspace = current_group() * SIZE + sub }))
	end
end

-- ── window routing ───────────────────────────────────────────────────────────
-- Replaces the Go daemon entirely. hl.on("window.open") fires with a HL.Window.
-- Moves new windows to the right sub-workspace within the currently active group.

local route_map = {
	["brave-browser"] = 2,
	["brave"] = 2,
	["firefox"] = 2,
	["chromium"] = 2,
	["vscodium"] = 1,
	["code"] = 1,
	["code-oss"] = 1,
	["godot"] = 1,
	["godot_editor"] = 1,
	["godot4"] = 1,
	["kitty"] = 3,
	["alacritty"] = 3,
	["foot"] = 3,
	["ghostty"] = 3,
}

hl.on("window.open", function(win)
	local sub = route_map[(win.class or ""):lower()]
	if not sub then
		return
	end

	local ws = hl.get_active_workspace()
	if not ws then
		return
	end

	local group = math.floor((ws.id - 1) / SIZE)
	local target = group * SIZE + sub

	-- Already on the right workspace, nothing to do
	if win.workspace and win.workspace.id == target then
		return
	end

	hl.dispatch(hl.dsp.window.move({ workspace = target, follow = false }))
end)

return sw
