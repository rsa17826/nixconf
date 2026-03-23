{ pkgs, ... }:

let
  # The standard Chrome Web Store update URL
  storeUrl = "https://clients2.google.com/service/update2/crx";
in
{
  # 2. Use the Chromium module only for the Policies/Extensions
  programs.chromium = {
    enable = true;

    extraOpts = {
      "CommandLineFlagSecurityWarningsEnabled" = false;
      "ExtensionsOnChromeURLsEnabled" = true;

      "ExtensionSettings" = {
        # DeArrow
        "nebjniochfgmgoadjlnelfggcmomgopf" = {
          "installation_mode" = "force_installed";
          "update_url" = "${storeUrl}";
        };
        # LibRedirect
        "oladmjdebphlnjjcnomfhhbfdldiimaf" = {
          "installation_mode" = "force_installed";
          "update_url" = "${storeUrl}";
        };
        # Stylus
        "clngdbkpkpeebahjckkjfobafhncgmne" = {
          "installation_mode" = "force_installed";
          "update_url" = "${storeUrl}";
          "file_url_navigation_allowed" = true;
        };
        # Violentmonkey
        "gindolcalhpefcmpmladkchjkfonglfa" = {
          "installation_mode" = "force_installed";
          "update_url" = "${storeUrl}";
          "file_url_navigation_allowed" = true;
          "runtime_allowed_hosts" = [
            "https://*"
            "http://*"
            "file://*"
          ];
        };
        # XDM
        "baejcnbldekpcbiogipmdeohckapojkf" = {
          "installation_mode" = "force_installed";
          "update_url" = "${storeUrl}";
          "file_url_navigation_allowed" = true;
        };
        # SponsorBlock
        "mnjggcdmjocbbbhaepdhchncahnbgone" = {
          "installation_mode" = "force_installed";
          "update_url" = "${storeUrl}";
        };
        # Redirector
        "ocgpenflpmgnfapjedencafcfakcekcd" = {
          "installation_mode" = "force_installed";
          "update_url" = "${storeUrl}";
        };

        # Generic force-installs for the rest
        "edibdbjcniadpccecjdfdjjppcpchdlm" = {
          "installation_mode" = "force_installed";
          "update_url" = "https://clients2.google.com/service/update2/crx";
        };
        "ejddcgojdblidajhngkogefpkknnebdh" = {
          "installation_mode" = "force_installed";
          "update_url" = "https://clients2.google.com/service/update2/crx";
        };
        "jcokkipkhhgiakinbnnplhkdbjbgcgpe" = {
          "installation_mode" = "force_installed";
          "update_url" = "https://clients2.google.com/service/update2/crx";
        };
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
