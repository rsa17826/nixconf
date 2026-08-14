{
  pkgs,
  userConfig,
  ...
}:
let
  rofiLauncherBin = pkgs.buildGoModule {
    pname = "rofi-launcher-bin";
    version = "0.1.0";
    src = ./rofi-launcher-go;
    vendorHash = "sha256-p4qS9CoZW9TDTVHN4jL1vbiBJ8ghJtrcb6T8EPnIab4=";
  };
in
{
  home = {
    packages = [
      (pkgs.writeShellApplication {
        name = "rofi-launcher";
        text = "rofi -modi blocks -show blocks -show-icons -blocks-wrap ${rofiLauncherBin}/bin/rofilauncher";
        runtimeInputs = with pkgs; [
          wl-clipboard
          libnotify
        ];
      })
    ];
  };
  myProfile = {
    editableConfigs = [
      {
        name = "rofi";
        src = ./.;
        srcStr = "${userConfig.nixConf}/home/rofi";
        destDir = ".config/rofi";
        files = [
          "config.rasi"
        ];
        dirs = [
          "themes"
        ];
      }
    ];
  };
}
