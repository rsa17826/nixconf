{ userConfig, ... }:
{
  myProfile = {
    editableConfigs = [
      {
        name = "tmux";
        src = ./.;
        srcStr = "${userConfig.nixConf}/home/tmux";
        destDir = "";
        files = [
          ".tmux.conf"
        ];
      }
    ];
  };
}
