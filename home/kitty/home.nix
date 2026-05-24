{
  userConfig,
  ...
}:
{
  home = {
    file = {
      ".config/kitty/bg.png".source = ./kittybg.png;
    };
  };
  myProfile = {
    editableConfigs = [
      {
        name = "kitty";
        src = ./.;
        srcStr = "${userConfig.nixConf}/home/kitty";
        destDir = ".config/kitty";
        files = [
          "kitty.conf"
        ];
      }
    ];
  };
}
