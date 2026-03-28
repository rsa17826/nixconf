{ userConfig, ... }:
{
  programs.git = {
    settings = {
      user = {
        name = userConfig.uname;
        email = userConfig.email;
      };
    };
    enable = true;
  };
}
