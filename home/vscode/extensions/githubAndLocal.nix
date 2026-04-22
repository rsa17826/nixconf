{
  lib,
  pkgs,
  inputs,
  ...
}:
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
      npmDepsFetcherVersion ? 1,
    }:
    let
      # Extract version from package.json in the source
      pkgJson = builtins.fromJSON (builtins.readFile "${src}/package.json");
      version = pkgJson.version;

      npmBuild = pkgs.buildNpmPackage {
        pname = "${extName}-deps";
        inherit
          version
          src
          npmDepsHash
          npmDepsFetcherVersion
          ;
        preBuild = ''
          rm -rf src/test || true
        '';
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
        src = inputs.ext-kdl;
        extName = "kdl";
        extCreator = "kdl-org";
        npmDepsHash = "sha256-opTWFuuNgvs97CBGdex8kRuAZMSWsxJj3NIlKwy+ws8=";
      })
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
        npmDepsHash = "sha256-fACMqwxxsRPoSw06yrSCxJ5cM2oATBVaxegyxk5Nq/Y=";
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
      (buildFromFlake {
        src = inputs.ext-simple-auto-formatter;
        extName = "simple-auto-formatter";
        extCreator = "rssaromeo";
        npmDepsHash = "sha256-Ia7RJ9aHnNYSqHFjPIDCjAuontkDP6mqumo7ord4H/s=";
        npmDepsFetcherVersion = 2;
        nativeBuildInputs = with pkgs; [
          pkg-config
          python3
        ];
        buildInputs = with pkgs; [ libsecret ];
      })
      (buildFromFlake {
        src = inputs.ext-sds;
        extName = "simpledatastorage";
        extCreator = "rssaromeo";
        npmDepsHash = "sha256-INpVqlwd1ZrYZOuiYWhwrcOPJUHZwXPn3u/cMAvTzns=";
      })
      (buildFromFlake {
        src = inputs.ext-textreplace;
        extName = "textreplace";
        extCreator = "rssaromeo";
        npmDepsHash = "sha256-SG/vE/ovAc48STJL8v+ACrDZVxQRufI81KO14w2hn98=";
        npmDepsFetcherVersion = 2;
      })
      (buildFromFlake {
        src = inputs.ext-better-end-line-actions;
        extName = "better-end-line-actions";
        extCreator = "rssaromeo";
        npmDepsHash = "sha256-lqpv0TAksBoq+hr+KZ6kKhzsxlHxTEh9jQtf92uKI+4=";
        npmDepsFetcherVersion = 2;
      })
    ];
  };
}
# TODO
# indent line
