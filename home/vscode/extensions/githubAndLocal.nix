{ pkgs, inputs, ... }:
let
  # Helper function to reduce boilerplate
  buildFromFlake =
    {
      src, # Pass the input directly (e.g., inputs.ext-owoify)
      extName,
      extCreator,
      npmDepsHash, # You still need this, but only when package-lock.json changes
      nativeBuildInputs ? [ ],
      buildInputs ? [ ],
    }:
    let
      # Extract version from package.json in the source
      pkgJson = builtins.fromJSON (builtins.readFile "${src}/package.json");
      version = pkgJson.version;

      npmBuild = pkgs.buildNpmPackage {
        pname = "${extName}-deps";
        inherit version src npmDepsHash;

        npmBuildScript = "compile";
        nativeBuildInputs = [ pkgs.typescript ] ++ nativeBuildInputs;
        inherit buildInputs;

        installPhase = "cp -r . $out";
      };
    in
    pkgs.stdenv.mkDerivation {
      pname = "vscode-extension-${extName}";
      inherit version;
      src = npmBuild;

      installPhase = ''
        mkdir -p $out/share/vscode/extensions/${extCreator}.${extName}
        cp -r . $out/share/vscode/extensions/${extCreator}.${extName}
      '';

      passthru = {
        vscodeExtName = extName;
        vscodeExtPublisher = extCreator;
        vscodeExtUniqueId = "${extCreator}.${extName}";
      };
    };
  buildLocalEx =
    {
      name,
      publisher,
      version,
      filename,
    }:
    pkgs.vscode-utils.buildVscodeExtension {
      inherit name version;
      src = ./vsix/${filename};
      vscodeExtName = name;
      vscodeExtPublisher = publisher;
      vscodeExtUniqueId = "${publisher}.${name}";
      # If Nix still complains about null, use a dummy hash or run 'nix-hash --flat --type sha256 path/to/file'
      hash = pkgs.lib.fakeHash;
      pname = name; # Add this line specifically
      sourceRoot = ".";
    };
  buildFromGh =
    {
      version,
      ghName,
      ghRev,
      ghSha ? "sha256-GIT+SHA+AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
      ghRepo,
      extName,
      extCreator,
      npmDepsHash ? "sha256-NPM+DEPS+HASH+AAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
      nativeBuildInputs ? [ ],
      buildInputs ? [ ],
    }:
    let
      npmBuild = pkgs.buildNpmPackage {
        pname = "${extName}-deps";
        inherit version;
        src = pkgs.fetchFromGitHub {
          owner = ghName;
          repo = ghRepo;
          rev = ghRev;
          sha256 = ghSha;
        };

        inherit npmDepsHash;

        # 1. Tell Nix to actually run the build script in package.json
        # Most VS Code extensions use "compile" or "build"
        npmBuildScript = "compile";
        # 2. Add dependencies needed for the build process (like TypeScript)
        nativeBuildInputs = [ pkgs.typescript ] ++ nativeBuildInputs;
        inherit buildInputs;
        installPhase = ''
          cp -r . $out
        '';

        # makeCacheWritable = true;

        # This ensures we have the lockfile we generated earlier
        # postPatch = ''
        #   if [ ! -f package-lock.json ]; then
        #     ${pkgs.nodejs}/bin/npm install --package-lock-only
        #   fi
        # '';
      };
    in
    pkgs.stdenv.mkDerivation {
      pname = "vscode-extension-${extName}";
      inherit version;
      src = npmBuild;

      installPhase = ''
        mkdir -p $out/share/vscode/extensions/${extCreator}.${extName}
        # We copy everything, including the newly created 'out' folder
        cp -r . $out/share/vscode/extensions/${extCreator}.${extName}
      '';

      passthru = {
        vscodeExtName = extName;
        vscodeExtPublisher = extCreator;
        vscodeExtUniqueId = "${extCreator}.${extName}";
      };
    };
  # dlExt =
  #   {
  #     name,
  #     publisher,
  #     version,
  #     domain,
  #   }:
  #   pkgs.vscode-utils.extensionFromVscodeMarketplace {
  #     inherit name publisher version;
  #     sha256 = lib.fakeHash;

  #     src = pkgs.fetchurl {
  #       url = "https://${domain}/${publisher}/${name}/${version}/${publisher}.${name}-${version}.vsix";
  #       sha256 = lib.fakeHash;
  #     };
  #   };
