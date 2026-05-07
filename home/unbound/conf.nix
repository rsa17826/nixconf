{ pkgs, ... }:
{
  services.unbound = {
    enable = true;
    settings = {
      remote-control.control-enable = true;

      forward-zone = [
        {
          name = ".";
          forward-addr = [ "127.0.0.1@5353" ];
          # forward-no-cache = false;
        }
      ];
      server = {
        verbosity = 3;
        interface = [
          "127.0.0.1"
          "::1"
        ];
        access-control = [
          "127.0.0.0/8 allow"
          "::1 allow"
        ];
        do-not-query-localhost = false;
        harden-dnssec-stripped = true;
        harden-glue = true;
        harden-referral-path = false;
        val-clean-additional = true;
      };
    };
  };
}
