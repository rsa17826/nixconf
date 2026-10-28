{
  userConfig,
  ...
}:
{
  nixpkgs = {
    overlays = [
      (import ./overlays/dokiTheme/conf.nix)
      (import ./overlays/owoify/conf.nix)
      (import ./overlays/focusFollowsMouse/conf.nix)
      ((import ./overlays/customFolderIcons/conf.nix) userConfig)
      (import ./overlays/toLocaleStringFix/conf.nix)
      # (import ./overlays/pythonSmallSpaces/conf.nix)
      (import ./overlays/updateHash/conf.nix)
    ];
  };
}
