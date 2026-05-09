{ pkgs, ... }:
let
  folderScript = pkgs.writeShellApplication {
    name = "folder-thumbnailer";
    runtimeInputs = with pkgs; [
      exiv2
      imagemagick
    ];
    text = builtins.readFile ./main.sh;
  };

  folderThumbnailer = pkgs.symlinkJoin {
    name = "folder-thumbnailer";
    paths = [
      folderScript
      (pkgs.writeTextFile {
        name = "folder-thumbnailer-thumbnailer";
        destination = "/share/thumbnailers/folder-thumbnailer.thumbnailer";
        text = ''
            [Thumbnailer Entry]
          Version=1.0
            Encoding=UTF-8
            Type=X-Thumbnailer
            Name=Folder Thumbnailer
            MimeType=inode/directory;
            Exec=${folderScript}/bin/folder-thumbnailer %s %i %o %u
        '';
      })
    ];
  };
in
{
  environment = {
    systemPackages = [ folderThumbnailer ];
  };
}
