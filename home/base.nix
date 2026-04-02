{ userConfig, ... }:
{
  nixpkgs.config.allowUnfree = false;
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      #    variant = "";
    };
  };
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      ipv6_servers = true;
      require_dnssec = true;
      doh_servers = true;
      server_names = [ "quad9-dnscrypt-ip4-filter-pri" ];
      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
      };
    };
  };
  networking = {
    nameservers = [
      "9.9.9.9"
      "149.112.112.112"
    ];
    networkmanager = {
      enable = true;
    };
  };
  services.displayManager.sddm.enable = false;
  services.displayManager.sddm.wayland.enable = false;
  services.displayManager.ly.enable = true;
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
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
  services.system76-scheduler.enable = true;
  services.displayManager = {
    # defaultSession = "plasma";
    defaultSession = "hyprland";

    # programs.twm.enable=true;
    autoLogin = {
      enable = true;
      user = "${userConfig.uname}";
    };
  };
}
