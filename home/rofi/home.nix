{ inputs, ... }:
{
  xdg.configFile."rofi/colors".source = "${inputs.rofi-themes}/files/colors";
  xdg.configFile."rofi/launchers/type-7".source = "${inputs.rofi-themes}/files/launchers/type-7";
}
