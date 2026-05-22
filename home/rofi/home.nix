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
  xdg.configFile."rofi/colors".source = "${inputs.rofi-themes}/files/colors";
  xdg.configFile."rofi/launchers/type-${x}".source =
    "${inputs.rofi-themes}/files/launchers/type-${x}";
  xdg.configFile."rofi/images".source = "${inputs.rofi-themes}/files/images";
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
  xdg.configFile."rofi/config.rasi".text = ''
    @theme "${inputs.rofi-themes}/files/launchers/type-${x}/style-${y}.rasi"
    configuration {
      /* 1. Fix Home and End for text cursor navigation */
      kb-move-front: "Home";
      kb-move-end: "End,Control+e";

      /* 2. Map Ctrl+Delete to delete the word in front of the cursor */
      kb-remove-word-forward: "Control+Delete";

      /* 3. Enable Word-by-Word cursor jumps (Ctrl+Left / Ctrl+Right) */
      kb-move-word-back: "Control+Left";
      kb-move-word-forward: "Control+Right";

      /* 4. Unbind Home/End from jumping rows so they don't fight the text cursor */
      kb-row-first: "KP_Home";
      kb-row-last: "KP_End";

      /* 5. Disable Shift+Left/Right from accidentally changing active launcher modes */
      kb-mode-previous: "Control+ISO_Left_Tab";
      kb-mode-next: "Control+Tab";

      kb-clear-line: "Control+a";
    }'';
}
