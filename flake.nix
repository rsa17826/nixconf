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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      impermanence,
      disko,
      sops-nix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      uname = "nyx";
      email = "nyx@nyx.com";
    in
    {
      nix.registry.home-manager.flake = inputs.home-manager;
      # homeConfigurations.${uname} = home-manager.lib.homeManagerConfiguration {
      #   inherit pkgs;
      #   extraSpecialArgs = {
      #     inherit inputs uname;
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
          specialArgs = {
            inherit inputs uname email;
            hostName = "${uname}_vbox";
          };
          modules = [
            ./home/conf.nix
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                backupFileExtension = "backup";
                # home-manager.useGlobalPkgs = true;
                # home-manager.useUserPackages = true;
                extraSpecialArgs = {
                  inherit inputs uname;
                  hostName = "${uname}_vbox";
                };
                users.${uname} = import ./home/home.nix;
              };
            }
            # disko.nixosModules.disko
            # impermanence.nixosModules.impermanence
            sops-nix.nixosModules.sops
            /etc/nixos/hardware-configuration.nix
            ./home/programs.nix
            ./home/base.nix
            # ./disko/conf.nix
            # ./impermanence/conf.nix
            ./home/shellScripts/conf.nix
            ./home/CRON/clean.nix
          ];
        };
      };
    };
}
# nix run .#homeConfigurations.nyx.activationPackage -- switch --flake .
