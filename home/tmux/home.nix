{ userConfig, ... }:
{
  myProfile = {
    editableConfigs = [
      {
        name = "tmux";
        src = ./.;
        srcStr = "${userConfig.nixConf}/home/tmux";
        nixKey = "tmux";
        dest = "$HOME";
        files = [
          ".tmux.conf"
        ];
      }
    ];
  };
}
