m = {}

do
	local mod_map = {
		["#"] = "SUPER",
		["!"] = "ALT",
		["+"] = "SHIFT",
		["^"] = "CTRL",
		["enter"] = "RETURN",
		["\n"] = "RETURN",
		["esc"] = "ESCAPE",
		["spc"] = "SPACE",
		["ins"] = "INSERT",
		["kp0"] = "KP_0",
		["kp1"] = "KP_1",
		["kp2"] = "KP_2",
		["kp3"] = "KP_3",
		["kp4"] = "KP_4",
		["kp5"] = "KP_5",
		["kp6"] = "KP_6",
		["kp7"] = "KP_7",
		["kp8"] = "KP_8",
		["kp9"] = "KP_9",
		["/"] = "slash",
		["pgup"] = "code:104",
		["pgdown"] = "code:109",
	}

	local map_keys = {}
	for k in pairs(mod_map) do
		table.insert(map_keys, k)
	end
	table.sort(map_keys, function(a, b)
		return #a > #b
	end)

	function m.bind(keys, func, args)
		args = args or {}
		local mods = {}
		local key = ""
		local i = 1

		while i <= #keys do
			local found = false

			for _, trigger in ipairs(map_keys) do
				if keys:sub(i, i + #trigger - 1) == trigger then
					table.insert(mods, mod_map[trigger])
					i = i + #trigger
					found = true
					break
				end
			end

			if not found then
				-- This is the "raw" part of the keybind (the 't' in '#t')
				-- We take the rest of the string as the key
				key = keys:sub(i)
				break
			end
		end

		-- Join modifiers with " + "
		local mod_string = table.concat(mods, " + ")

		local final_output
		if #mods > 0 then
			final_output = mod_string .. "+ " .. key
		else
			final_output = key
		end

		-- print("Bound to: " .. final_output)
		-- allow hl bind
		hl.bind(final_output, func, args)
	end
end
