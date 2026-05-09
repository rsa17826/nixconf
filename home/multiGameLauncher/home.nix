{ ... }:
{
  xdg = {
    desktopEntries = {
      launcher = {
        name = "Multi Game Launcher";
        exec = "/run/current-system/sw/bin/launcher %u";
        mimeType = [ "x-scheme-handler/multi-game-launcher" ];
      };
    };
    mimeApps = {
      defaultApplications = {
        "x-scheme-handler/multi-game-launcher" = [ "launcher.desktop" ];
      };
    };
  };
}
