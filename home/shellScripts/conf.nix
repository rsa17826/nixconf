{ pkgs, ... }:

let
  # The directory to scan (current directory)
  baseDir = ./.;

  # Your existing script builder
  newsh = { name }: pkgs.writeShellScriptBin name (builtins.readFile (baseDir + "/${name}/main.sh"));

  # 1. Get all files/directories in the current folder
  # Returns a set: { "testpkg" = "directory"; "default.nix" = "regular"; ... }
  contents = builtins.readDir baseDir;

  # 2. Filter to find only directories that actually contain main.sh
  scriptNames = builtins.filter (
    name: contents.${name} == "directory" && builtins.pathExists (baseDir + "/${name}/main.sh")
  ) (builtins.attrNames contents);

in
{
  # 3. Map the list of names to your newsh function
  packages = map (name: newsh { inherit name; }) scriptNames;
}
