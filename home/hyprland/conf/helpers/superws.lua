sw = {}

local SIZE = 10
local TAG_PREFIX = "sw."

-- ── helpers ──────────────────────────────────────────────────────────────────

local function active_id()
	local ws = hl.get_active_workspace()
	return ws and ws.id or 1
end

local function current_group()
	return math.floor((active_id() - 1) / SIZE)
end

local function current_sub()
	return ((active_id() - 1) % SIZE) + 1
end

local function resolve_ws(spec)
	if not spec then
		return nil
	end
	local s, sub = spec[1], spec[2]
	if s == 0 and sub == 0 then
		return nil
	end

	-- IF s == 0, use current_group() directly (which is 0-indexed)
	-- IF s >= 1, subtract 1 to convert your 1-indexed rule into 0-indexed math
	local g = (s == 0) and current_group() or (s - 1)

	local b = (sub == 0) and current_sub() or sub
	return g * SIZE + b
end

local function has_tag(win, tag)
	local t = win.tags
	if type(t) == "string" then
		for word in t:gmatch("%S+") do
			if word == tag or word == tag .. "*" then
				return true
			end
		end
	elseif type(t) == "table" then
		for _, v in ipairs(t) do
			local bare = v:sub(-1) == "*" and v:sub(1, -2) or v
			if bare == tag then
				return true
			end
		end
	end
	return false
end

-- ── navigation ───────────────────────────────────────────────────────────────

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

-- ── window rule system ───────────────────────────────────────────────────────
--
-- sw.window_rule(spec)
--
-- spec.match  (all optional, Hyprland regex):
--   class    string
--   title    string
--   float    bool     Lua-side check (not passed to Hyprland)
--   group    int      only fire in this super-group (1-based), 0 = any
--
-- spec:
--   workspace  {super, sub}  0 = current in that slot, {0,0} = don't move
--   follow     bool          focus follows window (default false)
--   exec       string        shell command (run async via exec_cmd)
--
-- static effects forwarded directly to hl.window_rule:
--   pin, opacity, animation, border_color, idle_inhibit, stay_focused
--   float (when used as an effect, not a match condition — put in spec not match)

local _rules = {}
local _effect_keys = {
	"pin",
	"opacity",
	"animation",
	"border_color",
	"idle_inhibit",
	"stay_focused",
	"float",
}

local function register_native(match, tag)
	local ok = pcall(function()
		hl.window_rule({ name = tag, match = match, tag = "+" .. tag })
	end)
	return ok
end

-- local function register_hyprctl(match, tag)
-- 	local function add(field, value)
-- 		local cmd = string.format("hyprctl keyword windowrule 'tag +%s, %s:%s'", tag, field, value)
-- 		os.execute(cmd) -- fine here: config load time, not inside an event
-- 	end
-- 	if match.class then
-- 		add("class", match.class)
-- 	end
-- 	if match.title then
-- 		add("title", match.title)
-- 	end
-- end

function sw.window_rule(spec)
	if not spec.workspace or spec.workspace == "special" then
		hl.window_rule(spec)
		return
	end
	local idx = #_rules + 1
	local tag = TAG_PREFIX .. idx
	table.insert(_rules, { tag = tag, spec = spec })

	-- strip Lua-side match keys before passing to Hyprland
	local match = {}
	for k, v in pairs(spec.match or {}) do
		if k ~= "float" and k ~= "group" then
			match[k] = v
		end
	end

	-- forward static effects to hl.window_rule
	local effects = { match = spec.match }
	for _, k in ipairs(_effect_keys) do
		if spec[k] ~= nil then
			effects[k] = spec[k]
		end
	end
	pcall(hl.window_rule, effects) -- pcall: silently skip unknown effect keys

	register_native(match, tag)
	-- if not register_native(match, tag) then
	-- 	-- register_hyprctl(match, tag)
	-- end
end

-- ── window.open handler ──────────────────────────────────────────────────────
-- IMPORTANT: never use os.execute inside a compositor event — it blocks the
-- main thread and freezes Hyprland. Use hl.dispatch(hl.dsp.exec_cmd(...)).

hl.on("window.open", function(win)
	local tags = type(win.tags) == "table" and table.concat(win.tags, ", ") or tostring(win.tags)
	hl.dispatch(hl.dsp.exec_cmd("notify-send '" .. win.class .. " tags=[" .. tags .. "]'"))

	for _, entry in ipairs(_rules) do
		hl.dispatch(hl.dsp.exec_cmd("notify-send 'checking " .. entry.tag .. "'"))
		if has_tag(win, entry.tag) then
			-- ← if you see this notify, has_tag matched
			hl.dispatch(hl.dsp.exec_cmd("notify-send 'MATCHED " .. entry.tag .. "'"))

			local spec = entry.spec
			if spec.exec then
				hl.dispatch(hl.dsp.exec_cmd(spec.exec))
			end
			-- hl.dispatch(hl.dsp.exec_cmd("notify-send 'ws is set to " .. table.concat(spec.workspace, ",") .. "'"))
			local target = resolve_ws(spec.workspace)
			if not target then
				goto continue
			end
			hl.dispatch(
				hl.dsp.exec_cmd(
					"notify-send 'target="
						.. tostring(target)
						.. " winws="
						.. tostring(win.workspace and win.workspace.id)
						.. "'"
				)
			)

			if target and not (win.workspace and win.workspace.id == target) then
				-- target the window by address instead of relying on focus
				hl.dispatch(
					hl.dsp.exec_cmd(
						string.format(
							"hyprctl dispatch movetoworkspacesilent %d,address:%s",
							target,
							tostring(win.address)
						)
					)
				)
			end
			return
		end
		::continue::
	end
end)
-- local function notify(msg)
--   hl.dispatch(hl.dsp.exec_cmd("notify-send '" .. win.class .. " tags=[" .. tags .. "]'")
-- end
sw.window_rule({
	match = { title = "^HyprSpy$" },
	workspace = { 0, 0 },
	pin = true,
	float = true,
})
