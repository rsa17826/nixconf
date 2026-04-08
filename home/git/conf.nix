{ userConfig, pkgs, ... }:
{
  programs.git = {
    settings = {
      user = {
        name = userConfig.uname;
        email = userConfig.email;
      };
    };
    credential.helper = "!${pkgs.gh}/bin/gh auth git-credential";
    enable = true;
  };
}
