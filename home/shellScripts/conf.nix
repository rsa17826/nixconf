{
  uname,
  pkgs,
  lib,
  ...
}:
let 
  newsh = {
    name
  }:
  (pkgs.writeShellScriptBin name (builtins.readFile ./${name}/main.sh))
  ;
  in
{
  home.packages = [
    newsh {name="testpkg"}
    newsh {name="er"}
  ];
}

