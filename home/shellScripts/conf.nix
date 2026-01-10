{ pkgs, ... }:

let
  newsh = { name }: pkgs.writeShellScriptBin name (builtins.readFile (./${name}/main.sh));
in
{
  home.packages = [
    (newsh { name = "testpkg"; })
    (newsh { name = "er"; })
    (newsh { name = "github-widget"; })
    (
      newsh { name = "githubNotifications"; }
      // {
        owner = "root";
        group = "root";
        mode = "0500"; # root-only execute
      }
    )
  ];
}
