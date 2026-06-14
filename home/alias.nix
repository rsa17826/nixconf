{ ... }:
let
  shellAliases = {
    vim = "nvim";
    vi = "nvim";
    nano = "nvim";
    # "nix-env" = "echo wrong command";
    clearcache = "nix-collect-garbage";
    clearallcache = "sudo nix-collect-garbage --delete-older-than 15d";
    worm = "magic-wormhole send";
    hole = "magic-wormhole receive";
    q = "exit 0";
    "q!" = "kill -9 -$(ps -o sid= -p $$ | tr -d ' ') 2>/dev/null";
    c = "clear";
    nix-shell-alias = "nix-shell";
    repairStore = "sudo nix-store --verify --check-contents --repair";
    sd = "shutdown";
    reb = "reboot";
    la = "eza -la --icons --git --header --total-size";
    lt = "eza --tree --level=7 --icons --git --group-directories-first";
    ls = "eza -l --icons --git --header --color-scale --group-directories-first --time-style=relative";
    wiz = "ncdu"; # wiztree
    e = "codium";
    edir = "codium";
    updatec = "cd ~/nixconf ; (nix flake metadata | grep -oE 'ext-[a-zA-Z0-9_-]+'|xargs nix flake update) && pkill -9 codium ; update && codium && q";
    dea = "echo 'use flake' > .envrc && echo '.direnv' >> .gitignore && git rm -r --cached .direnv 2>/dev/null; direnv allow";
    "7z" = "7zz";
    # cd = "z";
  };
  interactiveShellInit = ''
    alias rm=gio trash
  '';
in
{
  environment = { inherit shellAliases; };
  programs = {
    dconf = {
      enable = true;
    };
    bash = {
      enable = true;
      shellAliases = shellAliases;
      interactiveShellInit = interactiveShellInit;
    };
    zsh = {
      enable = true;
      shellAliases = shellAliases;
      interactiveShellInit = interactiveShellInit;
    };
  };
}
