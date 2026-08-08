{ pkgs, ... }:
{
  systemd = {
    timers = {
      unbound-adblock = {
        onSuccess = [ "unbound-restart-after-adblock.service" ];
        description = "Periodic unbound adblock list update";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitActiveSec = "1d";
          Persistent = true;
        };
      };
    };

    services = {
      unbound-restart-after-adblock = {
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          systemctl try-reload-or-restart unbound
        '';
      };

      unbound = {
        after = [ "systemd-tmpfiles-setup.service" ];
        wants = [ "systemd-tmpfiles-setup.service" ];
        preStart = ''
          touch /var/lib/unbound/adblock.conf
        '';
      };

      unbound-adblock = {
        description = "Update unbound adblock list";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = "unbound";
          Group = "unbound";
        };
        script = ''
          set -euo pipefail
          tmpfile=$(mktemp)
          ${pkgs.curl}/bin/curl -fsSL --doh-url https://9.9.9.9/dns-query "https://big.oisd.nl/unbound" -o "$tmpfile"
          ${pkgs.gnugrep}/bin/grep -q '^local-zone' "$tmpfile"
          mv "$tmpfile" /var/lib/unbound/adblock.conf
        '';
      };
    };
  };

  services = {
    unbound = {
      enable = true;
      settings = {
        remote-control = {
          control-enable = true;
        };
        forward-zone = [
          {
            name = ".";
            forward-addr = [ "127.0.0.1@5353" ];
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
          include = [
            "/var/lib/unbound/adblock.conf"
            (toString ./cws.conf)
          ];
        };
      };
    };
  };
}
