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
    ./programs.nix
    ./nix/base.nix
    ./nix/plasma.nix
    # ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  #boot.loader.grub = {
  #  enable = true;
  #  device = "/dev/sda"; # Install GRUB into the MBR
  #};

  #  boot.loader.grub.enable = true;
  #boot.loader.grub.device = "/dev/sda" ;
  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  security.sudo.extraRules = [
    {
      groups = [ "users" ];
      commands = [
        {

          command = "/run/current-system/sw/bin/reboot";
          options = [ "NOPASSWD" ];
        }
        {

          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        settings = {
          main = {
            capslock = "overload(control, esc)";
            # numlock = "repeat";
          };
        };
      };
    };
  };
  # systemd.services.numlock = {
  # description = "Enable NumLock at startup";
  # wantedBy = [ "multi-user.target" ];
  # serviceConfig = {
  # Type = "oneshot";
  # RemainAfterExit = "yes";
  # ExecStart = "setleds +num";
  # };
  # };
  console.useXkbConfig = true;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

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
