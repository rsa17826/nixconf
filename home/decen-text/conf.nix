{ pkgs, userConfig, ... }:
{
  users = {
    users = {
      "${userConfig.uname}" = {
        packages = with pkgs; [
          writeShellApplication
          {
            name = "decen-text";
            runtimeInputs = with pkgs; [
              deno
            ];
            text = ''
              exec deno run --allow-read --allow-write ${./main.js} "$@"
            '';
          }
        ];
      };
    };
  };
}
