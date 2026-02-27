{ userConfig, ... }:
{
  sops = {
    age.keyFile = "/home/${userConfig.uname}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      GITHUB_TOKEN = {
      };
      copypartyAdmin = {
        reloadUnits = [ "copyparty.service" ];
        path = "/home/${userConfig.uname}/.config/sops-nix/secrets";
      };
    };
  };
}
