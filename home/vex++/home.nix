{
  ln,
  userConfig,
  ...
}:
{
  home = {
    file = {
      "/home/nyix/.local/share/godot/app_userdata/vex/editorBar.sds".source =
        ln "${userConfig.nixConf}/home/vex++/editorBar.sds";
      "/home/nyix/.local/share/godot/app_userdata/vex/main.sds".source =
        ln "${userConfig.nixConf}/home/vex++/main.sds";
      "/home/nyix/.local/share/godot/app_userdata/vex/main - EDITOR.sds".source =
        ln "${userConfig.nixConf}/home/vex++/main - EDITOR.sds";
    };
  };
}
