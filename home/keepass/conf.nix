{ pkgs, ... }:
{
  programs.keepassxc = {
    enable = true;
    autostart = true;
    settings = {
      FdoSecrets.Enabled = true;
      GUI = {
        CompactMode = true;
        HidePasswords = true;
        ApplicationTheme = "dark";
      };
      SSHAgent.Enabled = true;
    };
    Browser = {
      Enabled = true;
    };
  };
  xdg.autostart.enable = true;
}
