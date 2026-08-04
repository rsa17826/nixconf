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
  ];

  # Generate HTML list items for the index page
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
              "<li><a href=\"http://${name}.127.0.0.1\">${name}</a></li>"
            ) remaps
          )}
        </ul>
      </body>
    </html>
  '';
in
{
  services = {
    nginx = {
      enable = true;

      # Define a default virtual host to catch requests to http://127.0.0.1/
      virtualHosts."_" = {
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

      # Your existing dynamic virtual hosts for the subdomains
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
    extraHosts = lib.concatStringsSep "\n" (
      map (pair: "127.0.0.1 ${builtins.elemAt pair 0}.127.0.0.1") remaps
    );
  };
}
