-- launcher.lua

-- Enter launcher submap
hl.bind("ALT + space", hl.dsp.submap("launcher"))

hl.define_submap("launcher", function()
  local function launch(cmd)
    return function()
      hl.dispatch(hl.dsp.exec_cmd(cmd))
      hl.dispatch(hl.dsp.submap("reset"))
    end
  end

  hl.bind("v", launch("codium"))
  hl.bind("b", launch("brave"))
  hl.bind("p", launch("kitty pwashare start"))
  hl.bind("g", launch("godot-newest"))
  hl.bind("s", launch("winspy"))
  hl.bind("a", launch("audioMover ~/audio ~/audio/output ~/syncthing/media/audio"))
  hl.bind("e", launch("thunar"))
  hl.bind("t", launch("kitty"))
  hl.bind("x", launch("xdm"))

  -- Exit on anything not matched
  hl.bind("catchall", hl.dsp.submap("reset"))
end)

-- Global launcher (works outside of submap too)
hl.bind("CTRL + SHIFT + SPACE", hl.dsp.exec_cmd("anyrun"))
