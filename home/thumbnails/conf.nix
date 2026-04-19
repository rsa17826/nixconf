{ pkgs, ... }:
let
  folderScript = pkgs.writeShellApplication {
    name = "folder-thumbnailer";
    runtimeInputs = with pkgs; [
      exiv2
      imagemagick
    ];
    text = ''
      #!${pkgs.bash}/bin/bash
      #!/usr/bin/env bash
      magick -thumbnail "$1" "$2/folder.png" "$3" 1>/dev/null 2>&1 ||\
      magick -thumbnail "$1" "$2/.folder.png" "$3" 1>/dev/null 2>&1 ||\
      rm -f "$HOME/.cache/thumbnails/normal/$(echo -n "$4" | md5sum | cut -d " " -f1).png" ||\
      rm -f "$HOME/.thumbnails/normal/$(echo -n "$4" | md5sum | cut -d " " -f1).png" ||\
      rm -f "$HOME/.cache/thumbnails/large/$(echo -n "$4" | md5sum | cut -d " " -f1).png" ||\
      rm -f "$HOME/.thumbnails/large/$(echo -n "$4" | md5sum | cut -d " " -f1).png" ||\
      exit 1
    '';
  };
in
{
  environment.systemPackages = [
    folderScript
    (pkgs.writeTextFile {
      name = "folder-thumbnailer.thumbnailer";
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
}
