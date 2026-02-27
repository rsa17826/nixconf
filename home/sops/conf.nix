{ userConfig, ... }:
{
  sops = {
    age.keyFile = "/home/${userConfig.uname}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      GITHUB_TOKEN = {
      };
      copypartyAdmin = {
        restartUnits = [ "home-assistant.service" ];
        path = "/home/${userConfig.uname}/.config/sops-nix/secrets";
      };
    };
  };
}
