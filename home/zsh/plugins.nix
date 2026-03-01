{ pkgs, lib, ... }: # Ensure lib is in your arguments here
let
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

    # Use lib.mapAttrsToList instead of builtins
    plugins = lib.mapAttrsToList (name: path: {
      name = name;
      src = pkgs.${name};
      file = if (path != null) then path else "share/${name}/${name}.zsh";
    }) zshPlugins;
  };
}
