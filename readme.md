sudo -i

export NIX_CONFIG="experimental-features = nix-command flakes"

git clone https://github.com/rsa17826/nixconf.git && cd nixconf

nixos-generate-config
vi /etc/nixos/hardware-configuration.nix

nix run github:nix-community/disko -- --flake .#nyx



nix shell nixpkgs#nix-output-monitor
nixos-install --flake .#nyx --impure -v --show-trace |& nom --json

nix-shell -p nix-prefetch-github -d-run "nix-prefetch-github rsa17826 auto-regex-vscode-extension --rev 40433a8c64ae8301ae9d7307f89410e1d8d68644"
