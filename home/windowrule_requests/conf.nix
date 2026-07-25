{
  pkgs,
  userConfig,
  ...
}:
let
  pythonEnv = pkgs.python314.withPackages (ps: [ ps.pygobject3 ]);
in
{
  systemd = {
    user = {
      services = {
        windowrule-daemon = {
          wantedBy = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          path = [ pkgs.libnotify ];
          serviceConfig = {
            ExecStart = "${pythonEnv}/bin/python3 ${./windowrule_daemon.py}";
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
          (pkgs.writeShellScriptBin ./request_windowrule.sh)
        ];
      };
    };
  };
}
