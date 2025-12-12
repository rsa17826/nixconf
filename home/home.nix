{
  config,
  pkgs,
  uname,
  ...
}:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.

  home.username = uname;
  home.homeDirectory = "/home/${uname}";
  xsession.numlock.enable = true;
  #wayland.windowManager.hyprland = {
  #  # Whether to enable Hyprland wayland compositor
  #  enable = true;
  #  # The hyprland package to use
  #  package = pkgs.hyprland;
  #  # Whether to enable XWayland
  #  xwayland.enable = true;
#
#    # Optional
#    # Whether to enable hyprland-session.target on hyprland startup
#    systemd.enable = true;
#  };
  #xdg.configFile."hypr/autostart.conf".text = ''
  #  ${pkgs.waybar}/bin/waybar &
  #  ${pkgs.networkmanagerapplet}/bin/nm-applet &
  #'';

  # VS Code

  home.stateVersion = "25.11"; # Please read the comment before changing.
  programs = {
    kitty = {
      enable = true; # required for the default Hyprland config
    };
   # hyprland = {
   #   enable = true;
   # };
    home-manager.enable = true;
    vscode = {
      enable = true;
      package = pkgs.vscodium;
      mutableExtensionsDir = true;

      profiles.default = {
        extensions = with pkgs.vscode-extensions;[]++pkgs.vscode-utils.extensionsFromVscodeMarketplace
[{
    name = "font-viewer";
    publisher = "adamraichu";
    version = "1.1.1";
    hash = "sha256-0T5gxxFkb+Muf65aoU4ONtEbhsqE5H5W9BhVhsqTySM=";
  }
  {
    name = "indent-jump";
    publisher = "apinix";
    version = "1.0.3";
    hash = "sha256-rvYc5bF2pakEUjtniKjE5wDnoZM9JGDEN2Lxhh3AdMo=";
  }
  {
    name = "furry-language";
    publisher = "avoonix";
    version = "0.1.1";
    hash = "sha256-d4y17dG2J7VZq1g7uo+3Y1gp8+0qyaQKHAUqsSvlmq8=";
  }
  {
    name = "nix";
    publisher = "bbenoist";
    version = "1.0.1";
    hash = "sha256-qwxqOGublQeVP2qrLF94ndX/Be9oZOn+ZMCFX1yyoH0=";
  }
  {
    name = "paste-replaced";
    publisher = "betterthantomorrow";
    version = "1.1.13";
    hash = "sha256-yW51Vo7nSyQCVQAfrDjuWTSMAptv/h5oNV8z5KHFvIE=";
  }
  {
    name = "better-json5";
    publisher = "blueglassblock";
    version = "1.6.0";
    hash = "sha256-ySGU7LZqymZBfsKaVwKrqrIMGEItBMea5LM+/DHABFM=";
  }
  {
    name = "vscode-toggle-quotes";
    publisher = "britesnow";
    version = "0.3.6";
    hash = "sha256-Hn3Mk224ePAAnNtkhKMcCil/kTgbonweb1i884Q62rs=";
  }
  {
    name = "rcdbg";
    publisher = "bvpav";
    version = "0.0.1";
    hash = "sha256-6zDA3WacBlj0qn0D+WlrDqg90FOqTmQ9eajJfVv0bEs=";
  }
  {
    name = "js-auto-backticks";
    publisher = "chamboug";
    version = "1.2.0";
    hash = "sha256-sXs5B8sFFqDR1EiCfDIV92RXiaZPpcAfSosfYYSCJng=";
  }
  {
    name = "cmake-format";
    publisher = "cheshirekow";
    version = "0.6.11";
    hash = "sha256-NdU8J0rkrH5dFcLs8p4n/j2VpSP/X7eSz2j4CMDiYJM=";
  }
  {
    name = "npm-intellisense";
    publisher = "christian-kohler";
    version = "1.4.5";
    hash = "sha256-liuFGnyvvVHzSv60oLkemFyv85R+RiGKErRIUz2PYKs=";
  }
  {
    name = "vscode-eslint";
    publisher = "dbaeumer";
    version = "3.0.21";
    hash = "sha256-Ip9q7BroIVNsxbO/OcZuJWagYsYtV2xJhe0z0NFiR2U=";
  }
  {
    name = "debugpy-attacher";
    publisher = "debugpyattacher";
    version = "1.3.0";
    hash = "sha256-L3x5jTKSQ94JCJbo4LKk2m/xovtYeafwBZNSY/vr6VY=";
  }
  {
    name = "dinoscan-vscode";
    publisher = "dinopitstudios";
    version = "2.0.4";
  }
  {
    name = "godot-format";
    publisher = "dohe";
    version = "0.2.12";
  }
  {
    name = "githistory";
    publisher = "donjayamanne";
    version = "0.6.20";
  }
  {
    name = "xml";
    publisher = "dotjoshjohnson";
    version = "2.5.1";
  }
  {
    name = "brackethighlighter";
    publisher = "durzn";
    version = "3.0.4";
  }
  {
    name = "memory-inspector";
    publisher = "eclipse-cdt";
    version = "1.2.0";
  }
  {
    name = "pythonsnippets3pro";
    publisher = "ericsia";
    version = "3.3.4";
  }
  {
    name = "prettier-vscode";
    publisher = "esbenp";
    version = "11.0.2";
  }
  {
    name = "comment-anchors";
    publisher = "exodiusstudios";
    version = "1.10.4";
  }
  {
    name = "vscode-solution-explorer";
    publisher = "fernandoescolar";
    version = "0.9.2";
  }
  {
    name = "c-cpp-runner";
    publisher = "franneck94";
    version = "9.5.0";
  }
  {
    name = "workspace-formatter";
    publisher = "franneck94";
    version = "1.2.2";
  }
  {
    name = "godot-tools";
    publisher = "geequlim";
    version = "2.5.1";
  }
  {
    name = "javascript-essentials";
    publisher = "gydunhn";
    version = "0.3.0";
  }
  {
    name = "nodejs-essentials";
    publisher = "gydunhn";
    version = "1.0.0";
  }
  {
    name = "typescript-essentials";
    publisher = "gydunhn";
    version = "1.2.0";
  }
  {
    name = "vsc-essentials";
    publisher = "gydunhn";
    version = "2.3.0";
  }
  {
    name = "vscode-ansi";
    publisher = "iliazeus";
    version = "1.1.7";
  }
  {
    name = "path-autocomplete";
    publisher = "ionutvmi";
    version = "1.25.0";
  }
  {
    name = "nix-ide";
    publisher = "jnoortheen";
    version = "0.5.0";
  }
  {
    name = "multi-formatter";
    publisher = "jota0222";
    version = "1.6.2";
  }
  {
    name = "synthwave-fluoromachine-cursor";
    publisher = "lujstn";
    version = "0.2.1";
  }
  {
    name = "vscode-autohotkey-plus-plus";
    publisher = "mark-wiemer";
    version = "6.7.1";
  }
  {
    name = "ts-error-translator";
    publisher = "mattpocock";
    version = "0.10.1";
  }
  {
    name = "rainbow-csv";
    publisher = "mechatroner";
    version = "3.23.0";
  }
  {
    name = "indent-nested-dictionary";
    publisher = "mgesbert";
    version = "0.0.4";
  }
  {
    name = "git-graph";
    publisher = "mhutchie";
    version = "1.30.0";
  }
  {
    name = "dotenv";
    publisher = "mikestead";
    version = "1.0.1";
  }
  {
    name = "mssql";
    publisher = "ms-mssql";
    version = "1.37.1";
  }
  {
    name = "black-formatter";
    publisher = "ms-python";
    version = "2025.3.11831009";
  }
  {
    name = "debugpy";
    publisher = "ms-python";
    version = "2025.17.2025121103";
  }
  {
    name = "python";
    publisher = "ms-python";
    version = "2025.20.0";
  }
  {
    name = "vscode-pylance";
    publisher = "ms-python";
    version = "2025.10.100";
  }
  {
    name = "hexeditor";
    publisher = "ms-vscode";
    version = "1.11.1";
  }
  {
    name = "powershell";
    publisher = "ms-vscode";
    version = "2025.5.0";
  }
  {
    name = "vscode-js-profile-flame";
    publisher = "ms-vscode";
    version = "1.0.9";
  }
  {
    name = "color-highlight";
    publisher = "naumovs";
    version = "2.8.0";
  }
  {
    name = "autodocstring";
    publisher = "njpwerner";
    version = "0.6.1";
  }
  {
    name = "fix-json";
    publisher = "oliversturm";
    version = "0.2.0";
  }
  {
    name = "oracle-java";
    publisher = "oracle";
    version = "25.0.0";
  }
  {
    name = "vscode-code-jump";
    publisher = "oxideops";
    version = "1.0.5";
  }
  {
    name = "lunar-theme";
    publisher = "prismlink";
    version = "1.2.1";
  }
  {
    name = "text-power-tools";
    publisher = "qcz";
    version = "1.51.0";
  }
  {
    name = "str-conv";
    publisher = "rectcircle";
    version = "1.2.1";
  }
  {
    name = "regex-text-gen";
    publisher = "rioj7";
    version = "0.14.0";
  }
  {
    name = "inline-parameters-extended";
    publisher = "robertostermann";
    version = "1.3.5";
    hash = "sha256-eG7+16Y3lh/AHWu2Is19/6Va5vlqve5yRDReeerSzHU=";
  }
  {
    name = "python-docstring-highlighter";
    publisher = "rodolphebarbanneau";
    version = "0.2.4";
    hash = "sha256-g0LcV/S1eZij+8YXW3NpfGm5gJGeoobqDUcAF66UpWI=";
  }
  {
    name = "rust-analyzer";
    publisher = "rust-lang";
    version = "0.4.2715";
    hash = "sha256-v5htid5XsJu3cbZ+zO4R3VSY7JUD+M2/kWXyhS4H370=";
  }
  {
    name = "vs-code-prettier-eslint";
    publisher = "rvest";
    version = "6.0.0";
    hash = "sha256-PogNeKhIlcGxUKrW5gHvFhNluUelWDGHCdg5K+xGXJY=";
  }
  {
    name = "glassit";
    publisher = "s-nlf-fh";
    version = "0.2.6";
    hash = "sha256-LcAomgK91hnJWqAW4I0FAgTOwr8Kwv7ZhvGCgkokKuY=";
  }
  {
    name = "dark-plus-material-saidtorres3";
    publisher = "saidtorres3";
    version = "2.7.5";
    hash = "sha256-tkOyPCJQhDgsXGNG6zS9UuBGBt81BGAzQlX7o5sfKoE=";
  }
  {
    name = "rainbow-struct-field-tags";
    publisher = "se-dev-pion";
    version = "0.3.1";
    hash = "sha256-GtuvLfEmdA2oRaDGksWPcw12fJugskCXT9gwSP3MYTk=";
  }
  {
    name = "slang-language-extension";
    publisher = "shader-slang";
    version = "2.0.3";
    hash = "sha256-j4ZS7hm3mo/zRjXtneeIU0hlTG6CXCblZBX2Fo6AW6Q=";
  }
  {
    name = "vscode-highlight-text";
    publisher = "simonhe";
    version = "0.0.49";
    hash = "sha256-YBHJmVBRu37Xtc76cp2V60pQUBwKqBcsprVKDxeGHlY=";
  }
  {
    name = "chrome-extension-api";
    publisher = "solomonkinard";
    version = "0.0.5";
    hash = "sha256-pAAoRu7IAbwk3rVzTti2rD3tNot7uD4mrASzm66NSuk=";
  }
  {
    name = "chrome-extensions";
    publisher = "solomonkinard";
    version = "0.1.1";
    hash = "sha256-T4RvRYbUw+BDvdGWSySeR7ta3k7adtSOJZfSG0t9nHA=";
  }
  {
    name = "themeeditor";
    publisher = "soyreneon";
    version = "1.14.3";
    hash = "sha256-nn8eQl9ZhFuHtZ6ZGcvJsDSkbucN6kf9vrWjL3TFrB4=";
  }
  {
    name = "typos-vscode";
    publisher = "tekumara";
    version = "0.1.46";
    hash = "sha256-cgA5nrEdah6Dae8TJE4r3yKfF6/G/4rjkVlwtG0ZU4E=";
  }
  {
    name = "doki-theme";
    publisher = "unthrottled";
    version = "88.1.18";
    hash = "sha256-7Ditwj7U26t3v4ofpqw/sHar6uE46E4DWVwGZjziZfM=";
  }
  {
    name = "autolink";
    publisher = "usernamehw";
    version = "1.0.0";
    hash = "sha256-DHw6Sy2ziLstoJeeCbTNZC1STgzRlXWzbjrjIpqe2u8=";
  }
  {
    name = "errorlens";
    publisher = "usernamehw";
    version = "3.26.0";
    hash = "sha256-pAkk3QURnlLNMZ2cFBks2lAEl/Hk8Z2i/QgvjUv+u2Y=";
  }
  {
    name = "vscode-lldb";
    publisher = "vadimcn";
    version = "1.12.0";
    hash = "sha256-pHVoFTm2UaXCjGhDNBIbFsfjJc1GB+ugNeSsPSULthQ=";
  }
  {
    name = "vscode-java-debug";
    publisher = "vscjava";
    version = "0.58.2025112507";
    hash = "sha256-uYrpfZfK3Vuq89/hW9TGVqmmyELAFJsJVFZmDNtD2CI=";
  }
  {
    name = "vscode-import-cost";
    publisher = "wix";
    version = "3.3.0";
    hash = "sha256-GQ26Cmu9F/6+3NMoxsb1BHqKqaVAx+qWNW0rYBHdiHI=";
  }
  {
    name = "javascriptsnippets";
    publisher = "xabikos";
    version = "1.8.0";
    hash = "sha256-ht6Wm1X7zien+fjMv864qP+Oz4M6X6f2RXjrThURr6c=";
  }
  {
    name = "pretty-ts-errors";
    publisher = "yoavbls";
    version = "0.6.3";
    hash = "sha256-7yoNuYg31hbtU4HATG4VAERcMk5KPRA3WLouSJo3rxs=";
  }
  {
    name = "vscode-autohotkey-debug";
    publisher = "zero-plusplus";
    version = "1.11.1";
    hash = "sha256-4PZHB3NZz5++w+zCuJ21B+aSVhtzaD4puAP2z+HmBWA=";
  }

        ];
        userSettings = {
  "doki.wallpaper.path" = "PATH DESCRIPTION";
  "doki.background.path" = "PATH DESCRIPTION";
  "doki.background.anchor" = "center";
  "window.titleBarStyle" = "custom";
  "window.customMenuBarAltFocus" = false;
  "window.enableMenuBarMnemonics" = false;

  "terminal.integrated.autoReplies" = {
    "Terminate batch job (Y/N)" = "Y\r";
  };

  "editor.pasteAs.enabled" = false;
  "debug.focusWindowOnBreak" = false;

  "files.exclude" = {
    "**/maps" = true;
    "themes" = true;
    "**/custom blocks" = true;
    "**/.vscode" = true;
    "**/*.tscn" = true;
    "**/*.uid" = true;
    "**/docs" = true;
    "**/icon.ico" = true;
    "**/js globals" = true;
    "**/node_modules" = true;
    "**/images" = true;
    ".gitattributes" = true;
    "VERSION" = true;
      "**/scenes/blocks/**" = true; # replaces all the [!.][!.] chains

    "**/scenes/blocks/[!.]" = true;
    "**/scenes/blocks/[!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.]" = true;
    "**/scenes/blocks/[!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.][!.]" = true;
    "**/GLOBAL/menu things" = true;
    "**/saves" = true;
    "**/*.import" = true;
    "**/project.godot" = true;
    "**/.editorconfig" = true;
    "**/*.tmp" = true;
    "**/*.TMp" = true;
    "**/export_presets.cfg" = true;
    "tabby_explorer_main_pref.tres" = true;
    "process" = true;
    "downloaded maps" = true;
    "override.cfg" = true;
    "exports" = true;
  };

  "security.workspace.trust.untrustedFiles" = "open";
  "workbench.startupEditor" = "none";
  "editor.detectIndentation" = false;
  "editor.defaultFormatter" = "esbenp.prettier-vscode";

  "[python]" = {
    "editor.defaultFormatter" = "Jota0222.multi-formatter";
    "editor.tabSize" = 2;
    "editor.guides.bracketPairs" = true;
    "editor.guides.bracketPairsHorizontal" = true;
    "editor.lightbulb.enabled" = "onCode";
    "editor.linkedEditing" = true;
    "multiFormatter.formatterList" = [
      "ms-python.black-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
    ];
  };

  "python.formatting.provider" = "black";

  "[javascript]" = {
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
  };

  "[html]" = {
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
    "editor.language.brackets" = [];
    "editor.language.colorizedBracketPairs" = [];
    "editor.suggest.insertMode" = "insert";
    "editor.guides.bracketPairs" = true;
    "editor.guides.bracketPairsHorizontal" = true;
    "editor.lightbulb.enabled" = "onCode";
  };

  "javascript.format.semicolons" = "remove";
  "typescript.format.semicolons" = "remove";
  "prettier.semi" = false;
  "files.autoSave" = "onFocusChange";

  "[css]" = {
    "editor.suggest.insertMode" = "insert";
  };
  "[scss]" = {
    "editor.suggest.insertMode" = "insert";
  };
  "[less]" = {
    "editor.suggest.insertMode" = "insert";
  };
  "[handlebars]" = {
    "editor.suggest.insertMode" = "insert";
  };
  "[json]" = {
    "editor.suggest.insertMode" = "insert";
  };
  "[jsonc]" = {
    "editor.suggest.insertMode" = "insert";
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
  };

  "[ahk2]" = {};
  "files.associations" = {
    "*.ahk" = "ahk2";
    "*.gd" = "gdscript";
    "*.js" = "javascript";
    "*.ts" = "typescript";
    "*.slang" = "hlsl";
  };

  "workbench.settings.applyToAllProfiles" = [
    "editor.fontFamily"
    "editor.wordWrap"
  ];

  "AutoHotkey2.InterpreterPath" = "PATH DESCRIPTION";
  "editor.accessibilitySupport" = "off";
  "explorer.confirmDelete" = false;

  "workbench.editorAssociations" = {
    "{hexdiff}:/**/*.*" = "hexEditor.hexedit";
    "*.dat" = "hexEditor.hexedit";
    "*.sol" = "hexEditor.hexedit";
    "*.vscdb" = "hexEditor.hexedit";
    "*.exe" = "hexEditor.hexedit";
    "*.bin" = "hexEditor.hexedit";
    "*.class" = "hexEditor.hexedit";
    "*.cha" = "hexEditor.hexedit";
    "*.dmp" = "hexEditor.hexedit";
    "*.jar" = "hexEditor.hexedit";
  };

  "[powershell]" = {
    "editor.defaultFormatter" = "rssaromeo.4-to-2-formatter";
  };

  "workbench.preferredLightColorTheme" = "Visual Studio Dark";
  "workbench.preferredHighContrastLightColorTheme" = "Visual Studio Dark";
  "editor.multiCursorModifier" = "ctrlCmd";
  "window.confirmSaveUntitledWorkspace" = false;

  "[gdscript]" = {
    "editor.defaultFormatter" = "Jota0222.multi-formatter";
    "editor.tabSize" = 2;
    "editor.guides.bracketPairs" = true;
    "editor.guides.bracketPairsHorizontal" = true;
    "editor.lightbulb.enabled" = "onCode";
    "editor.linkedEditing" = true;
    "multiFormatter.formatterList" = [
      "geequlim.godot-tools"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.auto-regex"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.auto-regex"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.4-to-2-formatter"
      "rssaromeo.auto-regex"
      "rssaromeo.auto-regex"
      "rssaromeo.auto-regex"
      "rssaromeo.auto-regex"
      "rssaromeo.auto-regex"
      "rssaromeo.auto-regex"
      "rssaromeo.auto-regex"
    ];
  };

  "godotTools.editorPath.godot4" = "PATH DESCRIPTION";
  "ahk++.file.interpreterPathV2" = "PATH DESCRIPTION";
  "files.autoSaveWhenNoErrors" = true;
  "vscode-ahk-plus.compilePath" = "PATH DESCRIPTION";
  "ahk++.file.compilerPath" = "PATH DESCRIPTION";

  "diffEditor.ignoreTrimWhitespace" = true;
  "cmake.options.statusBarVisibility" = "compact";
  "cmake.pinnedCommands" = [
    "workbench.action.tasks.configureTaskRunner"
    "workbench.action.tasks.runTask"
  ];

  "[cpp]" = {
    "editor.defaultFormatter" = "llvm-vs-code-extensions.vscode-clangd";
  };

  "cmake.configureOnOpen" = true;
  "cmake.showOptionsMovedNotification" = false;
  "clangd.path" = "PATH DESCRIPTION";
  "cmake.exportCompileCommandsFile" = false;
  "cmake.showConfigureWithDebuggerNotification" = false;
  "git.openRepositoryInParentFolders" = "never";
  "ahk++.file.interpreterPathV1" = "PATH DESCRIPTION";

  "[ahk]" = {
    "editor.defaultFormatter" = "mark-wiemer.vscode-autohotkey-plus-plus";
  };

  "diffEditor.experimental.useTrueInlineView" = true;
  "workbench.iconTheme" = "vscode-icons";
};

      };
    };
  };

  # Optional, hint Electron apps to use Wayland:
  # home.sessionVariables.NIXOS_OZONE_WL = "1";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.opensnitch-ui
    pkgs.vscodium
  ];
  # systemd.user.services.albert = {
  #   description = "Albert Launcher";
  #   after = [ "graphical.target" ];

  #   serviceConfig = {
  #     ExecStart = "${pkgs.makeWrapper}/bin/makeWrapper ${pkgs.albert}/bin/albert /home/username/bin/albert-launch.sh --set QT_QPA_PLATFORMTHEME gtk2 --set QT_STYLE_OVERRIDE Fusion";
  #     Restart = "always";
  #     Environment = "DISPLAY=:0";
  #   };

  #   wantedBy = [ "default.target" ];
  # };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/nyx/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.

}
