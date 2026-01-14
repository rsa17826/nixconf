{
  pkgs,
  uname,
  lib,
  ...
}:
let
  updateCommand = "cd /home/${uname}/nixconf && push ; cd - && sudo nixos-rebuild switch --flake ~/nixconf#${uname} --impure |& nom";
  shellAliases = {
    update = updateCommand;
    udpate = "update";
    push = "git add -A && git commit -m a && git push";
    vim = "nvim";
    vi = "nvim";
    nano = "nvim";
    "nix-env" = "echo wrong command";
    clearcache = "nix-collect-garbage";
    clearallcache = "sudo nix-collect-garbage --delete-older-than 3d";
    worm = "magic-wormhole send";
    hole = "magic-wormhole receive";
    q = "exit";
    c = "clear";
    nix-shell-alias = "nix-shell";
  };
in
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
    hyprland = {
      enable = true;
    };
    firefox = {
      enable = true;
    };
  };

  users.users."${uname}" = {
    shell = pkgs.fish;
    # shell = pkgs.zsh;
    isNormalUser = true;
    description = "${uname}";
    extraGroups = [
      "networkmanager"
      "wheel"
      "opensnitch"
      "input"
    ];
    packages = with pkgs; [
      # TODO
      quickshell # widget thing
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
      yt-dlp # media downloader
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
      # autokey # x11 only
      unixtools.watch # watch cmd
      htop # process info
      # htop-vim
      mission-center # task manager
      vlc # media player
      nicotine-plus # soulseek
      conky # like rainmeter
      wl-clipboard # clipboard cli tool
      # wl-clipboard-rs # what is the difference?
      wl-clicker # autoclicker
      # see if can change to scrolllock/z
      magic-wormhole # file transfer
      jq # json parser
      nil # nix language server
      # testing
      cascadia-code # font
      texlivePackages.cascadiamono-otf
      gpu-screen-recorder # screen recorder
      lutris-free
      faugus-launcher
      # thunar # wiztree
      # bottles
      # https://github.com/anyrun-org/anyrun
      # ulauncher
      qt6.qtdeclarative
    ];
  };
  environment.systemPackages = with pkgs; [
    neovim # tui text editor
    # vim
    sxhkd
    wget # cmd dl util
    brave # web browser
    nixfmt # nix language formatter
    git # git is required
    kdePackages.kget
    p7zip # archival tool
    nix-ld # run linux programs
    kitty # terminal emulator
    # rofi
    # albert
    keyd # disables capslock?
    anyrun # application launcher
    # xmodmap

    nix-output-monitor # nix update formatter
    cascadia-code # font
    swaynotificationcenter # notification daemon

    waybar
    nerd-fonts.jetbrains-mono # Matches your JetBrainsMono NFP
    font-awesome # For additional icons
    wlogout # For the power menu click
    pavucontrol # For audio control
  ];
}
