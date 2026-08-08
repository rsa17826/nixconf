{ lib, ... }:
let
  remaps = [
    [
      "timer"
      8765
    ]
    [
      "nullserv"
      7542
    ]
    [
      "mathquest"
      1533
    ]
    [
      "ap"
      38281
    ]
    [
      "copyparty"
      8086
    ]
    [
      "syncthing"
      8384
    ]
  ];

  # Generate HTML list items using .localhost
  indexHtml = ''
    <!DOCTYPE html>
    <html>
      <head><title>Service Dashboard</title></head>
      <body>
        <h1>Available Services</h1>
        <ul>
          ${lib.concatStringsSep "\n" (
            map (
              pair:
              let
                name = builtins.elemAt pair 0;
              in
              "<li><a href=\"http://${name}.localhost\">${name}</a></li>"
            ) remaps
          )}
          <li><a href="https://cws.localhost">chromewebstore (CWS)</a></li>
        </ul>
      </body>
    </html>
  '';
in
{
  services = {
    nginx = {
      enable = true;

      virtualHosts =
        (lib.listToAttrs (
          map (
            pair:
            let
              name = builtins.elemAt pair 0;
              port = builtins.elemAt pair 1;
            in
            {
              # Changed from .127.0.0.1 to .localhost
              name = "${name}.localhost";
              value = {
                locations = {
                  "/" = {
                    proxyPass = "http://127.0.0.1:${toString port}";
                    proxyWebsockets = true;
                    extraConfig = ''
                      proxy_set_header Host $host;
                      proxy_set_header X-Forwarded-Host $http_host;
                      proxy_set_header X-Forwarded-Proto $scheme;
                    '';
                  };
                };
              };
            }
          ) remaps
        ))
        // {
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
          "_" = {
            default = true;
            locations = {
              "/" = {
                return = "200 '${indexHtml}'";
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
        map (
          pair: "127.0.0.1 ${builtins.elemAt pair 0}.localhost\n127.0.0.1 ${builtins.elemAt pair 0}.127.0.0.1"
        ) remaps
      )
      + "\n127.0.0.1 cws.localhost";
  };
}
