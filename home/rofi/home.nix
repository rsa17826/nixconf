{
  inputs,
  pkgs,
  ...
}:
let
  x = "3";
  y = "3";

in
{
  home = {
    packages = [
      (pkgs.writeShellApplication {
        name = "rofi-launcher";
        text = "rofi -modi blocks -show blocks -show-icons -blocks-wrap ${./launcher.py}";
        runtimeInputs = with pkgs; [
          python3
          wl-clipboard
          libnotify
        ];
      })
    ];
  };
  xdg = {
    configFile = {
      "rofi/colors".source = "${inputs.rofi-themes}/files/colors";
      "rofi/launchers/type-${x}".source = "${inputs.rofi-themes}/files/launchers/type-${x}";
      "rofi/images".source = "${inputs.rofi-themes}/files/images";
      "rofi/config.rasi".text = ''
        @theme "${inputs.rofi-themes}/files/launchers/type-${x}/style-${y}.rasi"
        configuration {
          /* 1. Fix Home and End for text cursor navigation */
          kb-move-front: "Home";
          kb-move-end: "End,Control+e";

          /* 2. Map Ctrl+Delete to delete word forward AND ensure it's not bound elsewhere */
          kb-remove-word-forward: "Control+Delete";

          /* FIX: Explicitly bind Control+Backspace to remove word backward */
          kb-remove-word-back: "Control+Backspace";

          /* 3. Enable Word-by-Word cursor jumps */
          kb-move-word-back: "Control+Left";
          kb-move-word-forward: "Control+Right";

          /* 4. Unbind Home/End from jumping rows */
          kb-row-first: "KP_Home";
          kb-row-last: "KP_End";

          /* 5. Disable Shift+Left/Right mode switching */
          kb-mode-previous: "Control+ISO_Left_Tab";
          kb-mode-next: "Control+Tab";

          kb-clear-line: "Control+a";
        }'';
    };
  };
}
