{ inputs, ... }:
let
  x = "3";
  y = "3";
in
{
  xdg.configFile."rofi/colors".source = "${inputs.rofi-themes}/files/colors";
  xdg.configFile."rofi/launchers/type-${x}".source =
    "${inputs.rofi-themes}/files/launchers/type-${x}";
  xdg.configFile."rofi/images".source = "${inputs.rofi-themes}/files/images";
  xdg.configFile."rofi/config.rasi".text = ''
    @theme "${inputs.rofi-themes}/files/launchers/type-${x}/style-${y}.rasi"
    configuration {
      modi:            "combi,drun,calc";
      combi-modi:      "calc,drun";        /* calc first → its result appears at top */
      show:            "combi";

      /* when math result is selected, copy to Wayland clipboard */
      calc-command:    "echo -n '{result}' | wl-copy";

      /* optional: don't close after copying, so you can see it was selected */
      calc-auto-close: false;

      /* keep drun showing all apps beneath */
      drun-display-format: "{name}";
      combi-display-limit: 0;              /* no cap on combined results */
    }'';
}
