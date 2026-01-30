{uname}:
{
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib"
      "/var/log"
      "/etc/ssh"
      "/home/${uname}/nixconf"
    ];
    files = [
      "/etc/machine-id"
    ];
  };
}
