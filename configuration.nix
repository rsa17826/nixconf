# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  uname,
  ...
}:
let
  unstable =
    import
      (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
        # optional: pin for reproducibility
        # sha256 = "sha256-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=";
      })
      {
        config = config.nixpkgs.config;
        system = pkgs.system;
      };
in
{
  imports = [
    # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix
    # ./hardware-configuration.nix
  ];
  programs.zsh.enable = true;
  programs.hyprland.enable = true;

  # Bootloader.
   boot.loader.systemd-boot.enable = true;
   boot.loader.efi.canTouchEfiVariables = true;
  # boot.loader.grub = {
  #   enable = true;
  #   device = "/dev/sda"; # Install GRUB into the MBR
  # };
  
#  boot.loader.grub.enable = true;
#boot.loader.grub.device = "/dev/sda" ; 
# Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  programs.zsh.shellAliases = {
    update = "sudo nixos-rebuild switch --flake ~/nixconf#${uname} --impure";
    udpate = "update";
    push = "git add -A && git commit -m a && git push";
  };

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
  nix.settings.experimental-features = "nix-command flakes";
  # nix run home-manager/master -- init --switch
 # services.xserver.displayManager.autoNumLock = true;
  #services.xserver.xkbOptions = "ctrl:nocaps";
  #services.xserver.xkbOptions = "caps:off";
  #services.xserver.displayManager.autoNumLock = true;
  # Example for remapping Caps Lock and Num Lock to no-op

# Create a custom script to prevent toggling
#systemd.services.lock-keyboard = {
#  description = "Prevent Caps Lock and Num Lock Toggling";
#  wantedBy = [ "graphical.target" ];
#
#  serviceConfig.ExecStart = ''
#    xmodmap -e "keycode 66 = NoSymbol"     # Disable Caps Lock
#    xmodmap -e "keycode 77 = NoSymbol"     # Disable Num Lock
#  '';
#};

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  #   services.xserver.enable = true;
  #services.displayManager.cosmic-greeter.enable = true;

  # Enable the COSMIC desktop environment
  # services.desktopManager.cosmic.enable = true;
  #programs.hyprland = {
  #  # Install the packages from nixpkgs
  #  enable = true;
  #  # Whether to enable XWayland
  #  xwayland.enable = true;
  #};
  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
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
      keepass
      python313
      python313Packages.py7zr
      godot
      appimage-run
      firejail
      motrix
      nix-tree
      # ulauncher
    ];
  };
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;
  programs.appimage.package = pkgs.appimage-run.override {
    extraPkgs = pkgs: [
      pkgs.python312
    ];
  };
  # Enable the X11 windowing system.

  # Enable the Qtile

  services.system76-scheduler.enable = true;

  #environment.cosmic.excludePackages = with pkgs; [
  #    cosmic-edit
  #  ];
  # services.xserver.windowManager.i3.enable = false;

  # Optional: make i3 auto-selected on login
  # services.xserver.displayManager.defaultSession = "none+i3";

  # programs.twm.enable=true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "${uname}";
  programs.firefox.enable = true;

  nixpkgs.config.allowUnfree = true;
  systemd.services.sxhkd = {
    description = "Simple X Hotkey Daemon (sxhkd)";
    after = [ "graphical.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.sxhkd}/bin/sxhkd";
      Restart = "always";
      User = "${uname}";  # Replace "your-user" with your actual username
      Environment = "DISPLAY=:0";  # Ensures it runs in the X session
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    sxhkd
    rofi
    albert
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
    # xmodmap
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # sudo codium --no-sandbox --user-data-dir "/home/${uname}/.config/VSCodium/"
  networking.hostName = "${uname}";
  system.stateVersion = "25.05"; # Did you read the comment?
  services.opensnitch.enable = true;
  security.sudo.enable = true;
}
