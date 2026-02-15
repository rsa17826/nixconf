{ uname, ... }:
{
  sops = {
    age.keyFile = "/home/${uname}/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
    secrets = {
      GITHUB_TOKEN = {
      };
    };
  };
}
