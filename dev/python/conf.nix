{ userConfig, pkgs, ... }:

let
  extraPackages =
    map
      (
        {
          pname,
          version,
          sha256,
        }:
        pkgs.python314Packages.buildPythonPackage {
          inherit pname version;
          src = pkgs.fetchPypi { inherit pname version sha256; };
          pyproject = true;
          build-system = [ pkgs.python314Packages.setuptools ];
          doCheck = false;
        }
      )
      [
        # {
        #   pname = "types-curses";
        #   version = "2.4.2";
        #   sha256 = "sha256-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=";
        # }
      ];

  python314Pkgs = pkgs.python314.withPackages (_: extraPackages);
in
{
  users = {
    users = {
      "${userConfig.uname}" = {
        packages = [ python314Pkgs ];
      };
    };
  };
}
