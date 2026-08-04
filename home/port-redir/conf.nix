{ lib, ... }:
let
  remaps = [
    [
      "timer"
      8765
    ]
  ];
in
{
  services = {
    nginx = {
      enable = true;
      virtualHosts = lib.listToAttrs (
        map (
          pair:
          let
            name = builtins.elemAt pair 0;
            port = builtins.elemAt pair 1;
          in
          {
            name = "${name}.127.0.0.1";
            value = {
              locations = {
                "/" = {
                  proxyPass = "http://127.0.0.1:${toString port}";
                  proxyWebsockets = true;
                };
              };
            };
          }
        ) remaps
      );
    };
  };

  networking = {
    # firewall.allowedTCPPorts = [
    #   80
    #   443
    # ];
    extraHosts = lib.concatStringsSep "\n" (
      map (pair: "127.0.0.1 ${builtins.elemAt pair 0}.127.0.0.1") remaps
    );
  };
}
