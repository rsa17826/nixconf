{ userConfig, ... }:
{
  sops = {
    age.keyFile = "/home/${userConfig.uname}/.config/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      GITHUB_TOKEN = {
        owner = userConfig.uname;
        neededForUsers = true;
      };
      copypartyAdmin = {
        neededForUsers = true;
        owner = "copyparty";
        restartUnits = [ "home-assistant.service" ];
        path = "/home/${userConfig.uname}/.config/sops-nix/secrets";
      };
    };
  };
}
