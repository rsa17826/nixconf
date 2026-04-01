{ ... }:
{
  services = {
    syncthing = {
      enable = true;
      group = "mygroupname";
      user = "myusername";
      dataDir = "/home/myusername/Documents"; # Default folder for new synced folders
      configDir = "/home/myusername/.config/syncthing"; # Folder for Syncthing's settings and keys
    };
  };
}
