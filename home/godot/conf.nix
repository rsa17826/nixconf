{ pkgs, userConfig, ... }:
let
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      opencv4
      numpy
    ]
  );

  godot-dismiss = pkgs.writeShellScriptBin "godot-dismiss" ''
    exec ${pythonEnv}/bin/python3 /home/${userConfig.uname}/nxiconf/godot/auto_dismiss_godot/main.py
  '';
in
{
  systemd.user.services.ydotoold = {
    Unit.Description = "ydotool daemon";
    Install.WantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.ydotool}/bin/ydotoold";
      Restart = "always";
    };
  };

  # The auto-dismiss service
  systemd.user.services.godot-dismiss = {
    Unit = {
      Description = "Auto-dismiss Godot dialogs";
      After = [
        "graphical-session.target"
        "ydotoold.service"
      ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${godot-dismiss}/bin/godot-dismiss";
      Restart = "on-failure";
      RestartSec = "3s";
    };
  };
}
