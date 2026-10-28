{
  pkgs,
  inputs,
  ln,
  userConfig,
  ...
}:
{
  imports = [
    ./extensions/githubAndLocal.nix
    ./extensions/marketplace.nix
  ];
  programs = {
    vscodium = {
      enable = true;
      mutableExtensionsDir = false;
      package = (
        (inputs.vscodium.legacyPackages.${pkgs.stdenv.hostPlatform.system}.vscodium).override {
          commandLineArgs = "--password-store=basic --enable-blink-features=MiddleClickAutoscroll";
        }
      );
    };
  };
  # Use the full XDG path so VSCodium actually sees them
  xdg.configFile."VSCodium/User/settings.json".source =
    ln "${userConfig.nixConf}/home/vscode/settings.json";
  xdg.configFile."VSCodium/User/keybindings.json".source =
    ln "${userConfig.nixConf}/home/vscode/keybindings.json";
  xdg.configFile."VSCodium/User/replace.regex".source =
    ln "${userConfig.nixConf}/home/vscode/replace.regex";
  # home.activation.copy-vscode-settings = ''
  #   echo "Copying VSCode settings..."
  #   mkdir -p "$HOME/.config/VSCodium/User"
  #   ln -f ${./settings.json} "$HOME/.config/VSCodium/User/settings.json"
  #   ln -f ${./keybindings.json} "$HOME/.config/VSCodium/User/keybindings.json"
  # '';
  # language jsonc
  home.file.".vscode-oss/argv.json".text = ''
    {
      "enable-crash-reporter": false,
      "crash-reporter-id": "RANDOM UUID HERE",
      "locale": "en",
      "password-store": "basic"
    }
  '';
  # "locale": "furry-owo",
}
