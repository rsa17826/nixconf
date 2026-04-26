{ pkgs, lib, ... }:
{
  # 1. Define the MIME type correctly for Home Manager
  # This puts it in ~/.local/share/mime/packages/sds.xml
  xdg.dataFile."mime/packages/sds.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
      <mime-type type="application/x-sds">
        <comment>SDS File</comment>
        <glob pattern="*.sds"/>
      </mime-type>
    </mime-info>
  '';

  # 2. Set the default application
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/x-sds" = [ "codium.desktop" ];
      "application/json" = [ "codium.desktop" ];
      "application/vnd.stardivision.chart" = [ "codium.desktop" ];
      "text/plain" = "browser-selector.desktop";
      "text/html" = "browser-selector.desktop";
      "text/xml" = "browser-selector.desktop";
      "text/mhtml" = "browser-selector.desktop";
      "application/xhtml+xml" = "browser-selector.desktop";
      "application/xml" = "browser-selector.desktop";
      "application/pdf" = "browser-selector.desktop";
      "application/rss+xml" = "browser-selector.desktop";
      "application/atom+xml" = "browser-selector.desktop";
      "x-scheme-handler/http" = "browser-selector.desktop";
      "x-scheme-handler/https" = "browser-selector.desktop";
      "x-scheme-handler/ftp" = "browser-selector.desktop";
      "x-scheme-handler/chrome" = "browser-selector.desktop";
      "x-scheme-handler/about" = "browser-selector.desktop";
      "x-scheme-handler/unknown" = "browser-selector.desktop";
      "audio/webm" = "browser-selector.desktop";
      "video/webm" = "browser-selector.desktop";
      "video/mp4" = "browser-selector.desktop";
      "audio/mp4" = "browser-selector.desktop";
    };
  };
  # Rebuild MIME database after HM places the XML
  # home.activation.updateMimeDatabase = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #   ${pkgs.shared-mime-info}/bin/update-mime-database \
  #     "$HOME/.local/share/mime"
  # '';
}
