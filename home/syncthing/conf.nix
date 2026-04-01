{ userConfig, ... }:
{
  services = {
    syncthing = {
      enable = false;
      group = "users";
      user = "${userConfig.uname}";
      dataDir = "/home/${userConfig.uname}/Documents"; # Default folder for new synced folders
      configDir = "/home/${userConfig.uname}/.config/syncthing"; # Folder for Syncthing's settings and keys
    };
  };
}
