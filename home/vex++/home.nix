{
  userConfig,
  mkEditableConfig,
  ...
}:
let
  editable = mkEditableConfig [
    {
      name = "vex";
      src = ./.;
      srcStr = "${userConfig.nixConf}/home/vex++";
      nixKey = ".local/share/godot/app_userdata/vex"; # relative to ~/ for home.file
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
    file = editable.entries;
  };
}
