-- screenshot.lua
m.bind("print", hl.dsp.exec_cmd("hyprshot -m window"))

m.bind("+Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggleRec.sh"))
m.bind("^+Print", hl.dsp.exec_cmd("screenshot | tesseract - - stdout | wl-copy"))
m.bind("^+F9", hl.dsp.exec_cmd("flashbackSaveAndOpen"))
m.bind("^F9", hl.dsp.exec_cmd("flashbackSaveDontOpen"))
m.bind("CTRL + PRINT", hl.dsp.exec_cmd("screenshot | satty --filename -"))

-- Clone view
m.bind("#G", hl.dsp.exec_cmd("~/.config/hypr/scripts/clone_view.sh"))
m.bind("^!pgup", hl.dsp.exec_cmd('kill -SIGUSR2 "$(cat /tmp/gsr_stream.pid)"'))

-- Toggle inwhi shader
m.bind("^!+/", hl.dsp.exec_cmd("shaderstack toggle inwhi"))
