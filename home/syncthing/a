{
  userConfig,
  config,
  pkgs,
  ...
}:
{
  services.syncthing = {
    enable = true;

    # Run as your user, adjust as needed
    user = userConfig.uname;
    group = userConfig.uname;
    dataDir = "/home/${userConfig.uname}"; # where synced folders live
    configDir = "/home/${userConfig.uname}/.config/syncthing";

    # GUI listens on localhost only (matches your 127.0.0.1:8384)
    guiAddress = "127.0.0.1:8384";

    # Don't let NixOS overwrite devices/folders you add via the GUI
    overrideDevices = true;
    overrideFolders = true;

    settings = {
      # Your local device identity
      # Replace with your actual device ID from `syncthing show-config`
      localDeviceName = "nyix";

      gui = {
        enabled = true;
        tls = false;
        sendBasicAuthPrompt = false;
        apikey = config.sops.secrets.syncthingApiKey.value;
        theme = "default";
      };

      options = {
        # Global & local discovery
        globalAnnounceEnabled = true;
        localAnnounceEnabled = true;
        localAnnouncePort = 21027;

        # Relay
        relaysEnabled = true;
        relayReconnectIntervalM = 10;

        # NAT traversal
        natEnabled = true;
        natLeaseMinutes = 60;
        natRenewalMinutes = 30;
        natTimeoutSeconds = 10;

        # Auto-upgrade (every 12h, stable only)
        autoUpgradeIntervalH = 12;
        upgradeToPreReleases = false;

        # Opt out of usage reporting
        urAccepted = -1;

        # Misc
        reconnectionIntervalS = 60;
        startBrowser = false; # headless servers: set false
        setLowPriority = true;
        keepTemporariesH = 24;
        progressUpdateIntervalS = 5;
        limitBandwidthInLan = false;
        crashReportingEnabled = true;
        announceLANAddresses = true;
        sendFullIndexOnUpgrade = false;
        auditEnabled = false;

        minHomeDiskFree = {
          value = 1;
          unit = "%";
        };

        # Connection priorities (matching your config)
        connectionPriorityTcpLan = 10;
        connectionPriorityQuicLan = 20;
        connectionPriorityTcpWan = 30;
        connectionPriorityQuicWan = 40;
        connectionPriorityRelay = 50;
      };

      # Known peer devices — add entries here for each remote device
      devices = {
        # Example — replace ID and address with real values
        "rp" = {
          id = config.sops.secrets.syncthingRpId.value;
          addresses = [ "dynamic" ];
          compression = "metadata";
          introducer = false;
        };
      };

      # Shared folders — add entries here per folder
      folders = {
        # Example folder
        "syncthing" = {
          id = "syncthing";
          label = "syncthing";
          path = "/home/${userConfig.uname}/syncthing";
          type = "sendreceive";
          rescanIntervalS = 3600;
          fsWatcherEnabled = true;
          fsWatcherDelayS = 10;
          ignorePerms = true;
          autoNormalize = true;
          maxConflicts = 10;
          minDiskFree = {
            value = 1;
            unit = "%";
          };
          devices = [ "rp" ];
        };
        "songs" = {
          id = "songs";
          label = "songs";
          path = "/home/${userConfig.uname}/songs";
          type = "receiveonly";
          rescanIntervalS = 3600;
          fsWatcherEnabled = true;
          fsWatcherDelayS = 10;
          ignorePerms = true;
          autoNormalize = true;
          maxConflicts = 10;
          minDiskFree = {
            value = 1;
            unit = "%";
          };
          devices = [ "rp" ];
        };
      };
    };
  };
}
