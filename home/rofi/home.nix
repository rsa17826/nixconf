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
  xdg.configFile."rofi/config.rasi".text =
    ''@theme "${inputs.rofi-themes}/files/launchers/type-${x}/style-${y}.rasi"'';
}
