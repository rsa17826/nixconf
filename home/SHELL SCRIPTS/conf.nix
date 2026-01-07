{uname, pkgs, ...}
:
{
  home.packages = [
        (pkgs.writeShellScriptBin "er"
      (builtins.readFile ./er.sh))

  ];
}