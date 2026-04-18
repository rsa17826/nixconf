{ pkgs, userConfig, ... }:
let
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      opencv4
      numpy
    ]
  );

  godot-dismiss = pkgs.writeShellScriptBin "godot-dismiss" ''
    exec ${pythonEnv}/bin/python3 ${./auto_dismiss_godot/main.py}
  '';
in
{
  systemd.user.services.ydotoold = {
    description = "ydotool daemon";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.ydotool}/bin/ydotoold";
      Restart = "always";
    };
  };

  systemd.user.services.godot-dismiss = {
    description = "Auto-dismiss Godot dialogs";
    after = [
      "graphical-session.target"
      "ydotoold.service"
    ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${godot-dismiss}/bin/godot-dismiss";
      Restart = "on-failure";
      RestartSec = "3s";
    };
  };
}
