{ lib, ... }:
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";  # TODO adjust your target
    content = {
      type = "gpt";
      partitions = {
        esp = {
          size = "2G";
          type = "EF00";  # UEFI partition
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };

        root = {
          size = "100%";  # Use all remaining space for the root partition
          content = {
            type = "filesystem";
            format = "ext4";  # Or you can use "xfs" or any other filesystem type
            mountpoint = "/";
            # You can add extra arguments here like "noatime", "compress=zstd", etc.
          };
        };

        home = {
          size = "50G";  # Specify a size for /home or adjust as needed
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/home";
          };
        };

        nix = {
          size = "20G";  # Specify a size for /nix or adjust as needed
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/nix";
          };
        };

        swap = {
          size = "8G";  # Size for swap (same as the one in your original setup)
          content = {
            type = "swap";
          };
        };
      };
    };
  };
}
