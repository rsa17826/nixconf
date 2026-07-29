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

      app = pkgs.writeShellApplication {
        name = name;
        bashOptions = [ ];
        inherit runtimeInputs;
        # We read the main script text, but prepend a helper variable pointing to $out
        text = ''
          SCRIPT_DATA_DIR="@out@/share/${name}"
          ${builtins.readFile scriptPath}
        '';
      };
    in
    if extraFiles == [ ] then
      app
    else
      app.overrideAttrs (old: {
        # Substitute @out@ with the actual final store path
        postInstall = (old.postInstall or "") + ''
          substituteInPlace $out/bin/${name} --subst-var-by out $out
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
