{ pkgs, ... }:
let
  # Define your plugins and their specific entry points here
  # If the plugin is "standard", we just set it to null or true
  zshPlugins = {
    zsh-syntax-highlighting = null;
    zsh-autosuggestions = null;
    zsh-autopair = null;
    zsh-z = "share/zsh-z/zsh-z.plugin.zsh";
    zsh-forgit = "share/zsh-forgit/forgit.plugin.zsh";
    zsh-f-sy-h = "share/zsh/site-functions/f-sy-h.zsh";
  };
in
{
  programs.zsh = {
    enable = true;

    plugins = builtins.mapAttrsToList (name: path: {
      name = name;
      src = pkgs.${name};
      # If a path is provided, use it; otherwise, use your standard fallback
      file = if (path != null) then path else "share/${name}/${name}.zsh";
    }) zshPlugins;
  };
}
