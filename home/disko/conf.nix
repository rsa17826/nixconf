{ lib, ... }:
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda"; # TODO adjust your target
    content = {
      type = "gpt";
      partitions = {
        esp = {
          size = "2G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };

        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            content = {
              type = "ext4";
              extraArgs = [ "--label disk-main-luks" ]; # Add this if it keeps failing
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  #mountOptions = [
                  #  "compress=zstd"
                  #  "noatime"
                  #];
                };
                "@home" = {
                  mountpoint = "/home";
                };
                "@persist" = {
                  mountpoint = "/persist";
                };
                "@nix" = {
                  mountpoint = "/nix";
                };
"@swap" = {
  mountpoint = "/.swapvol";
  swap = {
    swapfile = {
      size = "8G"; # Matches your RAM to help with heavy builds
    };
  };
};
              };
            };
          };
        };
      };
    };
  };
}
