{
  description = "NixOS configuration";
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    millennium = {
      url = "github:SteamClientHomebrew/Millennium/next?dir=packages/nix";
      # inputs = {
      #   nixpkgs = {
      #     follows = "nixpkgs";
      #   };
      # };
    };
    helium-flake = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    copyparty = {
      url = "github:9001/copyparty";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        flake-utils = {
          follows = "flake-utils";
        };
      };
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        # hyprwire = {
        #   url = "git+https://github.com/hyprwm/hyprwire?rev=4e1933ae5602b350c5b6633f5c932549c9b8aca2";
        # };
      };
    };
    # TODO follow https://github.com/VirtCode/hypr-dynamic-cursors/raw/refs/heads/main/hyprpm.toml
    # hypr-dynamic-cursors = {
    #   url = "github:VirtCode/hypr-dynamic-cursors/57e14edd0ae265b01828e466e287e96eb1e84dd3";
    #   inputs = {
    #     hyprland.follows = "hyprland";
    #   };
    # };
    # hypr-darkwindow = {
    #   url = "github:micha4w/Hypr-DarkWindow";
    #   inputs = {
    #     hyprland = {
    #       # Make sure to change the tag to match your hyprland version
    #       follows = "hyprland";
    #     };
    #   };
    # };
    perkins = {
      url = "github:Mr-Robot-err-404/perkins";
      flake = false;
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
    rofi-blocks-main = {
      url = "github:OmarCastro/rofi-blocks";
      flake = false;
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    gowoify = {
      url = "github:rsa17826/gowoify";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        flake-utils = {
          follows = "flake-utils";
        };
      };
    };
    alwaysFocusedInputBox = {
      url = "github:rsa17826/alwaysFocusedInputBox";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        flake-utils = {
          follows = "flake-utils";
        };
      };
    };
    key-modifier = {
      url = "github:rsa17826/key-modifier";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        flake-utils = {
          follows = "flake-utils";
        };
      };
    };
    termbar = {
      url = "github:rsa17826/termbar";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        flake-utils = {
          follows = "flake-utils";
        };
      };
    };
    input-display = {
      url = "github:rsa17826/input-display";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        flake-utils = {
          follows = "flake-utils";
        };
      };
    };
    input-manager = {
      url = "github:rsa17826/input-manager";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        flake-utils = {
          follows = "flake-utils";
        };
      };
    };
    go-autoclicker = {
      url = "github:rsa17826/go-autoclicker";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        flake-utils = {
          follows = "flake-utils";
        };
      };
    };
    multi-game-launcher = {
      url = "github:rsa17826/multi-game-launcher";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        flake-utils = {
          follows = "flake-utils";
        };
      };
    };
    wayland-keepass-autotype = {
      url = "github:rsa17826/wayland-keepass-autotype";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        flake-utils = {
          follows = "flake-utils";
        };
      };
    };
    audio-manager = {
      url = "github:rsa17826/audio-manager";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        flake-utils = {
          follows = "flake-utils";
        };
      };
    };
    browser-selector = {
      url = "github:rsa17826/browserSelector";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    autocorrect = {
      url = "github:rsa17826/autocorrect";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        flake-utils = {
          follows = "flake-utils";
        };
      };
    };
    file-sorter = {
      url = "github:rsa17826/file-sorter";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    macro-recorder = {
      url = "github:rsa17826/macro-recorder";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
        flake-utils = {
          follows = "flake-utils";
        };
      };
    };
    auto-screenshotter = {
      url = "github:rsa17826/auto-screenshotter";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    # ext
    ext-vscode-math-on-selected-nums = {
      url = "github:rsa17826/vscode-ext---math-on-selected-nums";
      flake = false;
    };
    ext-vscode-void-color-theme = {
      url = "github:rsa17826/vscode-void-color-theme";
      flake = false;
    };
    ext-macro-syntax-highlighter = {
      url = "github:rsa17826/macro-syntax-highlighter";
      flake = false;
    };
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
      nix-index-database,
      ...
    }@inputs:
    let
      globalArgs = {
        inherit inputs;
        root = ./.;
        pkgFromInp =
          inputName: pkgName: inputs.${inputName}.packages.${pkgs.stdenv.hostPlatform.system}.${pkgName};
        listDir =
          start: cb:
          (
            let
              dir = builtins.readDir start;
            in
            (map cb (
              builtins.filter (name: dir.${name} == "directory" && builtins.pathExists (cb name)) (
                builtins.attrNames dir
              )
            ))
          );
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
                system = {
                  nixos = {
                    label = if builtins.pathExists ./label.nix then import ./label.nix else "unlabeled";
                  };
                };
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
            ./dev/python/conf.nix
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
# /etc/opensnitchd/rules/
# /etc/opensnitchd/system-fw.json:
