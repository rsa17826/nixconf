{ pkgs, userConfig, ... }:

let
  baseDir = ./.;

  # Optimized script builder
  newsh =
    name:
    let
      scriptPath = baseDir + "/${name}/main.sh";
      depsPath = baseDir + "/${name}/deps.nix";

      # Check if deps.nix exists, otherwise provide an empty list
      runtimeInputs = if builtins.pathExists depsPath then (import depsPath pkgs) else [ ];
    in
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      text = builtins.readFile scriptPath;
    };

  contents = builtins.readDir baseDir;

  scriptNames = builtins.filter (
    name: contents.${name} == "directory" && builtins.pathExists (baseDir + "/${name}/main.sh")
  ) (builtins.attrNames contents);

in
{
  users.users."${userConfig.uname}".packages = map newsh scriptNames;
}
