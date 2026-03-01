{
  userConfig,
  config,
  pkgs,
  ...
}:
{
  # users.users."${userConfig.uname}" = {
  #   plugins = with pkgs; [
  #   ];
  # };
  programs.pay-respects = {
    enable = true;
    enableZshIntegration = true;
  };
  zsh-z = {
    enable = true;
  };
  programs.nix-index.enable = true;
  programs.zsh = {
    dotDir = "${config.xdg.configHome}/zsh";
    enable = true;

    # plugins = [
    #   (mkZshPlugin "zsh-abbr" pkgs.zsh-abbr)
    #   (mkZshPlugin "zsh-autosuggestions" pkgs.zsh-autosuggestions)
    #   (mkZshPlugin "zsh-syntax-highlighting" pkgs.)
    # ];
    history.size = 10000;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    plugins =
      map
        (pkg: {
          name = pkg.pname;
          src = pkg;
          file = "share/${pkg.pname}/${pkg.pname}.zsh";
        })
        (
          with pkgs;
          [
            zsh-syntax-highlighting
            zsh-autosuggestions
            zsh-forgit
            zsh-f-sy-h
            zsh-autopair
          ]
        );
  };
}
