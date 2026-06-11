{
  userConfig,
  ...
}:
{
  myProfile = {
    editableConfigs = [
      {
        name = "autocorrect";
        src = ./.;
        srcStr = "${userConfig.nixConf}/home/autocorrect";
        destDir = ".config/autocorrect_daemon/";
        files = [
          "corrections.json"
        ];
      }
    ];
  };
}
