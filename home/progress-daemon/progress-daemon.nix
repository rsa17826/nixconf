{ pkgs }:

let
  # Create a custom python environment with tkinter
  pythonEnv = pkgs.python3.withPackages (ps: [ ps.tkinter ]);
in
pkgs.stdenv.mkDerivation {
  pname = "progress-daemon";
  version = "1.0";

  # Point this to the folder containing your script
  src = ./.;

  # We only need the python environment to run it
  buildInputs = [ pythonEnv ];

  installPhase = ''
    mkdir -p $out/bin
    # Copy the script to the store
    cp progress-daemon.py $out/bin/progress-daemon
    chmod +x $out/bin/progress-daemon

    # Wrap the script so it always uses our specific pythonEnv
    sed -i "1c\#!${pythonEnv}/bin/python" $out/bin/progress-daemon
  '';
}
