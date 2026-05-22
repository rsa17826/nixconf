{ userConfig, ... }:
{
  sops = {
    age = {
      keyFile = "/home/${userConfig.uname}/.config/sops/age/keys.txt";
    };
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      GITHUB_TOKEN = {
        owner = userConfig.uname;
      };
      copypartyAdmin = {
        restartUnits = [ "copyparty.service" ];
        group = "copyparty";
        mode = "0440";
      };
      copypartyS = {
        restartUnits = [ "copyparty.service" ];
        group = "copyparty";
        mode = "0440";
      };
      copypartySongs = {
        restartUnits = [ "copyparty.service" ];
        group = "copyparty";
        mode = "0440";
      };
      # syncthingApiKey = { };
      # syncthingRpId = { };
    };
  };
}
