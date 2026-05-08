-- screenshot.lua

local mainMod = "SUPER"

hl.bind("SHIFT + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggleRec.sh"))
hl.bind("CTRL + SHIFT + Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | tesseract - - stdout | wl-copy'))
hl.bind("CTRL + SHIFT + F9", hl.dsp.exec_cmd("flashbackSaveAndOpen"))
hl.bind("CTRL + F9", hl.dsp.exec_cmd("killall -SIGUSR1 gpu-screen-recorder"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("hyprshot -m region --raw | satty --filename -"))

-- Clone view
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("~/.config/hypr/scripts/clone_view.sh"))

-- Toggle inwhi shader
hl.bind("CTRL + ALT + SHIFT + slash", hl.dsp.exec_cmd("shaderstack toggle inwhi"))
