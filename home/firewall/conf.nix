{ ... }:
{
  networking.firewall.allowedTCPPorts = [
    8086
    1234
    9564
  ];
  networking.firewall.allowedUDPPorts = [
    1234
  ];
}
