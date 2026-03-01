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
    plugins = [
      {
        name = "zsh-z";
        src = pkgs.zsh-z;
        file = "share/zsh-z/zsh-z.plugin.zsh"; # This is the specific path for this pkg
      }
    ]
    ++
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
