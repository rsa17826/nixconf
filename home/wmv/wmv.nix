{ pkgs, ... }:

let
  pythonEnv = pkgs.python314;
in
pkgs.stdenv.mkDerivation {
  pname = "wmv";
  version = "1.0";

  src = ./.;

  # NativeBuildInputs for tools used during the build
  nativeBuildInputs = [ pkgs.makeWrapper ];
  buildInputs = [ pythonEnv ];

  installPhase = ''
    mkdir -p $out/bin
    cp wmv.py $out/bin/wmv.py

    # Create a wrapper that calls python with your script
    makeWrapper ${pythonEnv}/bin/python $out/bin/wmv \
      --add-flags "$out/bin/wmv.py" \
  '';
}
