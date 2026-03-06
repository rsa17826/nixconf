{ lib, ... }:
let
  shellAliases = {
    udpate = "update";
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
    sd = "shutdown";
    reb = "reboot";
    cd = "z";
  };
  commonInit = ''
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
  '';

  # fishInit = ''
  #   set -gx DBUS_SESSION_BUS_ADDRESS "unix:path=/run/user/"(id -u)"/bus"
  # '';
in
{
  environment.shellAliases = shellAliases;
  programs = {
    bash = {
      enable = true;
      shellAliases = shellAliases;
      interactiveShellInit = commonInit;
    };
    zsh = {
      enable = true;
      shellAliases = shellAliases // {
        "#" = "echo";
      };
      interactiveShellInit = commonInit;
      initExtra = ''
        # Map the codes Kitty is sending to Zsh actions
        bindkey "\e[1;5D" backward-word
        bindkey "\e[1;5C" forward-word
        bindkey "\e[1;6D" backward-word # Shift variant
        bindkey "\e[1;6C" forward-word  # Shift variant
        bindkey '^H' backward-kill-word  # Ctrl+Backspace
        bindkey "\e[3;5~" kill-word      # Ctrl+Delete
      '';
    };
    # fish = {
    #   enable = true;
    #   shellAliases = lib.mapAttrs (_k: v: lib.strings.replaceStrings [ "|&" ] [ "&|" ] v) shellAliases;
    #   interactiveShellInit = fishInit;
    # };
  };
}
