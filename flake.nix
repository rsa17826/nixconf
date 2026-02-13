{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      impermanence,
      disko,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      uname = "nyx";
    in
    {
      nix.registry.home-manager.flake = inputs.home-manager;
      # homeConfigurations.${uname} = home-manager.lib.homeManagerConfiguration {
      #   inherit pkgs;
      #   extraSpecialArgs = {
      #     inherit inputs uname;
      #     rootDir = "/home/${uname}/nixconf";
      #   };
      #   modules = [
      #     ./home/home.nix
      #     {
      #       # This bit ensures the home-manager command is actually installed
      #       programs.home-manager.enable = true;
      #       home.username = uname;
      #       home.homeDirectory = "/home/${uname}";
      #     }
      #   ];
      # };
      nixosConfigurations = {
        ${uname} = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./home/conf.nix
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.backupFileExtension = "backup";
              # home-manager.useGlobalPkgs = true;
              # home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit uname;
              };
              home-manager.users.${uname} = import ./home/home.nix;
            }
            disko.nixosModules.disko
            impermanence.nixosModules.impermanence
          ];
          specialArgs = {
            inherit inputs uname;
            rootDir = "/home/${uname}/nixconf";
          };
        };
      };
      home-manager.extraSpecialArgs = {
        inherit inputs uname; # Added 'inputs' here so sops works
        rootDir = "/home/${uname}/nixconf"; # Added this line
      };
    };
}
# nix run .#homeConfigurations.nyx.activationPackage -- switch --flake .
