{ pkgs, ... }:

let
  newsh = { name }: pkgs.writeShellScriptBin name (builtins.readFile (./${name}/main.sh));

  # Get all directories that contain a 'main.sh' file
  scriptDirs = builtins.filter (dir: builtins.isFile (dir + "/main.sh")) (builtins.attrNames ./.);

  # Generate a list of packages dynamically from these directories
  packages = builtins.map (dir: newsh { name = dir; }) scriptDirs;
in
{
  home.packages = packages;
}
