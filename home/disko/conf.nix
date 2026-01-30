{ lib, ... }:
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1"; # TODO adjust your target
    content = {
      type = "gpt";
      partitions = {
        esp = {
          size = "512M";
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
