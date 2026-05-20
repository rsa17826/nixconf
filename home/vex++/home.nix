{
  userConfig,
  mkEditableConfig,
  root,
  ...
}:
let
  editable = mkEditableConfig [
    {
      name = "hypr";
      src = root + "/home/hyprland";
      srcStr = "${userConfig.nixConf}/home/hyprland";
      dest = "$HOME/.local/share/godot/app_userdata/vex";
      files = [
        "main - EDITOR.sds"
        "config.cfg"
        "main.sds"
        "editorBar.sds"
      ];
    }
  ];
in
{
  home = {
    file = editable.xdgEntries;
  };
}
