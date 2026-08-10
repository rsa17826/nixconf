{
  config,
  pkgs,
  userConfig,
  inputs,
  lib,
  listDir,
  ...
}:
let
  gtkExtraConfig = {
    gtk-application-prefer-dark-theme = 1;
    gtk-enable-animations = 0;
  };
  # Move the execution of the import here, but do NOT pass config to it yet
  editconfBuilder = import ./editconf/editconf.nix { inherit pkgs lib; };
in
{
  # ── DECLARE OPTIONS ──────────────────────────────────────────────────
  options = {
    myProfile = {
      editableConfigs = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
        description = "List of collected configurations for edit-conf.";
      };
    };
  };

  # ── AUTOMATICALLY IMPORT SUB-FILES ───────────────────────────────────
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ]
  ++ (listDir ./. (p: ./${p}/home.nix));

  # ── EVALUATE CONFIGURATION ───────────────────────────────────────────
  config =
    let
      # Evaluating it down here safely isolates it inside the module execution pass
      editable = editconfBuilder config.myProfile.editableConfigs;
    in
    {
      home = {
        file = editable.entries // {
          # allow easy access to flake lock for current booted gen
          "${userConfig.nixConf}/current flake.lock.json".source = ../flake.lock;
        };
        # file = lib.filterAttrs (n: v: lib.hasPrefix ".local" n) editable.entries;
        username = userConfig.uname;
        homeDirectory = "/home/${userConfig.uname}";
        stateVersion = "26.05";

        sessionVariables = {
          QT_QPA_PLATFORMTHEME = lib.mkForce "generic";
          EDITOR = "codium";
          SOPS_EDITOR = "codium --wait";
          VISUAL = "codium";
          HYPRCURSOR_THEME = "mew";
          QT_STYLE_OVERRIDE = "adwaita-dark";
          ADW_DISABLE_PORTAL = "0";
          GTK_THEME = "Adwaita-dark";
          GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
          GTK_USE_PORTAL = "1";
        };
        packages = [ editable.editScript ];
      };
      _module = {
        args = {
          ln = config.lib.file.mkOutOfStoreSymlink;
        };
      };
      xdg = {
        # configFile = lib.filterAttrs (n: v: !lib.hasPrefix ".local" n) editable.entries;
        enable = true;
        dataHome = "/home/${userConfig.uname}/.local/share";
        configHome = "/home/${userConfig.uname}/.config";
        cacheHome = "/home/${userConfig.uname}/.cache";
        desktopEntries = {
          kitty-audd = {
            name = "audd";
            genericName = "audio download";
            exec = "kitty sh -c \"audd && exit || read\"";
            icon = "utilities-terminal";
            categories = [ "Utility" ];
            terminal = false;
          };
          kitty-vidd = {
            name = "vidd";
            genericName = "video download";
            exec = "kitty sh -c \"vidd && exit || read\"";
            icon = "utilities-terminal";
            categories = [ "Utility" ];
            terminal = false;
          };
        };

        mimeApps = {
          enable = true;
          defaultApplications = {
            "inode/directory" = [ "thunar.desktop" ];
          };
        };

        portal = {
          enable = true;
          extraPortals = with pkgs; [
            xdg-desktop-portal-gtk
            xdg-desktop-portal-hyprland
          ];
          config = {
            common = {
              default = [
                "hyprland"
                "gtk"
              ];
            };
            vscodium = {
              "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
            };
          };
        };
      };

      systemd = {
        user = {
          services = {
          };
        };
      };

      programs = {
        direnv = {
          enable = true;
          nix-direnv = {
            enable = true;
          };
        };
        home-manager = {
          enable = true;
        };
      };

      gtk = {
        enable = true;
        theme = {
          name = "Adwaita-dark";
          package = pkgs.gnome-themes-extra;
        };
        gtk3 = {
          extraConfig = gtkExtraConfig;
        };
        gtk4 = {
          extraConfig = gtkExtraConfig;
          # gtk4.theme = config.gtk.theme;
          theme = null;
        };
      };

      qt = {
        enable = true;
        platformTheme = {
          name = "gtk2";
        };
        style = {
          name = "adwaita-dark";
          package = pkgs.symlinkJoin {
            name = "adwaita-qt-all";
            paths = with pkgs; [
              adwaita-qt
              adwaita-qt6
            ];
          };
        };
      };
      dconf = {
        settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
          };
        };
      };
    };
}
