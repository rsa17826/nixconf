{ ... }:
{
  programs.kitty = {
    enable = true;
    keybindings = {
      # Navigation (Ctrl + Arrows)
      "ctrl+left" = "send_text all \\x1bb";
      "ctrl+right" = "send_text all \\x1bf";

      # Selection (Ctrl + Shift + Arrows)
      "ctrl+shift+left" = "send_text all \\x1b[1;6D";
      "ctrl+shift+right" = "send_text all \\x1b[1;6C";

      # Deletion (Ctrl + Backspace / Delete)
      "ctrl+backspace" = "send_text all \\x17";
      "ctrl+delete" = "send_text all \\x1bd";

      # Clipboard (Ctrl + C / Ctrl + V)
      # Note: Overrides default terminal interrupt (SIGINT)
      "ctrl+c" = "copy_to_clipboard";
      "ctrl+v" = "paste_from_clipboard";

      # Optional: Rebind Interrupt so you can still stop processes
      "ctrl+alt+c" = "send_text all \\x03";
    };
  };
}
