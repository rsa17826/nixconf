{ pkgs, userConfig, ... }:
{
  users = {
    users = {
      "${userConfig.uname}" = {
        packages = with pkgs; [
          (writeShellApplication {
            name = "decen-text";
            runtimeInputs = [ pkgs.deno ];
            text = ''
              exec deno run --no-remote --allow-read --allow-write ${./main.js} "$@"
            '';
          })
        ];
      };
    };
  };
}
