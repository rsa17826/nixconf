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
        # owner = userConfig.uname;
        # 3. Set the group to 'copyparty' so the service can read it
        group = "copyparty";

        # 4. Set permissions: Read for owner (root) and group (copyparty)
        mode = "0440";
      };
    };
  };
}
