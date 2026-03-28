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
    };
  };
  # Rebuild MIME database after HM places the XML
  home.activation.updateMimeDatabase = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.shared-mime-info}/bin/update-mime-database \
      "$HOME/.local/share/mime"
  '';

}
