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
        update = "cd /home/${uname}/nixconf && push ; cd - && sudo nixos-rebuild switch --flake ~/nixconf#${uname} --impure";
        udpate = "update";
        push = "git add -A && git commit -m a && git push";
        vim = "nvim";
        "nix-env" = "echo wrong command";
        clearcache = "nix-collect-garbage";
        clearallcache = "sudo nix-collect-garbage --delete-older-than 3d";
      };
    };
    hyprland = {
      enable = true;
    };
    firefox = {
      enable = true;
    };
  };
  nix-shell = {
    shellHook = ''
      alias nix-env='echo "nix-env is deprecated; use nix profile"'
    '';
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
      typos # spellchecker
      typos-lsp
      keepass # password manager
      python313
      python313Packages.py7zr
      godot # programing
      appimage-run
      firejail
      motrix # download manager
      nix-tree
      kid3 # audio tagger
      yt-dlp # downloader
      syncthingtray
      syncthing # file sync
      mp3gain # audio volume normilizer
      python314
      eww # status bar
      filen-desktop # cloud storage
      javaPackages.compiler.temurin-bin.jre-25 # for running java apps
      file # like die
      opensnitch-ui # firewall
      vscodium # text editor
      wineWowPackages.unstableFull # windows apps
      autokey
      espanso-wayland # typo correction
      unixtools.watch # watch cmd
      htop # process info
      # htop-vim
      vlc # media player
      nicotine-plus # soulseek
      # https://github.com/anyrun-org/anyrun
      # ulauncher
    ];
  };
  environment.systemPackages = with pkgs; [
    neovim
    # vim
    sxhkd
    wget
    brave # web browser
    nixfmt-rfc-style # nix language formatter
    git # git is required
    kdePackages.kget
    p7zip # archival tool
    nix-ld
    kitty # terminal emulator
    # rofi
    # albert
    waybar
    keyd # disables capslock?
    anyrun # application launcher
    # xmodmap
  ];
}
