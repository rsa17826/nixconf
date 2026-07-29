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

      # Create the base shell application
      baseApp = pkgs.writeShellApplication {
        inherit name runtimeInputs;
        bashOptions = [ ];
        text =
          if usesDataDir then
            ''
              SCRIPT_DATA_DIR="@out@/share/${name}"
              ${rawScriptText}
            ''
          else
            rawScriptText;
      };
    in
    if extraFiles == [ ] && !usesDataDir then
      baseApp
    else
      pkgs.runCommand name { } ''
        # Copy the original script application structure
        cp -r ${baseApp}/* $out/
        chmod -R +w $out

        # Replace @out@ placeholder with the real store path of this wrapped derivation
        if [ -f "$out/bin/${name}" ]; then
          substituteInPlace "$out/bin/${name}" --subst-var-by out "$out"
        fi

        # Copy extra directories and files to $out/share/<name>/
        mkdir -p $out/share/${name}
        ${pkgs.lib.concatMapStringsSep "\n" (f: "cp -r ${dir}/${f} $out/share/${name}/${f}") extraFiles}
      '';

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
