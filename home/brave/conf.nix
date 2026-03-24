{ userConfig, pkgs, ... }:

let
  mkCrx =
    {
      name,
      src,
      keyPath,
      version,
    }:
    pkgs.stdenv.mkDerivation {
      pname = name;
      inherit version;
      inherit src;

      nativeBuildInputs = [ pkgs.go-crx3 ];

      buildPhase = ''
        crx3 pack $src -o ${name}.crx
      '';
      installPhase = ''
        mkdir -p $out
        cp ${name}.crx $out/
      '';
    };
in
{
  # 2. Use the Chromium module only for the Policies/Extensions
  programs.chromium = {
    enable = true;

    extensions = [
      (mkCrx {
        name = "dearrow";
        src = "/home/${userConfig.uname}/chrome extensions/dearrow";
        id = "nebjniochfgmgoadjlnelfggcmomgopf";
        crxPath = "/home/share/extension.crx";
        version = "2.1.11";
      })
    ];
    # extraOpts = {
    #   "CommandLineFlagSecurityWarningsEnabled" = false;
    #   "ExtensionsOnChromeURLsEnabled" = true;

    #   "ExtensionSettings" = {
    #     # DeArrow
    #     "nebjniochfgmgoadjlnelfggcmomgopf" = {
    #       "installation_mode" = "force_installed";
    #       "update_url" = "${storeUrl}";
    #     };
    #     # LibRedirect
    #     "oladmjdebphlnjjcnomfhhbfdldiimaf" = {
    #       "installation_mode" = "force_installed";
    #       "update_url" = "${storeUrl}";
    #     };
    #     # Stylus
    #     "clngdbkpkpeebahjckkjfobafhncgmne" = {
    #       "installation_mode" = "force_installed";
    #       "update_url" = "${storeUrl}";
    #       "file_url_navigation_allowed" = true;
    #     };
    #     # Violentmonkey
    #     "gindolcalhpefcmpmladkchjkfonglfa" = {
    #       "installation_mode" = "force_installed";
    #       "update_url" = "${storeUrl}";
    #       "file_url_navigation_allowed" = true;
    #     };
    #     # XDM
    #     "baejcnbldekpcbiogipmdeohckapojkf" = {
    #       "installation_mode" = "force_installed";
    #       "update_url" = "${storeUrl}";
    #       "file_url_navigation_allowed" = true;
    #     };
    #     # SponsorBlock
    #     "mnjggcdmjocbbbhaepdhchncahnbgone" = {
    #       "installation_mode" = "force_installed";
    #       "update_url" = "${storeUrl}";
    #     };
    #     # Redirector
    #     "ocgpenflpmgnfapjedencafcfakcekcd" = {
    #       "installation_mode" = "force_installed";
    #       "update_url" = "${storeUrl}";
    #     };

    #     # Generic force-installs for the rest
    #     "edibdbjcniadpccecjdfdjjppcpchdlm" = {
    #       "installation_mode" = "force_installed";
    #       "update_url" = "https://clients2.google.com/service/update2/crx";
    #     };
    #     "eimadpbcbfnmbkopoojfekhnkhdbieeh" = {
    #       "installation_mode" = "force_installed";
    #       "update_url" = "https://clients2.google.com/service/update2/crx";
    #     };
    #     "ejddcgojdblidajhngkogefpkknnebdh" = {
    #       "installation_mode" = "force_installed";
    #       "update_url" = "https://clients2.google.com/service/update2/crx";
    #     };
    #     "jcokkipkhhgiakinbnnplhkdbjbgcgpe" = {
    #       "installation_mode" = "force_installed";
    #       "update_url" = "https://clients2.google.com/service/update2/crx";
    #     };
    #   };
    # };
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
