{
  lib,
  pkgs,
  userConfig,
  ...
}:
{
  systemd = {
    user = {
      services = {
        macro-recorder = {
          wantedBy = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          path = with pkgs; [
            python314Packages.pygobject3
            libnotify
          ];

          serviceConfig = {
            ExecStart = ./windowrule_daemon.py;
            Restart = "on-failure";
            RestartSec = "5s";
            KillMode = "mixed";
          };
        };
      };
    };
    # timers = {
    #   nix-custom-gc = {
    #     wantedBy = [ "timers.target" ];
    #     timerConfig = {
    #       OnCalendar = "daily";
    #       Persistent = true;
    #     };
    #   };
    # };
  };
  users = {
    users = {
      "${userConfig.uname}" = {
        packages = [
          (lib.writeShellScriptBin ./request_windowrule.sh)
        ];
      };
    };
  };
}
