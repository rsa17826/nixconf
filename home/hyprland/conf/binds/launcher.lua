-- launcher.lua

-- Enter launcher submap
m.bind("!space", hl.dsp.submap("launcher"))

hl.define_submap("launcher", function()
	local function launch(cmd)
		return function()
			hl.dispatch(hl.dsp.exec_cmd(cmd))
			hl.dispatch(hl.dsp.submap("reset"))
		end
	end

	m.bind("v", launch("codium"))
	m.bind("b", launch("brave"))
	m.bind("p", launch("kitty pwashare start"))
	m.bind("g", launch("godot-newest"))
	m.bind("s", launch("winspy"))
	m.bind("a", launch("audioMover ~/audio ~/audio/output ~/syncthing/media/audio"))
	m.bind("e", launch("thunar"))
	m.bind("t", launch("kitty"))
	m.bind("x", launch("xdm"))

	-- Exit on anything not matched
	m.bind("catchall", hl.dsp.submap("reset"))
end)

-- Global launcher (works outside of submap too)
m.bind("^+spc", hl.dsp.exec_cmd("rofi-launcher"))
