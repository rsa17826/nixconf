{
  config,
  pkgs,
  uname,
  ...
}:
let
  updateCheck = pkgs.writeShellScriptBin "check-flake-updates" ''
    # Navigate to your config directory
    cd /home/${uname}/nixconf # or wherever your flake.nix is

    # Check if any inputs can be updated without actually writing to the lockfile
    UPDATES=$(nix flake check --no-build 2>&1 | wc -l)

    if [ "$UPDATES" -gt 0 ]; then
       echo "Update Available"
    else
       echo ""
    fi
  '';
in
{
  home.packages = [ updateCheck ];
  programs.waybar = {
    enable = true;
    systemd.enable = true; # Automatically starts waybar with the session

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;

        modules-left = [
          "hyprland/workspaces"
          "custom/notes"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "disk"
          "pulseaudio"
          "custom/github"
          "custom/notifications"
          "custom/update"
          "custom/power"
        ];

        # Hyprland Workspaces (New addition for Linux)
        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "active" = "";
            "default" = "";
          };
        };

        "clock" = {
          format = "<span color='rgba(0, 0, 0, 0.9)'></span> {:%A %d %B %Y %H:%M} <span color='rgba(0, 0, 0, 0.9)'></span>";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        "disk" = {
          interval = 60;
          format = " {percentage_used}%";
          path = "/";
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-muted = "󰝟 Muted";
          format-icons = [
            "󰕿"
            "󰖀"
            "󰕾"
          ];
          on-click = "pavucontrol";
        };

        "custom/notes" = {
          format = "󰔌";
          on-click = "thunar ~/Documents/notes"; # Replacement for Windows notes
        };

        "custom/github" = {
          format = "{output}"; # output from the script
          interval = 300; # refresh every 5 minutes
          exec = "github-widget"; # run your script
          on-click = "xdg-open https://github.com/notifications";
          tooltip = "GitHub Notifications";
        };

        "custom/notifications" = {
          format = "";
          on-click = "swaync-client -t -sw";
        };

        "custom/update" = {
          format = " {}";
          interval = 3600;
          exec = "updateCheck"; # Basic NixOS update check
          on-click = "updateCheck";
        };

        "custom/power" = {
          format = "";
          on-click = "wlogout";
        };
      };
    };

    style = ''
      @define-color red #ff4d4d;
      @define-color yellow #f9e2af;
      @define-color blue #89b4fa;
      @define-color text #c3c3c3;

      * {
        font-family: "JetBrainsMono NFP";
        font-size: 14px;
        font-weight: 600;
        border: none;
      }

      window#waybar {
        background-color: rgba(0, 0, 0, 0);
        color: @text;
      }

      #workspaces, #clock, #disk, #pulseaudio, #custom-github, 
      #custom-notifications, #custom-power, #custom-update, #custom-notes {
        padding: 0 10px;
        margin: 0 4px;
        background-color: rgba(0, 0, 0, 0.0);
      }

      #clock {
        color: rgba(157, 0, 0, 0.643);
        background-color: rgba(0, 0, 0, 0.9);
        font-weight: 600;
      }

      #custom-github {
        color: red;
        font-weight: bold;
      }

      #workspaces button.active {
        color: @red;
        border-bottom: 2px solid @red;
      }

      #custom-power {
        color: #f38ba8;
      }
    '';
  };
}
