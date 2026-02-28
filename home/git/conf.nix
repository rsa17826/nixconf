{ userConfig, ... }:
{
  programs.git={
        userName  = userConfig.uname;
    userEmail = userConfig.email;
    enable = true;

  }
}
