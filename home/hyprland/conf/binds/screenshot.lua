-- screenshot.lua

m.bind("+Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggleRec.sh"))
m.bind("^SHIFT + Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | tesseract - - stdout | wl-copy'))
m.bind("^SHIFT + F9", hl.dsp.exec_cmd("flashbackSaveAndOpen"))
m.bind("^F9", hl.dsp.exec_cmd("killall -SIGUSR1 gpu-screen-recorder"))
m.bind("^Print", hl.dsp.exec_cmd("hyprshot -m region --raw | satty --filename -"))

-- Clone view
m.bind("#G", hl.dsp.exec_cmd("~/.config/hypr/scripts/clone_view.sh"))

-- Toggle inwhi shader
m.bind("^!+/", hl.dsp.exec_cmd("shaderstack toggle inwhi"))
