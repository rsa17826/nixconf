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
      app = pkgs.writeShellApplication {
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
      app
    else
      app.overrideAttrs (old: {
        # Using postInstall check hook to safely modify binary and copy assets
        postInstall = (old.postInstall or "") + ''
          ${pkgs.lib.optionalString usesDataDir ''
            # Substitute @out@ inside the generated executable script
            ${pkgs.gnused}/bin/sed -i "s|@out@|$out|g" "$out/bin/${name}"
          ''}

          ${pkgs.lib.optionalString (extraFiles != [ ]) ''
            mkdir -p "$out/share/${name}"
            ${pkgs.lib.concatMapStringsSep "\n" (f: "cp -r ${dir}/${f} $out/share/${name}/${f}") extraFiles}
          ''}
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
