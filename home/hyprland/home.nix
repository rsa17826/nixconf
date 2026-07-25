{
  userConfig,
  lib,
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
        # Only files whose sha256 matches conf/windowrule_requests/approved_hashes.json
        # get symlinked into the location Hyprland actually loads from.
        # New/changed files are blocked and reported here instead of
        # silently taking effect. Approve with:
        #   approve_windowrule.py <filename.lua>
        $DRY_RUN_CMD python3 \
          "$nixconf/home/hyprland/scripts/check_windowrule_hashes.py" \
          "$nixconf/home/hyprland/conf/windowrule_requests"# || true
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
