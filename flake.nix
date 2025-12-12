{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      uname = "nyx";
    in
    {
      nixosConfigurations = {
        ${uname} = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./configuration.nix
            inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${uname} = import ./home/home.nix;
      }
          ];
          specialArgs = {
            inherit inputs;
            inherit uname;
          };
        };
      };

      #homeConfigurations."${uname}" = home-manager.lib.homeManagerConfiguration {
      #  inherit pkgs;
      #  modules = [
      #    ./home/home.nix
      #  ];
      #};
    };
}
