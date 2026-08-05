# { userConfig, pkgs, ... }:
# let
#   compiledShaders =
#     pkgs.runCommand "qsbar-compiled-shaders"
#       {
#         nativeBuildInputs = [ pkgs.kdePackages.qtshadertools ]; # Ensure 'qsb' is available here
#       }
#       ''
#         mkdir -p $out

#         # Copy everything from your source shaders directory
#         cp -r ${./bar/shaders}/* $out/

#         # Loop through and compile every .vert and .frag file found
#         for file in $out/*.{vert,frag}; do
#           if [ -f "$file" ]; then
#             # Run qsb compilation
#             qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 \
#                 -o "$file.qsb" "$file"
#           fi
#         done
#       '';
# in
# {
#   myProfile = {
#     editableConfigs = [
#       {
#         name = "qsbar";
#         src = ./bar;
#         srcStr = "${userConfig.nixConf}/home/quickshell/bar";
#         destDir = ".config/quickshell/bar";
#         files = [
#           "ClipHist.qml"
#           "Clock.qml"
#           "conf.nix"
#           "CountdownTimer.qml"
#           "CountdownTimerRow.qml"
#           "GithubNotif.qml"
#           "MediaProgress.qml"
#           "NotifBell.qml"
#           "NotifState.qml"
#           "NotifToast.qml"
#           "owoify.js"
#           "RecIndicator.qml"
#           "shell.qml"
#           "ShutdownCountdown.qml"
#           "Syncthing.qml"
#           "Time.qml"
#           "TimerServer.qml"
#           "Tray.qml"
#           "webserver.py"
#           "Wifi.qml"
#         ];
#         dirs = [
#           "shaders"
#         ];
#       }
#     ];
#   };
# }


# qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 \
#     -o shaders/recglitch.vert.qsb shaders/recglitch.vert
# qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 \
#     -o shaders/recglitch.frag.qsb shaders/recglitch.frag
