{ ... }:
{
  networking = {
    firewall = {
      allowedTCPPorts = [
        8086
        1234
        9564
        22000
        1716
        59100
        59200
        65530
      ];
      allowedUDPPorts = [
        1234
        22000
        21027
        1716
        59100
        59200
        65530
      ];
    };
  };
}
