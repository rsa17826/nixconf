{ pkgs, ... }:
let
  folderScript = pkgs.writeShellApplication {
    name = "folder-thumbnailer";
    runtimeInputs = with pkgs; [
      exiv2
      imagemagick
    ];
    text = ''
      magick "$2/.foldericon.png" -thumbnail "$1" "$3" 2>/dev/null && exit 0
      # rm -f \
      #   "$HOME/.cache/thumbnails/normal/$(printf '%s' "$4" | md5sum | cut -d ' ' -f1).png" \
      #   "$HOME/.thumbnails/normal/$(printf '%s' "$4" | md5sum | cut -d ' ' -f1).png" \
      #   "$HOME/.cache/thumbnails/large/$(printf '%s' "$4" | md5sum | cut -d ' ' -f1).png" \
      #   "$HOME/.thumbnails/large/$(printf '%s' "$4" | md5sum | cut -d ' ' -f1).png"
      exit 1
    '';
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
  environment.systemPackages = [ folderThumbnailer ];
}
