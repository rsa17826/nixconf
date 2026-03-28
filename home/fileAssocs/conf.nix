{ pkgs, ... }:

{
  xdg.mimeData.enable = true;

  # Create the definition file in the user's profile
  xdg.dataFile."mime/packages/sds.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
      <mime-type type="application/x-sds">
        <comment>SDS File</comment>
        <glob pattern="*.sds"/>
      </mime-type>
    </mime-info>
  '';
}
