{
  userConfig,
  lib,
  pkgs,
  ...
}:
{
  myProfile = {
    editableConfigs = [
      {
        name = "hypr";
        src = ./.;
        srcStr = "${userConfig.nixConf}/home/hyprland";
        destDir = ".config/hypr";
        files = [
          "hyprland.lua"
          "hyprlock.conf"
        ];
        dirs = [
          "shaders"
          "wallpapers"
          "conf"
          "scripts"
        ];
      }
    ];
  };
  home = {
    activation = {
      enableAllScripts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        nixconf="${userConfig.nixConf}"
        chmod +x "$nixconf/home/hyprland/scripts/"*.sh
        chmod +x "$nixconf/home/hyprland/scripts/"*.py
      '';
      checkWindowRuleHashes = lib.hm.dag.entryAfter [ "enableAllScripts" ] ''
        nixconf="${userConfig.nixConf}"
        # Every *.lua in conf/windowrule_requests/ must have a matching
        # sha256 in approved_hashes.json. Missing entry, mismatched
        # hash, or DENIED all fail this activation step outright.
        # Approve at runtime via the windowrule-daemon notification, or
        # by hand-editing approved_hashes.json.
        $DRY_RUN_CMD ${pkgs.python3}/bin/python3 \
          "$nixconf/home/hyprland/scripts/check_windowrule_hashes.py" \
          "$nixconf/home/hyprland/conf/windowrule_requests"
      '';
    };
  };
  services = {
    hyprpaper = {
      enable = false;
    };
  };

  # xdg.configFile."hypr/hm.conf".text = ''
  #   plugin = hypr-darkwindow.packages.${pkgs.stdenv.hostPlatform.system}.Hypr-DarkWindow
  # '';

  # // (
  #   # Map over the files in the ./shaders directory
  #   builtins.mapAttrs (name: value: {
  #     source = ln "${userConfig.nixConf}/home/hyprland/shaders/${name}";
  #   }) (builtins.readDir ./shaders)
  # );
  #    echo "Linking hyprland settings..."

  #    mkdir -p "$HOME/.config/hypr"
  #    #rm "$HOME/.config/hypr/hyprland.conf" >& /dev/null
  #    ln -f "$HOME/nixconf/home/hyprland/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"
  #  '';
  # xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;
}
