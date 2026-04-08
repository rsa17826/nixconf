{ userConfig, pkgs, ... }:
{
  programs.git = {
    settings = {
      user = {
        name = userConfig.uname;
        email = userConfig.email;
      };
      credential = {
        helper = "!gh auth git-credential";
      };
    };
    enable = true;
  };
}
