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

      # Helper function to generate a host configuration
      mkHost =
        hostName: userConfig:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs hostName userConfig;
          };
          modules = userConfig.modules ++ [
            ./hardware-configurations/${hostName}.nix

            inputs.sops-nix.nixosModules.sops

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                # useGlobalPkgs = true;
                # useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = {
                  inherit inputs hostName userConfig;
                };
                users.${userConfig.uname} = import userConfig.homeFile;
              };
            }
          ];
        };

      # Define your hosts here
      hosts = {
        nyx_vbox = {
          uname = "nyx";
          email = "nyx@nyx.com";
          homeFile = ./home/home.nix;
          modules = [
            ./home/conf.nix
            # disko.nixosModules.disko
            # ./disko/conf.nix
            # impermanence.nixosModules.impermanence
            # ./impermanence/conf.nix
            ./home/programs.nix
            ./home/base.nix
            ./home/shellScripts/conf.nix
            ./home/CRON/clean.nix
          ];
        };
        # tunyic
        nyix = {
          uname = "nyix";
          email = "rsa17826@email.vccs.edu";
          homeFile = ./home/home.nix;
          modules = [
            ./home/conf.nix
            ./home/programs.nix
            ./home/base.nix
            ./home/shellScripts/conf.nix
          ];
        };
      };
    in
    {
      # Map the hosts defined above into nixosConfigurations
      nixosConfigurations = nixpkgs.lib.mapAttrs mkHost hosts;
    };
}
# error: flake 'git+file:///home/user/nixconf' does not provide attribute 'packages.x86_64-linux.homeConfigurations."nyix".activationPackage', 'legacyPackages.x86_64-linux.homeConfigurations."nyix".activationPackage' or 'homeConfigurations."nyix".activationPackage'