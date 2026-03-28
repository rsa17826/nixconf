{ pkgs, ... }:

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
    # This forces Codium to be the FIRST choice
    defaultApplications = {
      "application/x-sds" = [ "codium.desktop" ];
    };
    # This explicitly tells Linux NOT to use LibreOffice for this type
    removedAssociations = {
      "application/x-sds" = [
        "writer.desktop"
        "libreoffice-writer.desktop"
      ];
    };
  };
}
