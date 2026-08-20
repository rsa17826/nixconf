{ lib, ... }:
let
  # Added `access`: "local"  -> nginx only accepts this vhost on 127.0.0.1
  #                 "public" -> nginx accepts it on 0.0.0.0 (and thus LAN/WAN too)
  # The backend proxy target is always 127.0.0.1:port regardless - `access`
  # only controls which nginx *frontend* socket will answer for that name.
  remaps = [
    {
      name = "timer";
      port = 8765;
      public = false;
    }
    {
      name = "nullserv";
      port = 7542;
      public = false;
    }
    {
      name = "mathquest";
      port = 1533;
      public = false;
    }
    {
      name = "mathquest2";
      port = 8061;
      public = false;
    }
    {
      name = "ap";
      port = 38281;
      public = true;
    }
    {
      name = "copyparty";
      port = 8086;
      public = true;
    }
    {
      name = "syncthing";
      port = 8384;
      public = false;
    }
    {
      name = "vex2";
      port = 4541;
      public = false;
    }
  ];

  publicRemaps = builtins.filter (r: r.public) remaps;

  listItem = r: "<li><a href=\"http://${r.name}.localhost\">${r.name}</a></li>";

  # Local dashboard (served on 127.0.0.1): show everything, since only
  # someone on the machine itself can reach this page in the first place.
  localIndexHtml = ''
    <!DOCTYPE html>
    <html>
      <head><title>Service Dashboard (local)</title></head>
      <body>
        <h1>Available Services (local access)</h1>
        <ul>
          ${lib.concatStringsSep "\n" (map listItem remaps)}
          <li><a href="https://cws.localhost">chromewebstore (CWS)</a></li>
        </ul>
      </body>
    </html>
  '';

  # Public dashboard (served on 0.0.0.0): only list the services that are
  # actually reachable from outside, so we're not advertising links that
  # will just 404/fall through to this same catch-all.
  publicIndexHtml = ''
    <!DOCTYPE html>
    <html>
      <head><title>Service Dashboard</title></head>
      <body>
        <h1>Available Services</h1>
        <ul>
          ${lib.concatStringsSep "\n" (map listItem publicRemaps)}
        </ul>
      </body>
    </html>
  '';

  mkListen =
    public:
    (
      if public then
        [
          {
            addr = "127.0.0.1";
            port = 80;
          }
        ]
      else
        [
          {
            addr = "0.0.0.0";
            port = 80;
          }
          {
            addr = "[::]";
            port = 80;
          }
        ]
    );
in
{
  services = {
    nginx = {
      enable = true;
      eventsConfig = ''
        worker_connections 1024;
      '';
      virtualHosts =
        (lib.listToAttrs (
          map (r: {
            name = "${r.name}.localhost";
            value = {
              listen = mkListen r.public;
              locations = {
                "/" = {
                  proxyPass = "http://127.0.0.1:${toString r.port}";
                  proxyWebsockets = true;
                  extraConfig = ''
                    proxy_set_header Host $host;
                    proxy_set_header X-Forwarded-Host $http_host;
                    proxy_set_header X-Forwarded-Proto $scheme;
                  '';
                };
              };
            };
          }) remaps
        ))
        // {
          "chromewebstore.google.com" = {
            addSSL = true;
            sslCertificate = ./cws.localhost+3.pem;
            sslCertificateKey = ./cws.localhost+3-key.pem;
            locations = {
              "/" = {
                return = "302 https://cws.localhost$request_uri";
              };
            };
          };
          "cws.localhost" = {
            addSSL = true;
            sslCertificate = ./cws.localhost+3.pem;
            sslCertificateKey = ./cws.localhost+3-key.pem;
            locations = {
              "/" = {
                extraConfig = ''
                  resolver 127.0.0.1:5353 valid=300s;
                  set $upstream chromewebstore.google.com;
                  proxy_pass https://$upstream;
                  proxy_set_header Host chromewebstore.google.com;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto $scheme;
                  proxy_ssl_server_name on;
                  proxy_ssl_name chromewebstore.google.com;
                  proxy_ssl_session_reuse off;
                  proxy_buffering off;
                  proxy_buffer_size 16k;
                  proxy_buffers 4 32k;
                  proxy_busy_buffers_size 64k;
                '';
              };
            };
          };

          # Catch-all when accessed via loopback: full dashboard.
          # This listen (127.0.0.1:80) is more specific than 0.0.0.0:80, so
          # nginx always prefers it for connections actually arriving on
          # loopback, regardless of Host header.
          "_local" = {
            default = true;
            listen = [
              {
                addr = "127.0.0.1";
                port = 80;
              }
              {
                addr = "[::1]";
                port = 80;
              }
            ];
            locations = {
              "/" = {
                return = "200 '${localIndexHtml}'";
                extraConfig = ''
                  add_header Content-Type text/html;
                '';
              };
            };
          };

          # Catch-all for everything else (LAN/WAN interfaces): public dashboard.
          "_public" = {
            default = true;
            listen = [
              {
                addr = "0.0.0.0";
                port = 80;
              }
              {
                addr = "[::]";
                port = 80;
              }
            ];
            locations = {
              "/" = {
                return = "200 '${publicIndexHtml}'";
                extraConfig = ''
                  add_header Content-Type text/html;
                '';
              };
            };
          };
        };
    };
  };

  networking = {
    # Update extraHosts to map .localhost domains to 127.0.0.1
    extraHosts =
      lib.concatStringsSep "\n" (
        map (r: "127.0.0.1 ${r.name}.localhost\n127.0.0.1 ${r.name}.127.0.0.1") remaps
      )
      + "\n127.0.0.1 cws.localhost";

    firewall = {
      allowedTCPPorts = [
        80
        443
      ]
      ++ lib.map (x: x.port) publicRemaps;
    };
  };
}
