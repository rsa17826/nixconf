{
  config,
  pkgs,
  lib,
  ...
}:
let
  zshPlugins = {
    zsh-autosuggestions = null;
    zsh-autopair = null;
    zsh-history-substring-search = null
    zsh-z = "share/zsh-z/zsh-z.plugin.zsh";
    zsh-forgit = "share/zsh-forgit/forgit.plugin.zsh";
    zsh-f-sy-h = "share/zsh/site-functions/f-sy-h.zsh";
    zsh-command-time = "share/zsh/plugins/command-time/command-time.plugin.zsh";
  };
in
{
  programs.pay-respects = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.nix-index.enable = true;
  programs.zsh = {
    dotDir = "${config.xdg.configHome}/zsh";
    enable = true;
    history.size = 10000;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    plugins = lib.mapAttrsToList (name: path: {
      name = name;
      src = pkgs.${name};
      file = if (path != null) then path else "share/${name}/${name}.zsh";
    }) zshPlugins;
    initContent = ''
      ZSH_COMMAND_TIME_COLOR="yellow"
      ZSH_COMMAND_TIME_MIN_SECONDS=3
      ZSH_COMMAND_TIME_ECHO=1
    '';
  };
}
