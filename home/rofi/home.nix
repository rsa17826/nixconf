{
  pkgs,
  userConfig,
  ...
}:
{
  home = {
    packages = [
      (pkgs.writeShellApplication {
        name = "rofi-launcher";
        text = "rofi -modi blocks -show blocks -show-icons -blocks-wrap ${./launcher.py}";
        runtimeInputs = with pkgs; [
          (python3.withPackages (ps: with ps; [ emoji ]))
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
