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
    copyparty = {
      url = "github:9001/copyparty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # impermanence = {
    #   url = "github:nix-community/impermanence";
    #   inputs.nixpkgs.follows = "nixpkgs";
    #   inputs.home-manager.follows = "home-manager";
    # };
    # disko = {
    #   url = "github:nix-community/disko";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      disko,
      sops-nix,
      nix-index-database,
      copyparty,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Helper function to generate a host configuration
      mkHost =
        hostName: userConfig:
        nixpkgs.lib.nixosSystem (
          let
            args = {
              inherit inputs hostName userConfig;
            };
          in
          {
            inherit system;
            specialArgs = args;
            modules = userConfig.modules ++ [
              ./hardware-configurations/${hostName}.nix

              inputs.sops-nix.nixosModules.sops
              inputs.copyparty.nixosModules.default
              nix-index-database.nixosModules.nix-index
              home-manager.nixosModules.home-manager
              {
                home-manager = {
                  # useGlobalPkgs = true;
                  # useUserPackages = true;
                  backupFileExtension = "backup";
                  extraSpecialArgs = args;
                  users.${userConfig.uname} = import userConfig.homeFile;
                };
              }
            ];
          }
        );
      mkHostHM =
        hostName: userConfig:
        home-manager.lib.homeManagerConfiguration (
          let
            args = {
              inherit
                inputs
                hostName
                userConfig
                ;
            };
          in
          {

            inherit pkgs;
            # Home-manager requires 'pkgs' instance
            extraSpecialArgs = args;
            modules = [
              # > Our main home-manager configuration file <
              userConfig.homeFile
            ];
          }
        );

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
      nixHosts = nixpkgs.lib.mapAttrs mkHost hosts;
      homehosts = nixpkgs.lib.mapAttrs mkHostHM hosts;
    in
    {
      # Map the hosts defined above into nixosConfigurations
      nixosConfigurations = nixHosts;
      homeConfigurations = homehosts;
    };
}
# error: flake 'git+file:///home/user/nixconf' does not provide attribute 'packages.x86_64-linux.homeConfigurations."nyix".activationPackage', 'legacyPackages.x86_64-linux.homeConfigurations."nyix".activationPackage' or 'homeConfigurations."nyix".activationPackage'
# /etc/opensnitchd/rules/
