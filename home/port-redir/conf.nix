{ lib, ... }:
let
  # Per-service options:
  #   name    - hostname prefix (<name>.localhost)
  #   port    - default port for both sides
  #   public  - true -> reachable from LAN/WAN, false -> loopback only
  #   https   - (optional, default false) also serve over TLS:
  #               https://<name>.localhost            (port 443, by SNI)
  #               https://<host>:<httpsPort>            (only meaningful if public)
  #   httpPort  - (optional, default port) port the backend really listens on
  #   httpsPort - (optional, default port) port clients use. Without https this is
  #             the backend port itself (exposed directly through the firewall).
  #             With https and public, nginx binds 0.0.0.0:httpsPort, so it MUST differ
  #             from httpPort (otherwise the backend and nginx fight for the port).
  #
  # Example:  { name = "ap"; port = 38281; public = true; https = true; httpPort = 38280; httpsPort = 38281; }
  #           -> backend moves to 38280, https://192.168.1.124:38281 is nginx+TLS.
  #
  # The certificate must cover *.localhost and the LAN IP(s) you use, e.g.
  #   mkcert "*.localhost" localhost 127.0.0.1 ::1 192.168.1.124
  certFile = ./cws.localhost+3.pem;
  certKeyFile = ./cws.localhost+3-key.pem;

  rawRemaps = [
    {
      name = "timer";
      port = 8765;
      public = false;
    }
    {
      name = "pl2wba";
      port = 34283;
      public = false;
    }
    {
      name = "pl2wba-level-viewer";
      port = 52853;
      public = false;
    }
    {
      name = "tts";
      port = 47429;
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
      httpPort = 38281;
      httpsPort = 38280;
      public = true;
    }
    {
      name = "ap-slot-tracker";
      port = 54221;
      public = false;
    }
    {
      name = "fs";
      port = 54220;
      public = false;
    }
    {
      name = "copyparty";
      httpsPort = 8087;
      httpPort = 8086;
      public = true;
    }
    {
      name = "syncthing";
      port = 8384;
      public = false;
    }
    {
      name = "live-stream";
      port = 46049;
      public = false;
    }
    {
      name = "vex2";
      port = 4541;
      public = false;
    }
    {
      name = "multi-video-sync";
      port = 60907;
      public = false;
    }
  ];

  # Fill in derived fields (https/httpPort/httpsPort are optional in the list above).
  remaps = map (
    r:
    let
      https = !!(r.httpsPort > 0);
      httpPort = r.httpPort or r.port;
      httpsPort = r.httpsPort or r.port;
    in
    assert lib.assertMsg (!(https && r.public && httpPort == httpsPort))
      "${r.name}: https+public needs httpPort != httpsPort (nginx and the backend can't both bind ${toString httpsPort})";
    r // { inherit https httpPort httpsPort; }
  ) rawRemaps;

  publicRemaps = builtins.filter (r: r.public) remaps;

  # What the dashboards link to (local dashboard uses the hostname forms).
  listItem =
    r:
    "<li><a href=\"//${r.name}.localhost\" data-port=\"${toString r.httpsPort}\" data-https=\"${if r.https then "1" else "0"}\">${r.name}</a></li>";

  localListItem =
    r:
    "<li><a href=\"${if r.https then "https" else "http"}://${r.name}.localhost\">${r.name}</a></li>";

  # Local dashboard (served on 127.0.0.1): show everything, since only
  # someone on the machine itself can reach this page in the first place.
  localIndexHtml = ''
    <!DOCTYPE html>
    <html>
      <head><title>Service Dashboard (local)</title></head>
      <body>
        <h1>Available Services (local access)</h1>
        <ul>
          ${lib.concatStringsSep "\n" (map localListItem remaps)}
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
        <script>
          document.addEventListener("DOMContentLoaded", function() {
            document.querySelectorAll("a").forEach(e=>e.href = (e.dataset.https == "1" ? "https:" : "http:") + "//" + window.location.hostname + ":" + e.dataset.port)
          });
        </script>
      </body>
    </html>
  '';

  loopback = [
    "127.0.0.1"
    "[::1]"
  ];
  wildcard = [
    "0.0.0.0"
    "[::]"
  ];

  mkListen =
    r:
    let
      plain = map (addr: {
        inherit addr;
        port = 80;
      }) (if r.public then wildcard ++ loopback else loopback);
      # https://<name>.localhost on 443 (SNI picks the vhost)
      tlsHost = map (addr: {
        inherit addr;
        port = 443;
        ssl = true;
      }) (if r.public then wildcard ++ loopback else loopback);
      # https://<ip>:<httpsPort>, only for public services
      tlsPort = map (addr: {
        inherit addr;
        port = r.httpsPort;
        ssl = true;
      }) wildcard;
    in
    plain ++ lib.optionals r.https (tlsHost ++ lib.optionals r.public tlsPort);

in
{
  services = {
    nginx = {
      enable = true;
      clientMaxBodySize = "128m";
      eventsConfig = ''
        worker_connections 1024;
      '';
      virtualHosts =
        (lib.listToAttrs (
          map (r: {
            name = "${r.name}.localhost";
            value = {
              listen = mkListen r;
              addSSL = r.https;
              sslCertificate = lib.mkIf r.https certFile;
              sslCertificateKey = lib.mkIf r.https certKeyFile;
              locations = {
                "/" = {
                  proxyPass = "http://127.0.0.1:${toString r.httpPort}";
                  proxyWebsockets = true;

                  extraConfig = ''
                    proxy_set_header Host $host;
                    proxy_set_header X-Forwarded-Host $http_host;
                    proxy_set_header X-Forwarded-Proto $scheme;

                    if ($request_method = 'OPTIONS') {
                      add_header 'Access-Control-Allow-Origin' '*';
                      add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, OPTIONS';
                      add_header 'Access-Control-Allow-Headers' 'Content-Type';
                      add_header 'Content-Length' 0;
                      add_header 'Content-Type' 'text/plain charset=UTF-8';
                      return 204;
                    }

                    add_header 'Access-Control-Allow-Origin' '*' always;
                    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, OPTIONS' always;
                    add_header 'Access-Control-Allow-Headers' 'Content-Type' always;
                  '';
                };
              };
            };
          }) remaps
        ))
        // {
          "chromewebstore.google.com" = {
            addSSL = true;
            sslCertificate = certFile;
            sslCertificateKey = certKeyFile;
            locations = {
              "/" = {
                return = "302 https://cws.localhost$request_uri";
              };
            };
          };
          "cws.localhost" = {
            addSSL = true;
            sslCertificate = certFile;
            sslCertificateKey = certKeyFile;
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
      ++ map (x: x.httpsPort) publicRemaps;
    };
  };
}
