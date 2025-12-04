{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations = {
      nyx = inputs.nixpkgs.lib.nixosSystem{
        inherit system;
        modules = [
          ./configuration.nix
                 # ({
          # services.xserver.enable = true;
          # services.xserver.windowManager.i3.enable = true;
          # environment.systemPackages = with pkgs; [ i3status ];
        # })
        ];
        specialArgs = {
        inherit inputs;
        };
      };
      };

      homeConfigurations."nyx" = home-manager.lib.homeManagerConfiguration {
       inherit pkgs;
       modules = [
         ./home/home.nix
       ];
      };
    };
}
