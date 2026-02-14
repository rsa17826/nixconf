{ uname, ... }:
{
  sops = {
    # 1. Point to your private key
    age.keyFile = "/home/${uname}/.config/sops/age/keys.txt";

    # 2. Point to your secrets file (relative to home.nix)
    defaultSopsFile = ../../secrets/secrets.yaml;

    # 3. Define the secrets you want to symlink
    secrets = {
      GITHUB_TOKEN = {
      };
    };
  };
}
