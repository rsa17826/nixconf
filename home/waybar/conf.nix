{
  config,
  pkgs,
  uname,
  ...
}:
{
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
          format = "<span color='#000000e6'></span> {:%A %d %B %Y %H:%M:%S} <span color='#000000e6'></span>";
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

        "custom/github" = {
          format = ""; # output from the script
          interval = 30;
          exec = "sudo -n github-widget"; # run your script
          on-click = "xdg-open https://github.com/notifications";
          tooltip = "GitHub Notifications";
        };

        "custom/notifications" = {
          format = "";
          on-click = "swaync-client -t -sw";
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
        font-weight: 900;
        border: none;
      }

      window#waybar {
        background-color: rgba(0, 0, 0, 0);
        color: @text;
      }

      #workspaces, #clock, #disk, #pulseaudio, #custom-github, 
      #custom-notifications, #custom-power, #custom-notes {
        padding: 0 2px;
        margin: 0 2px;
        background-color: rgba(0, 0, 0, 0.0);
      }
      #custom-power{
        margin-right:10px;
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
