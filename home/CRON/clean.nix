{
  pkgs,
  uname,
  ...
}:

let
  cleanupScript = pkgs.writeShellScriptBin "cleanup-script" (builtins.readFile ./clean.sh);
in
{
  systemd.timers.cleanup = {
    description = "Check for old files";
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "daily";
  };

  systemd.services.cleanup = {
    description = "Cleanup old files";
    serviceConfig = {
      ExecStart = "${cleanupScript}/bin/cleanup-script";
      Type = "oneshot";
    };
  };

  users.users."${uname}".packages = [ cleanupScript ];
}
