{ userConfig, pkgs, ... }:
let
  mkZshPlugin = name: pkg: {
    inherit name;
    src = pkg;
    file = "share/${name}/${name}.zsh";
  };
in
{
  # users.users."${userConfig.uname}" = {
  #   plugins = with pkgs; [
  #   ];
  # };
  programs.zsh = {
    enable = true;

    plugins = [
      (mkZshPlugin "zsh-abbr" pkgs.zsh-abbr)
      (mkZshPlugin "zsh-autosuggestions" pkgs.zsh-autosuggestions)
      (mkZshPlugin "zsh-syntax-highlighting" pkgs.zsh-syntax-highlighting)
    ];
    history.size = 10000;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    plugins = [
      {
        name = "nix-shell";
        src = "${pkgs.zsh-nix-shell}/share/zsh-nix-shell";
      }
      {
        name = "you-should-use";
        src = "${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use";
      }
      {
        name = "zsh-vi-mode";
        src = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode";
      }
      {
        name = "zsh-z";
        src = "${pkgs.zsh-z}/share/zsh-z";
      }
    ];

  };
}
