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
                  };
                };
              };
            }
          ) remaps
        ))
        // {
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
    extraHosts = lib.concatStringsSep "\n" (
      map (
        pair: "127.0.0.1 ${builtins.elemAt pair 0}.localhost\n127.0.0.1 ${builtins.elemAt pair 0}.127.0.0.1"
      ) remaps
    );
  };
}
