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

      # Read script text into a variable
      rawScriptText = builtins.readFile scriptPath;

      # Check if SCRIPT_DATA_DIR is referenced anywhere in main.sh
      usesDataDir = pkgs.lib.hasInfix "SCRIPT_DATA_DIR" rawScriptText;

      # Only prepend SCRIPT_DATA_DIR definition if used in the script
      scriptText =
        if usesDataDir then
          ''
            SCRIPT_DATA_DIR="@out@/share/${name}"
            ${rawScriptText}
          ''
        else
          rawScriptText;

      app = pkgs.writeShellApplication {
        inherit name runtimeInputs;
        bashOptions = [ ];
        text = scriptText;
      };
    in
    if extraFiles == [ ] then
      app
    else
      app.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          ${pkgs.lib.optionalString usesDataDir ''
            substituteInPlace $out/bin/${name} --subst-var-by out $out
          ''}
          mkdir -p $out/share/${name}
          ${pkgs.lib.concatMapStringsSep "\n" (f: "cp -r ${dir}/${f} $out/share/${name}/${f}") extraFiles}
        '';
      });

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