in
{
  programs.vscode.profiles.default = {
    extensions = [
      (buildFromFlake {
        src = inputs.ext-owoify-editor;
        extName = "owoify-editor";
        extCreator = "rssaromeo";
        npmDepsHash = "sha256-opTWFuuNgvs97CBGdex8kRuAZMSWBxJj3NIlKwy+ws8=";
      })
      (buildFromFlake {
        src = inputs.ext-4-to-2-formatter;
        extName = "4-to-2-formatter";
        extCreator = "rssaromeo";
        npmDepsHash = "sha256-o7IA+4Kq4j2XD7dpJNje8g4G2KFi6ocsnXyaGSaXB8M=";
      })
      (buildFromFlake {
        src = inputs.ext-auto-regex;
        extName = "auto-regex";
        extCreator = "rssaromeo";
        npmDepsHash = "sha256-XN++TQ7z+qF/iK3ktBnCISYh5+eAFi+5QeQgIw0ogoA=";
        nativeBuildInputs = with pkgs; [
          pkg-config
          python3
        ];
        buildInputs = with pkgs; [ libsecret ];
      })
      (buildFromFlake {
        src = inputs.ext-multi-formatter;
        extName = "multi-formatter";
        extCreator = "Jota0222";
        npmDepsHash = "sha256-wWpLlndJnrub7QVskc+jKACETjwv0niVwr6AZjFl1jU=";
        nativeBuildInputs = with pkgs; [
          pkg-config
          python3
        ];
        buildInputs = with pkgs; [ libsecret ];
      })
      # (buildFromFlake {
      #   src = inputs.ext-simple-auto-formatter;
      #   extName = "simple-auto-formatter";
      #   extCreator = "rssaromeo";
      #   npmDepsHash = "sha256-FOBs2Vtje7kNQ27tb0ghwl6/yMjttzuofeuv2LAE6y8=";
      # })
      (buildFromFlake {
        src = inputs.ext-sds;
        extName = "simpledatastorage";
        extCreator = "rssaromeo";
        npmDepsHash = "sha256-INpVqlwd1ZrYZOuiYWhwrcOPJUHZwXPn3u/cMAvTzns=";
      })
    ];
    # extensions = [
    #   (buildFromGh {
    #     ghName = "rsa17826";
    #     ghRepo = "vscodeowotest";
    #     extName = "owoify-editor";
    #     extCreator = "rssaromeo";
    #     version = "3.0.0";

    #     ghRev = "4972c72433774e930feb6a3e9ebae610d6dfde38";
    #     ghSha = "sha256-5m0ijBmmM9namnCHJb2uHZrLXg+U3n84di+TlhZ/310=";
    #     npmDepsHash = "sha256-eUE/p44juc+GWdw8HugVk5Ot69ckjaK4zhOPYM6GFnM=";
    #   })
    #   # onStartupFinished
    #   # (buildFromGh {
    #   #   ghName = "rsa17826";
    #   #   ghRepo = "simple-auto-formatter";

    #   #   extName = "simple-auto-formatter";
    #   #   extCreator = "rssaromeo";
    #   #   version = "22.0.0";

    #   #   ghRev = "ea398d43bfc9fb05e2c52d78135a0258c4a081f9";
    #   #   ghSha = "sha256-FOBs2Vtje7kNQ27tb0ghwl6/yMjttzuofeuv2LAE6y8=";
    #   # })
    #   (buildFromGh {
    #     ghName = "rsa17826";
    #     ghRepo = "4-to-2-formatter";

    #     extName = "4-to-2-formatter";
    #     extCreator = "rssaromeo";
    #     version = "7.0.0";

    #     ghRev = "8d205d877c1c7b2747846472f161729e67c634e6";
    #     ghSha = "sha256-PHaOXLEX2D/nrhabylTB+U0R7/6eVSsrRulFYaNebtk=";
    #     npmDepsHash = "sha256-o7IA+4Kq4j2XD7dpJNje8g4G2KFi6ocsnXyaGSaXB8M=";
    #   })
    #   (buildFromGh {
    #     ghName = "rsa17826";
    #     ghRepo = "auto-regex-vscode-extension";

    #     extName = "auto-regex";
    #     extCreator = "rssaromeo";
    #     version = "52.0.0";

    #     ghRev = "40433a8c64ae8301ae9d7307f89410e1d8d68644";
    #     ghSha = "sha256-UXZeOcP/GDA81+vU0pHAxDSJYSYs0djBfqoJdHgLCZc=";
    #     npmDepsHash = "sha256-XN++TQ7z+qF/iK3ktBnCISYh5+eAFi+5QeQgIw0ogoA=";
    #     nativeBuildInputs = with pkgs; [
    #       pkg-config
    #       python3 # node-gyp usually needs this too
    #     ];

    #     # Libraries needed at build and run time
    #     buildInputs = with pkgs; [
    #       libsecret
    #     ];
    #   })
    #   (buildFromGh {
    #     ghName = "rsa17826";
    #     ghRepo = "MultiFormatterVSCode";

    #     extName = "multi-formatter";
    #     extCreator = "Jota0222";
    #     version = "6.0.0";

    #     ghRev = "021eaba326486ac6d82aaa5392a402efde0d053d";
    #     ghSha = "sha256-VMGeH4s8z1rtH7SU87jNAZoWNHcFcQ0GHRPs6dvDWm8=";
    #     npmDepsHash = "sha256-wWpLlndJnrub7QVskc+jKACETjwv0niVwr6AZjFl1jU=";
    #     nativeBuildInputs = with pkgs; [
    #       pkg-config
    #       python3
    #     ];
    #     buildInputs = with pkgs; [
    #       libsecret
    #     ];
    #   })
    #   # (buildFromGh {
    #   #   ghName = "coopmoney";
    #   #   ghRepo = "vscode-nix-embedded-languages";

    #   #   extName = "nix-embedded-languages";
    #   #   extCreator = "coopermaruyama";
    #   #   version = "1.1.1";

    #   #   ghRev = "b8b2a5aedc444a6ac2c4be79648e502d5e25b36c";
    #   #   ghSha = "sha256-zyJvVVlguTpUMwLXnllJsnJfn3WfXqyenxvJl6nr4Kk=";
    #   # })
    #   (buildFromGh {
    #     ghName = "rsa17826";
    #     ghRepo = "sds-vscode-language";

    #     extName = "simpledatastorage";
    #     extCreator = "rssaromeo";
    #     version = "9.0.0";

    #     ghRev = "391123c1c13b309a2733ed9d1bae0a077391adcb";
    #     ghSha = "sha256-FlrSoYriFFXo3cBqR9jGMtKp/2X6T2smBkBtjogePBA=";
    #     npmDepsHash = "sha256-INpVqlwd1ZrYZOuiYWhwrcOPJUHZwXPn3u/cMAvTzns=";
    #   })
    # ];
  };
}
