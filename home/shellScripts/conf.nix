{ pkgs, userConfig, ... }:

let
  baseDir = ./.;

  # Optimized script builder
  newsh =
    name:
    let
      dir = baseDir + "/${name}";
      scriptPath = dir + "/main.sh";
      depsPath = dir + "/deps.nix";

      runtimeInputs = if builtins.pathExists depsPath then (import depsPath pkgs) else [ ];

      dirContents = builtins.readDir dir;
      extraFiles = builtins.attrNames (
        removeAttrs dirContents [
          "main.sh"
          "deps.nix"
        ]
      );

      rawScriptText = builtins.readFile scriptPath;
      usesDataDir = pkgs.lib.hasInfix "SCRIPT_DATA_DIR" rawScriptText;

      # Package extra files into a store path if any exist
      extraData =
        if extraFiles != [ ] then
          pkgs.runCommand "${name}-data" { } ''
            mkdir -p $out
            ${pkgs.lib.concatMapStringsSep "\n" (f: "cp -r ${dir}/${f} $out/${f}") extraFiles}
          ''
        else
          null;

      # Strip duplicate shebangs (e.g., #!/usr/bin/env bash) since writeShellApplication adds its own
      cleanScriptText =
        pkgs.lib.replaceStrings [ "#!/usr/bin/env bash\n" "#!/bin/bash\n" ] [ "" "" ]
          rawScriptText;
    in
    pkgs.writeShellApplication {
      inherit name runtimeInputs;
      bashOptions = [ ];
      text =
        if usesDataDir && extraData != null then
          ''
            SCRIPT_DATA_DIR="${extraData}"
            ${cleanScriptText}
          ''
        else
          cleanScriptText;
    };

  contents = builtins.readDir baseDir;

  scriptNames = builtins.filter (
    name: contents.${name} == "directory" && builtins.pathExists (baseDir + "/${name}/main.sh")
  ) (builtins.attrNames contents);

in
{
  users = {
    users = {
      "${userConfig.uname}" = {
        packages = map newsh scriptNames;
      };
    };
  };
}
