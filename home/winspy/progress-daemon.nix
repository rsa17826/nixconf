{ pkgs }:

let
  # Create a custom python environment with tkinter
  pythonEnv = pkgs.python3.withPackages (ps: [ ps.tkinter ]);
in
pkgs.stdenv.mkDerivation {
  pname = "winspy";
  version = "1.0";

  # Point this to the folder containing your script
  src = ./.;

  # We only need the python environment to run it
  buildInputs = [ pythonEnv ];

  installPhase = ''
    mkdir -p $out/bin
    # Copy the script to the store
    cp winspy.py $out/bin/winspy
    chmod +x $out/bin/winspy

    # Wrap the script so it always uses our specific pythonEnv
    sed -i "1c\#!${pythonEnv}/bin/python" $out/bin/winspy
  '';
}
