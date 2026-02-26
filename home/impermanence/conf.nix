{ userConfig, ... }:
{
  environment.persistence."/persist" = {
    hideMounts = true; # Usually set to true to keep 'df -h' clean
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/ssh"
    ];
    files = [
      "/etc/machine-id"
    ];

    # Use the 'users' attribute within the system persistence
    # to handle home directory permissions automatically
    users.${userConfig.uname} = {
      directories = [
        "nixconf" # Path is relative to the user's home
        "Downloads"
        "Documents"
        ".local/share/direnv"
      ];
    };
  };
}
