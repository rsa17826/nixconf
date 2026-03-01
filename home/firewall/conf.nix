{ ... }:
{
  networking.firewall.allowedTCPPorts = [
    8086
    1234
  ];
  networking.firewall.allowedUDPPorts = [
    1234
  ];
}