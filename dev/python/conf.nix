{ lib, pkgs, ... }:

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
          doCheck = false;
        }
      )
      [
        {
          pname = "types-curses";
          version = "2.0.2";
          sha256 = "sha256-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=";
        }
        # just add more attrsets here
      ];

  myPython = pkgs.python314.withPackages (_: extraPackages);
in
{
  environment.systemPackages = [ myPython ];
}
