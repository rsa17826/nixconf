{ pkgs, userConfig, ... }:
let
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      opencv4
      numpy
    ]
  );

  godot-dismiss = pkgs.writeShellApplication {
    name = "godot-dismiss";
    runtimeInputs = [
      pythonEnv
      pkgs.hyprland # provides hyprctl
      pkgs.grim
      pkgs.ydotool
    ];
    text = ''
      exec python3 ${./auto_dismiss_godot/main.py} ${./auto_dismiss_godot/ok_btn.png}
    '';
  };
in
{
  systemd.user.services.ydotoold = {
    description = "ydotool daemon";
    wantedBy = [ "default.target" ];
    serviceConfig = with pkgs; {
      ExecStart = "${ydotool}/bin/ydotoold";
      Restart = "always";
    };
  };

  systemd.user.services.godot-dismiss = {
    description = "Auto-dismiss Godot dialogs";
    after = [
      "graphical-session.target"
      "ydotoold.service"
    ];
    wants = [ "ydotool.service" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${godot-dismiss}/bin/godot-dismiss";
      Restart = "on-failure";
      RestartSec = "3s";
    };
  };
}
