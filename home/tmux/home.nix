{ userConfig, ... }:
{
  myProfile = {
    editableConfigs = [
      {
        name = "tmux";
        src = ./.;
        srcStr = "${userConfig.nixConf}/home";
        nixKey = "tmux";
        dest = "$HOME";
        files = [
          ".tmux.conf"
        ];
      }
    ];
  };
}
