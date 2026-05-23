{
  userConfig,
  ...
}:
{
  myProfile = {
    editableConfigs = [
      {
        name = "vex";
        src = ./.;
        srcStr = "${userConfig.nixConf}/home/vex++";
        destDir = ".local/share/godot/app_userdata/vex";
        files = [
          "main - EDITOR.sds"
          "config.cfg"
          "main.sds"
          "editorBar.sds"
        ];
      }
    ];
  };
}
