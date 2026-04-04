{ ... }:
{
  networking.firewall.allowedTCPPorts = [
    8086
    1234
    9564
    22000
  ];
  networking.firewall.allowedUDPPorts = [
    1234
    22000
    21027
  ];
}
