{
  description = "NixOS configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    copyparty = {
      url = "github:9001/copyparty";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    hyprland = {
      url = "github:hyprwm/Hyprland/521ece463c4a9d3d128670688a34756805a4328f";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        hyprwire.url = "git+https://github.com/hyprwm/hyprwire?rev=4e1933ae5602b350c5b6633f5c932549c9b8aca2";
      };
    };
    # TODO follow https://github.com/VirtCode/hypr-dynamic-cursors/raw/refs/heads/main/hyprpm.toml
    hypr-dynamic-cursors = {
      url = "github:VirtCode/hypr-dynamic-cursors/57e14edd0ae265b01828e466e287e96eb1e84dd3";
      inputs.hyprland.follows = "hyprland";
    };
    hypr-darkwindow = {
      url = "github:micha4w/Hypr-DarkWindow"; # Make sure to change the tag to match your hyprland version
      inputs.hyprland.follows = "hyprland";
    };

    # impermanence = {
    #   url = "github:nix-community/impermanence";
    #   inputs={
    # nixpkgs.follows = "nixpkgs";
    # flake-utils.follows="flake-utils";
    # };
    #   inputs.home-manager.follows = "home-manager";
    # };
    # disko = {
    #   url = "github:nix-community/disko";
    #   inputs={
    # nixpkgs.follows = "nixpkgs";
    # flake-utils.follows="flake-utils";
    # };
    # };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    multi-game-launcher = {
      url = "github:rsa17826/multi-game-launcher";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    wayland-keepass-autotype = {
      url = "github:rsa17826/wayland-keepass-autotype";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    audio-manager = {
      url = "github:rsa17826/audio-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    # ext
    ext-owoify-editor = {
      url = "github:rsa17826/vscodeowotest";
      flake = false;
    };
    ext-simple-auto-formatter = {
      url = "github:rsa17826/simple-auto-formatter";
      flake = false;
    };
    ext-4-to-2-formatter = {
      url = "github:rsa17826/4-to-2-formatter";
      flake = false;
    };
    ext-auto-regex = {
      url = "github:rsa17826/auto-regex-vscode-extension";
      flake = false;
    };
    ext-multi-formatter = {
      url = "github:rsa17826/MultiFormatterVSCode";
      flake = false;
    };
    ext-sds = {
      url = "github:rsa17826/sds-vscode-language";
      flake = false;
    };
    ext-textreplace = {
      url = "github:rsa17826/textreplace-vscode-extension";
      flake = false;
    };
    ext-better-end-line-actions = {
      url = "github:rsa17826/fixed-line-actions-vscode-extension";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      sops-nix,
      nix-index-database,
      copyparty,
      ...
    }@inputs:
    let
      globalArgs = {
        inherit inputs;
        pkgFromInp =
          inputName: pkgName: inputs.${inputName}.packages.${pkgs.stdenv.hostPlatform.system}.${pkgName};
      };
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Helper function to generate a host configuration
      mkHost =
        hostName: tempUserConfig:
        nixpkgs.lib.nixosSystem (
          let
            userConfig = tempUserConfig // {
              nixConf = "/home/${tempUserConfig.uname}/nixconf";
            };
            args = globalArgs // {
              inherit hostName userConfig;
            };
          in
          {
            inherit system;
            specialArgs = args;
            modules = userConfig.modules ++ [
              {
                system.nixos.label = if builtins.pathExists ./label.nix then import ./label.nix else "unlabeled";
              }
              ./hardware-configurations/${hostName}.nix

              inputs.sops-nix.nixosModules.sops
              inputs.copyparty.nixosModules.default
              # nix-index-database.nixosModules.nix-index
              nix-index-database.nixosModules.default
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
        hostName: tempUserConfig:
        home-manager.lib.homeManagerConfiguration (
          let
            userConfig = tempUserConfig // {
              nixConf = "/home/${tempUserConfig.uname}/nixconf";
            };
            args = globalArgs // {
              inherit
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
            # ./home/CRON/clean.nix
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
# /etc/opensnitchd/system-fw.json:
