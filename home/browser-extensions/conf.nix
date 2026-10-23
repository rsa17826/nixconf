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
              "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock for YouTube - Skip Sponsorships
              "icallnadddjmdinamnolclfjanhfoafe" # FastForward
              "cclelndahbckbenkjhflpdbgdldlbecc" # Get cookies.txt LOCALLY
              "edibdbjcniadpccecjdfdjjppcpchdlm" # I still don't care about cookies
              "fbeffbjdlemaoicjdapfpikkikjoneco" # Scratch Addons
              "donbcfbmhbcapadipfkeojnmajbakjdc" # Ruffle - Flash Emulator
            ]
            (k: {
              installation_mode = "force_installed";
              update_url = "https://clients2.google.com/service/update2/crx";
            });
      };
    };
  };
}

# edibdbjcniadpccecjdfdjjppcpchdlm

# mnjggcdmjocbbbhaepdhchncahnbgone

# jcokkipkhhgiakinbnnplhkdbjbgcgpe
