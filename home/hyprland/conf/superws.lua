-- superws.lua
-- Super-workspace navigation module.
--
-- Real workspaces are grouped into blocks of SIZE.
-- Group 1 → ws 1..SIZE,  Group 2 → ws SIZE+1..SIZE*2, etc.
--
-- Usage (in binds.lua):
--   local sw = require("superws")
--
--   m.bind("#a",   sw.focus(1))          -- go to sub-ws 1 of current group
--   m.bind("#+a",  sw.move(1))           -- throw window to sub-ws 1 of current group
--   m.bind("!#1",  sw.switch_group(1))   -- jump to group 1, keep sub-ws position
--   m.bind("!#+1", sw.move_to_group(1))  -- throw window to group 1

local sw = {}

local SIZE = 10 -- workspaces per group; must match groupSize in main.go

-- ── helpers ──────────────────────────────────────────────────────────────────

local function current_group()
	return math.floor((hl.get_active_workspace() - 1) / SIZE)
end

local function current_sub()
	return ((hl.get_active_workspace() - 1) % SIZE) + 1
end

-- ── public API ───────────────────────────────────────────────────────────────

--- Focus sub-workspace `sub` within the current group.
function sw.focus(sub)
	return function()
		local target = current_group() * SIZE + sub
		hl.dsp.focus({ workspace = target })()
	end
end

--- Move the active window to sub-workspace `sub` within the current group.
function sw.move(sub)
	return function()
		local target = current_group() * SIZE + sub
		hl.dsp.window.move({ workspace = target })()
	end
end

--- Move silently (window moves, focus stays).
function sw.move_silent(sub)
	return function()
		local target = current_group() * SIZE + sub
		hl.dsp.window.move({ workspace = target, follow = false })()
	end
end

--- Switch to group `n` (1-based), preserving the current sub-workspace slot.
function sw.switch_group(n)
	return function()
		local target = (n - 1) * SIZE + current_sub()
		hl.dsp.focus({ workspace = target })()
	end
end

--- Move the active window to group `n` (1-based), sub-ws 1.
function sw.move_to_group(n)
	return function()
		local target = (n - 1) * SIZE + 1
		hl.dsp.window.move({ workspace = target })()
	end
end

--- Cycle to the next group, wrapping after `max_groups`.
function sw.next_group(max_groups)
	max_groups = max_groups or 5
	return function()
		local next_g = (current_group() + 1) % max_groups
		local target = next_g * SIZE + current_sub()
		hl.dsp.focus({ workspace = target })()
	end
end

--- Cycle to the previous group.
function sw.prev_group(max_groups)
	max_groups = max_groups or 5
	return function()
		local prev_g = (current_group() - 1 + max_groups) % max_groups
		local target = prev_g * SIZE + current_sub()
		hl.dsp.focus({ workspace = target })()
	end
end

--- Move relatively within the current group's sub-workspaces.
--- `delta` is +1 (forward) or -1 (backward), clamped to [1, SIZE].
function sw.focus_relative(delta)
	return function()
		local sub = math.max(1, math.min(SIZE, current_sub() + delta))
		local target = current_group() * SIZE + sub
		hl.dsp.focus({ workspace = target })()
	end
end

return sw

