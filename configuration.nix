# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help’).

{
  # config,
  pkgs,
  uname,
  ...
}:
# let
#   unstable =
#     import
#       (builtins.fetchTarball {
#         url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
#         # optional: pin for reproducibility
#         # sha256 = "sha256-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=";
#       })
#       {
#         config = config.nixpkgs.config;
#         system = pkgs.system;
#       };
# in
{
  
}
