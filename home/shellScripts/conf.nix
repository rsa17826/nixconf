{ pkgs, ... }:

let
  newsh = { name }: pkgs.writeShellScriptBin name (builtins.readFile (./${name}/main.sh));
in
{
  home.packages = [
    (newsh { name = "testpkg"; })
    (newsh { name = "er"; })
    ({
      inherit newsh { name = "github-widget"; };
      owner = "root";
    group = "root";
    mode = "0500";  # root-only execute
})
  ];
  environment.etc."mysecrets/github_token.env" = {
    source = "/etc/mysecrets/github_token.env"; # do not overwrite
    owner = "root";
    group = "root";
    mode = "0400"; # root-only read
  };
}
