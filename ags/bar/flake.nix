{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    astal.url = "github:aylur/astal";
    ags.url = "github:aylur/ags";
  };

  outputs =
    {
      nixpkgs,
      astal,
      ags,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          # This includes the 'astallib' and type generation tools
          astal.packages.${system}.default
          astal.packages.${system}.io
          astal.packages.${system}.battery
          astal.packages.${system}.network
          # Add any other astal libraries you need here
        ];
      };
    };
}
