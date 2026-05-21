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
        file = lib.filterAttrs (n: v: lib.hasPrefix ".local" n) editable.entries;
        username = userConfig.uname;
        homeDirectory = "/home/${userConfig.uname}";
        stateVersion = "26.05";

        sessionVariables = {
          QT_QPA_PLATFORMTHEME = "generic";
          EDITOR = "nvim";
          SOPS_EDITOR = "codium --wait";
          VISUAL = "nvim";
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
        configFile = lib.filterAttrs (n: v: !lib.hasPrefix ".local" n) editable.entries;
        enable = true;
        dataHome = "/home/${userConfig.uname}/.local/share";
        configHome = "/home/${userConfig.uname}/.config";
        cacheHome = "/home/${userConfig.uname}/.cache";
        desktopEntries = {
          kitty-audd = {
            name = "audd";
            genericName = "audio download";
            exec = "kitty sh -c \"audd && exit\"";
            icon = "utilities-terminal";
            categories = [ "Utility" ];
            terminal = false;
          };
          kitty-vidd = {
            name = "vidd";
            genericName = "video download";
            exec = "kitty sh -c \"vidd && exit\"";
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
            swaync = {
              Service = {
                Restart = lib.mkForce "no";
              };
              Install = {
                # Also, prevent Home Manager from trying to start them during activation
                WantedBy = lib.mkForce [ ];
              };
            };
            xdg-desktop-portal-gtk = {
              Service = {
                Restart = lib.mkForce "no";
              };
              Install = {
                WantedBy = lib.mkForce [ ];
              };
            };
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
        kitty = {
          enable = true;
        };
        home-manager = {
          enable = true;
        };
        anyrun = {
          enable = true;
          config = {
            x = {
              fraction = 0.5;
            };
            y = {
              fraction = 0.3;
            };
            width = {
              fraction = 0.3;
            };
            hideIcons = false;
            ignoreExclusiveZones = false;
            layer = "overlay";
            hidePluginInfo = false;
            closeOnClick = false;
            showResultsImmediately = true;
            maxEntries = null;

            plugins = [
              "${pkgs.anyrun}/lib/libapplications.so"
              # "${pkgs.anyrun}/lib/libsymbols.so"
              #"${pkgs.anyrun}/lib/libshell.so"
              #"${pkgs.anyrun}/lib/libdictionary.so"
            ];
          };
          # Inline comments are supported for language injection into
          # multi-line strings with Treesitter! (Depends on your editor)
          extraCss = /* css */ ''
            .some_class {
              background: red;
            }
          '';

          extraConfigFiles."some-plugin.ron".text = ''
            Config(
              // for any other plugin
              // this file will be put in ~/.config/anyrun/some-plugin.ron
              // refer to docs of xdg.configFile for available options
            )
          '';
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
