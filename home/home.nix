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
        extensions = with pkgs.vscode-extensions;[

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
