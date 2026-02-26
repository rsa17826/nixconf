{ userConfig,... }:
{
  programs.git.config = {
    init = {
      defaultBranch = "main";
    };
    url = {
      "https://github.com/" = {
        insteadOf = [
          "gh:"
          "github:"
        ];
      };
    };
    user = {
      email = userConfig.email;
      name = userConfig.uname;
    };
  };
}
