{ pkgs, ... }:

{
  # Register the MIME type system-wide
  environment.etc."share/mime/packages/sds.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
      <mime-type type="application/x-sds">
        <comment>SDS File</comment>
        <glob pattern="*.sds"/>
      </mime-type>
    </mime-info>
  '';

  # Set the association
  xdg.mime.defaultApplications = {
    "application/x-sds" = "codium.desktop";
  };
}