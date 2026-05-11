{ lib, ... }:
{
  programs = {
    chromium = {
      enable = true;

      extraOpts = {
        "DeveloperToolsAvailability" = 1;
        "CommandLineFlagSecurityWarningsEnabled" = false;
        "ExtensionSettings" =
          lib.genAttrs
            [
              "mnjggcdmjocbbbhaepdhchncahnbgone"
              "ocgpenflpmgnfapjedencafcfakcekcd"
              "icallnadddjmdinamnolclfjanhfoafe"
              "edibdbjcniadpccecjdfdjjppcpchdlm"
              "eimadpbcbfnmbkopoojfekhnkhdbieeh"
              "ejddcgojdblidajhngkogefpkknnebdh"
              "fbeffbjdlemaoicjdapfpikkikjoneco"
              "donbcfbmhbcapadipfkeojnmajbakjdc"
            ]
            (k: {
              installation_mode = "force_installed";
              update_url = "https://clients2.google.com/service/update2/crx";
            });
      };
    };
  };
}

# ~/chrome extensions/dearrow
# nebjniochfgmgoadjlnelfggcmomgopf

# ~/chrome extensions/libredirect
# oladmjdebphlnjjcnomfhhbfdldiimaf

# ~/chrome extensions/stylus
# clngdbkpkpeebahjckkjfobafhncgmne

# ~/chrome extensions/violentmonkey
# gindolcalhpefcmpmladkchjkfonglfa

# edibdbjcniadpccecjdfdjjppcpchdlm

# ~/chrome extensions/xdm NEW extension
# baejcnbldekpcbiogipmdeohckapojkf

# ejddcgojdblidajhngkogefpkknnebdh
# ocgpenflpmgnfapjedencafcfakcekcd
# mnjggcdmjocbbbhaepdhchncahnbgone

# jcokkipkhhgiakinbnnplhkdbjbgcgpe
