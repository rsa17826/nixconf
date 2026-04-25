{ lib, pkgs, ... }:

{
  python314.override = [
    (pkgs.python314.withPackages (
      ps:
      (lib.map
        [
          {
            pname = "types-curses";
            version = "2.0.2";
            sha256 = "sha256-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=";
          }
        ]
        (
          {
            pname,
            version,
            sha256,
          }:
          {
            src = pkgs.python3Packages.fetchPypi {
              inherit pname version sha256;
            };
            doCheck = false;
          }
        )
      )
    ))
  ];
}
