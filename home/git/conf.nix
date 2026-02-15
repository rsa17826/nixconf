{ uname, email }:
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
      email = email;
      name = uname;
    };
  };
}
