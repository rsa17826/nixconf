{ lib, ... }:
let
  shellAliases = {
    udpate = "update";
    sd = "shutdown";
    vim = "nvim";
    vi = "nvim";
    nano = "nvim";
    "nix-env" = "echo wrong command";
    clearcache = "nix-collect-garbage";
    clearallcache = "sudo nix-collect-garbage --delete-older-than 15d";
    worm = "magic-wormhole send";
    hole = "magic-wormhole receive";
    q = "exit";
    c = "clear";
    nix-shell-alias = "nix-shell";
    repairStore = "sudo nix-store --verify --check-contents --repair";
    reb = "reboot";
  };
in
{
  environment.shellAliases = shellAliases;
  programs = {
    bash = {
      enable = true;
      shellAliases = shellAliases;
    };
    zsh = {
      enable = true;
      shellAliases = shellAliases;
    };
    fish = {
      enable = true;
      shellAliases = lib.mapAttrs (_k: v: lib.strings.replaceStrings [ "|&" ] [ "&|" ] v) shellAliases;
    };
  };
}
