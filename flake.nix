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
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.astal.follows = "astal";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      impermanence,
      disko,
      sops-nix,
      ags,
      astal,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      cfg = {
        "nyx_vbox" = {
          uname = "nyx";
          email = "nyx@nyx.com";
        };
        all = {
          args = {
            inherit inputs;
          };
          homeFile = ./home/home.nix;
          modules = [
            ./home/conf.nix

            # disko.nixosModules.disko
            # ./disko/conf.nix
            # impermanence.nixosModules.impermanence
            # ./impermanence/conf.nix
            sops-nix.nixosModules.sops
            /etc/nixos/hardware-configuration.nix
            ./home/programs.nix
            ./home/base.nix
            ./home/shellScripts/conf.nix
            ./home/CRON/clean.nix
            ./hardware-configuration/${hostName}/hardware-configuration.nix
          ];
        };
      };
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
        map ${hostName} = inputs.nixpkgs.lib.nixosSystem ({
          inherit system;
          specialArgs = args;
          modules =
            cfg.${hostName}
            ++ cfg.all
            ++ [
              inputs.home-manager.nixosModules.home-manager
              {
                home-manager = {
                  backupFileExtension = "backup";
                  # home-manager.useGlobalPkgs = true;
                  # home-manager.useUserPackages = true;
                  extraSpecialArgs = args;
                  users.${args.uname} = import homeFile;
                };
              }
            ];
        });
      };
    };
}
# nix run .#homeConfigurations.nyx.activationPackage -- switch --flake .
