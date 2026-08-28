{ pkgs, ... }:

let
  pythonEnv = pkgs.python314;
in
pkgs.stdenv.mkDerivation {
  pname = "webfs";
  version = "1.0";

  src = ./.;

  # NativeBuildInputs for tools used during the build
  nativeBuildInputs = [ pkgs.makeWrapper ];
  buildInputs = [ pythonEnv ];

  installPhase = ''
    mkdir -p $out/bin
    cp webfs.py $out/bin/webfs.py

    # Create a wrapper that calls python with your script
    makeWrapper ${pythonEnv}/bin/python $out/bin/webfs \
      --add-flags "$out/bin/webfs.py" \
  '';
}
