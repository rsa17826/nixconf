{
  pkgs,
  userConfig,
  ln,
  ...
}:
{
  nixpkgs.overlays = [
    (import ./overlays/dokiTheme/conf.nix)
    (import ./overlays/owoify/conf.nix)
    (import ./overlays/toLocaleStringFix/conf.nix)
    (import ./overlays/updateHash/conf.nix)
  ];
  imports = [
    ./extensions/githubAndLocal.nix
    ./extensions/marketplace.nix
  ];
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    mutableExtensionsDir = false;

    # profiles.default = {
    #   # extensions =
    #   #   with pkgs.vscode-extensions;
    #   #   [
    #   #     # (dlExt {
    #   #     #   name = "nix-embedded-languages";
    #   #     #   version = "1.0.1";
    #   #     #   publisher = "coopmoney";
    #   #     #   domain = "openvsx.eclipsecontent.org";
    #   #     # })
    #   #   ]
    # };
  };
  home.file."VSCodium/User/settings.json".source = ln ./settings.json;
  home.file."VSCodium/User/keybindings.json".source = ln ./keybindings.json;

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
# Cannot activate da 'C/C++ Runner' extension because it depends on an unknown 'ms-vscode.cpptools' extension .
