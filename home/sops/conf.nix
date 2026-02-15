{ rootDir, uname, ... }:
{
  sops = {
    # 1. Point to your private key
    age.keyFile = "/home/${uname}/.config/sops/age/keys.txt";

    # 2. Point to your secrets file (relative to home.nix)
    defaultSopsFile = rootDir + ./secrets/secrets.yaml;

    # 3. Define the secrets you want to symlink
    secrets = {
      GITHUB_TOKEN = {
      };
    };
  };
}
# age12kl0dmlpcwuw2c6uq5c8dzhyg34cl7r2qzylxzte0ewe8eemz9jqfq4hl8
