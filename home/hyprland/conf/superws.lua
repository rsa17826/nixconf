-- superws.lua

local sw = {}

local SIZE = 10
local TAG_PREFIX = "sw." -- prefix for auto-generated rule tags

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
	local g = (s == 0) and current_group() or (s - 1)
	local b = (sub == 0) and current_sub() or sub
	return g * SIZE + b
end

local function has_tag(win, tag)
	local t = win.tags
	if type(t) == "string" then
		-- tags may arrive as a space-separated string
		for word in t:gmatch("%S+") do
			if word == tag then
				return true
			end
		end
	elseif type(t) == "table" then
		for _, v in ipairs(t) do
			if v == tag then
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
-- sw.window_rule(spec) registers a rule.
--
-- Matching uses Hyprland's native regex engine via hl.window_rule — full regex
-- including alternation (|), groups, lookaheads all work.
--
-- spec.match fields (all optional, all regex strings unless noted):
--   class    string   Hyprland regex against WM_CLASS
--   title    string   Hyprland regex against window title
--   float    bool     match floating state
--   group    int      only fire in this super-group (1-based), 0 = any
--
-- spec fields:
--   workspace  {super, sub}   where to send the window
--                             0 in either slot means "current"
--                             {0,0} = don't move (exec-only rule)
--   follow     bool           focus follows window after move (default false)
--   exec       string         shell command to run on match
--
-- workspace notation:
--   {0,1}  same group,  sub-ws 1
--   {1,0}  group 1,     same sub-ws
--   {2,3}  group 2,     sub-ws 3
--   {0,0}  no move

local _rules = {} -- { tag, spec } entries in registration order

-- Try to register the tag effect via hl.window_rule.
-- HL.WindowRuleSpec doesn't document `tag` but Hyprland's engine supports it;
-- if this throws, fall through to the hyprctl fallback below.
local function register_native(match, tag)
	local ok = pcall(function()
		hl.window_rule({
			name = tag,
			match = match,
			tag = "+" .. tag, -- dynamic effect: set tag on matching windows
		})
	end)
	return ok
end
sw.window_rule({
	match = { title = "^HyprSpy$" },
	pin = true,
	float = true,
	workspace = { 1, 0 },
})
-- Fallback: inject a classic windowrule via hyprctl for one match field.
-- Supports class and title. float/group are handled in the event handler.
local function register_hyprctl(match, tag)
	local function add(field, value)
		-- hyprctl keyword windowrule "tag +sw.1, class:^codium$"
		local cmd = string.format("hyprctl keyword windowrule 'tag +%s, %s:%s'", tag, field, value)
		hl.dispatch(hl.dsp.exec_cmd(cmd))
	end

	if match.class then
		add("class", match.class)
	end
	if match.title then
		add("title", match.title)
	end
end

function sw.window_rule(spec)
	local idx = #_rules + 1
	local tag = TAG_PREFIX .. idx
	table.insert(_rules, { tag = tag, spec = spec })

	local match = {}
	for k, v in pairs(spec.match or {}) do
		if k ~= "float" and k ~= "group" then
			match[k] = v
		end
	end

	-- forward static effects to hl.window_rule
	local effects = { match = spec.match }
	local effect_keys = { "pin", "float", "opacity", "animation", "border_color", "idle_inhibit", "stay_focused" }
	for _, k in ipairs(effect_keys) do
		if spec[k] ~= nil then
			effects[k] = spec[k]
		end
	end
	hl.window_rule(effects)

	if not register_native(match, tag) then
		register_hyprctl(match, tag)
	end
end
-- ── window.open handler ──────────────────────────────────────────────────────

hl.on("window.open", function(win)
	-- read the tags table
	local tags = type(win.tags) == "table" and table.concat(win.tags, ", ") or tostring(win.tags)

	hl.dispatch(hl.dsp.exec_cmd("notify-send '" .. win.class .. " tags=[" .. tags .. "]'"))

	-- catch the notification error instead of silently dying
	-- local ok, err = pcall(function()
	-- 	hl.notification.create({ text = "test", timeout = 3 })
	-- end)
	-- if not ok then
	-- 	hl.dispatch(hl.dsp.exec_cmd("notify-send 'notif err: " .. tostring(err) .. "'"))
	-- end
end)

return sw
