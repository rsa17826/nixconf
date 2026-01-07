{
  uname,
  pkgs,
  lib,
  ...
}:
{
  home.packages = [
    (pkgs.writeShellScriptBin "er" (builtins.readFile ./er.sh))
  ];
}
