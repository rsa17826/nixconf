{
  userConfig,
  ...
}:
{
  myProfile = {
    editableConfigs = [
      {
        name = "dunsr";
        src = ./.;
        srcStr = "${userConfig.nixConf}/home/dunst";
        destDir = ".config/dunst/";
        files = [
          "dunstrc"
        ];
      }
    ];
  };
}
