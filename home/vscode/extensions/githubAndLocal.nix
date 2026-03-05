{ pkgs, ... }:
let
  # Helper function to reduce boilerplate
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
      ghSha ? "sha256-GIT+HASHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
      ghRepo,
      sourceRoot ? ".",
      extName,
      extCreator,
      npmDepsHash ? "sha256-NPM_DEPS_HASHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
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

        # Use the hash provided by the failed build error
        inherit npmDepsHash;

        # Fix for the "Panic" - tells NPM not to be as strict with URLs
        makeCacheWritable = true;
        npmInstallFlags = [ "--package-lock-only" ];

        # If the lockfile is missing, this allows the build to continue
        # (though you should really ensure the lockfile is in the repo root)
        postPatch = ''
          if [ ! -f package-lock.json ]; then
            echo "Warning: package-lock.json missing, attempting to generate..."
            ${pkgs.nodejs}/bin/npm install --package-lock-only
          fi
        '';
      };
    in
    pkgs.vscode-utils.buildVscodeExtension {
      inherit version;
      pname = extName;
      src = npmBuild;
      vscodeExtUniqueId = "${extCreator}.${extName}";
      vscodeExtName = extName;
      vscodeExtPublisher = extCreator;
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
      (buildFromGh {
        ghName = "rsa17826";
        ghRepo = "vscodeowotest";
        extName = "owoify-editor";
        extCreator = "rssaromeo";
        version = "3.0.0";
        sourceRoot = "source";

        ghRev = "4972c72433774e930feb6a3e9ebae610d6dfde38";
        # ghSha = "sha256-3nTApOmVXrUyoQ5Zvo0vt8bTn1XQpk36webCSacwbF8=";
      })
      # (buildFromGh {
      #   ghName = "rsa17826";
      #   ghRepo = "simple-auto-formatter";

      #   extName = "simple-auto-formatter";
      #   extCreator = "rssaromeo";
      #   version = "22.0.0";
      #   sourceRoot = "source";

      #   ghRev = "704d3115007225940bbff112d686ea85508eeb9b";
      #   ghSha = "sha256-Zk9tG2qxfQrZbn/HRAImipiGQ+GyD0Ga4I3UqUIVfjY=";
      # })
      # (buildFromGh {
      #   ghName = "rsa17826";
      #   ghRepo = "4-to-2-formatter";

      #   extName = "4-to-2-formatter";
      #   extCreator = "rssaromeo";
      #   version = "7.0.0";
      #   sourceRoot = "source";

      #   ghRev = "23df4506dbcff95247c8b454c03377f8a518226b";
      #   ghSha = "sha256-UWioS6zquOphFsxyylWr83/btGfWFN9RwgtAe5s97yQ=";
      # })
      # (buildFromGh {
      #   ghName = "rsa17826";
      #   ghRepo = "auto-regex-vscode-extension";

      #   extName = "auto-regex";
      #   extCreator = "rssaromeo";
      #   version = "51.0.0";
      #   sourceRoot = "source";

      #   ghRev = "40433a8c64ae8301ae9d7307f89410e1d8d68644";
      #   ghSha = "sha256-UXZeOcP/GDA81+vU0pHAxDSJYSYs0djBfqoJdHgLCZc=";
      # })
      # (buildFromGh {
      #   ghName = "rsa17826";
      #   ghRepo = "MultiFormatterVSCode";

      #   extName = "multi-formatter";
      #   extCreator = "Jota0222";
      #   version = "6.0.0";

      #   ghRev = "0ded2c7cbad7769a42c3f3a4dffd16635111be4d";
      #   ghSha = "sha256-aDZ7HHMdFLwaG6Y2trInJGFAyz+xv/CrSyBBeoZ4Q28=";
      # })
      # (buildFromGh {
      #   ghName = "coopmoney";
      #   ghRepo = "vscode-nix-embedded-languages";

      #   extName = "nix-embedded-languages";
      #   extCreator = "coopermaruyama";
      #   version = "1.1.1";
      #   sourceRoot = "source";

      #   ghRev = "b8b2a5aedc444a6ac2c4be79648e502d5e25b36c";
      #   ghSha = "sha256-zyJvVVlguTpUMwLXnllJsnJfn3WfXqyenxvJl6nr4Kk=";
      # })
      # (buildFromGh {
      #   ghName = "rsa17826";
      #   ghRepo = "sds-vscode-language";

      #   extName = "simpledatastorage";
      #   extCreator = "rssaromeo";
      #   version = "9.0.0";
      #   sourceRoot = "source";

      #   ghRev = "391123c1c13b309a2733ed9d1bae0a077391adcb";
      #   ghSha = "sha256-FlrSoYriFFXo3cBqR9jGMtKp/2X6T2smBkBtjogePBA=";
      # })
    ];
  };
}
