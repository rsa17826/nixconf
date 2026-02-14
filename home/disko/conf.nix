{ lib, ... }:
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/ata-VBOX_HARDDISK_VB2C6885fc-f3c0c4ad"; # TODO adjust your target
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
              type = "btrfs";
              extraFormatArgs = [ "--label disk-main-luks" ]; # Add this if it keeps failing
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
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
              };
            };
          };
        };
      };
    };
  };
}
