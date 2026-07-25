{
  lib,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  openssl,
}:

rustPlatform.buildRustPackage rec {
  pname = "freenet-core";
  version = "0.1.14";

  src = fetchFromGitHub {
    owner = "freenet";
    repo = "freenet-core";
    tag = "v${version}";
    hash = "sha256-d9TUivzXhPNGzmVQ7dlxvJbJlcaUJ4NXxE/Nfj9ofgM="; # nix build will tell you the real one on first try
  };

  cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB="; # same here — replace after first failed build

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  # Only build the two binaries you actually want (freenet + fdev),
  # skip if the workspace builds fine as-is
  cargoBuildFlags = [
    "-p"
    "freenet"
    "-p"
    "fdev"
  ];

  meta = with lib; {
    description = "Freenet Core - the new Rust P2P node (contracts/WASM), not the old Java fred";
    homepage = "https://github.com/freenet/freenet-core";
    license = licenses.agpl3Only;
    mainProgram = "freenet";
  };
}
