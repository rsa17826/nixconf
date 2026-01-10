{
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
          tooltip = false;
        };

        "clock" = {
          format = "<span color='#000000e6'></span> {:%A %d %B %Y %H:%M:%S} <span color='#000000e6'></span>";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        "disk" = {
          interval = 60;
          format = " {percentage_used}%";
          tooltip = false;
          path = "/";
        };

        "pulseaudio" = {
          format = "<span color='#89B4FA'>{icon}</span> {volume}%";
          format-muted = "<span color='#fa8989ff'>{󰝟}</span> Muted";
          format-icons = [
            "󰕿"
            "󰖀"
            "󰕾"
          ];
          tooltip = false;
          on-click = "pavucontrol";
        };

        "custom/github" = {
          format = "<span rise='-6000'></span>{}";
          interval = 300;
          exec = "github-widget"; # run your script
          on-click = "xdg-open https://github.com/notifications";
          tooltip = false;
          # tooltip-format = "{tooltip}";
        };

        "custom/notifications" = {
          format = "";
          tooltip = false;
          on-click = "swaync-client -t -sw";
        };

        "custom/power" = {
          format = "";
          tooltip = false;
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
        padding: 0 4px;
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
        color: @text;
        font-weight: bold;
        margin-right: -2px;
      }
      .github-dot {
        color: red;
        font-size: 10px;
        margin-left: -14px;
        margin-right: 4px;
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
