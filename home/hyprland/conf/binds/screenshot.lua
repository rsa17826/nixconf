-- screenshot.lua
m.bind("print", hl.dsp.exec_cmd("hyprshot -m window"))

m.bind("+Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggleRec.sh"))
m.bind("^SHIFT + Print", hl.dsp.exec_cmd("screenshot | tesseract - - stdout | wl-copy"))
m.bind("^SHIFT + F9", hl.dsp.exec_cmd("flashbackSaveAndOpen"))
m.bind("^F9", hl.dsp.exec_cmd("flashbackSaveDontOpen"))
m.bind("CTRL + PRINT", hl.dsp.exec_cmd("screenshot | satty --filename -"))

-- Clone view
m.bind("#G", hl.dsp.exec_cmd("~/.config/hypr/scripts/clone_view.sh"))

-- Toggle inwhi shader
m.bind("^!+/", hl.dsp.exec_cmd("shaderstack toggle inwhi"))
