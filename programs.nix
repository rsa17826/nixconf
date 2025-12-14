{ pkgs, uname, ... }:
{
  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
      extraPkgs = pkgs: [
        pkgs.python312
        pkgs.python314
      ];
    };
  };
  programs = {
    zsh = {
      enable = true;
      shellAliases = {
        update = "sudo echo a && cd /home/${uname}/nixconf && push ; cd - && sudo nixos-rebuild switch --flake ~/nixconf#${uname} --impure";
        udpate = "update";
        push = "git add -A && git commit -m a && git push";
        vim = "nvim";
        "nix-env" = "echo wrong command";
        clearcache = "nix-collect-garbage";
      };
    };
    hyprland = {
      enable = true;
    };
    firefox = {
      enable = true;
    };
  };

  users.users."${uname}" = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "${uname}";
    extraGroups = [
      "networkmanager"
      "wheel"
      "opensnitch"
    ];
    packages = with pkgs; [
      kdePackages.kate
      typos
      keepass
      python313
      python313Packages.py7zr
      godot
      appimage-run
      firejail
      motrix
      nix-tree
      kid3
      yt-dlp
      syncthingtray
      syncthing
      mp3gain
      vscodium
      python314
      eww
      anyrun
      # https://github.com/anyrun-org/anyrun
      # ulauncher
    ];
  };
  environment.systemPackages = with pkgs; [
    neovim
    # vim
    sxhkd
    wget
    brave
    nixfmt-rfc-style
    git
    kdePackages.kget
    p7zip
    nix-ld
    kitty
    # rofi
    albert
    waybar
    keyd
    # xmodmap
  ];
}
