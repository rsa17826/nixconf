{ userConfig, ... }:
{
  services.copyparty = {
    enable = true;
    # the user to run the service as
    user = "${userConfig.uname}";
    # the group to run the service as
    group = "copyparty";
    # directly maps to values in the [global] section of the copyparty config.
    # see `copyparty --help` for available options
    settings = {
      i = "0.0.0.0";
      # use lists to set multiple values
      p = [
        8086
      ];
      # use booleans to set binary flags
      no-reload = true;
    };

    # create users
    accounts = {
      admin.passwordFile = "/home/${userConfig.uname}/a";
      s.passwordFile = "/home/${userConfig.uname}/s";
    };

    volumes = {
      "/" = {
        path = "/home/${userConfig.uname}/copyparty";
        access = {
          rwm = "*";
          A = [
            "admin"
          ];
        };
        flags = {
          fk = 4;
          scan = 60;
          # volflag "e2d" enables the uploads database
          e2d = true;
          # "d2t" disables multimedia parsers (in case the uploads are malicious)
          d2t = true;
          # skips hashing file contents if path matches *.iso
          nohash = "\.iso$";
          nodupe = true;
        };
      };
      "/s" = {
        path = "/home/${userConfig.uname}/copypartyS";
        access = {
          rwmd = "s";
          A = [
            "admin"
          ];
        };
        flags = {
          fk = 4;
          scan = 60;
          # volflag "e2d" enables the uploads database
          e2d = true;
          nodupe = true;
        };
      };
    };
    # you may increase the open file limit for the process
    openFilesLimit = 8192;
  };
}
