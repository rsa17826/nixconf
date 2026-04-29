{ ... }:
{
  programs.kitty = {
    enable = true;
    keybindings = {
      # Navigation (Ctrl + Arrows)
      # "ctrl+left" = "send_text all \\x1bb";
      # "ctrl+right" = "send_text all \\x1bf";

      # # Selection (Ctrl + Shift + Arrows)
      # "ctrl+shift+left" = "send_text all \\x1b[1;6D";
      # "ctrl+shift+right" = "send_text all \\x1b[1;6C";

      # Deletion (Ctrl + Backspace / Delete)
      # "ctrl+backspace" = "send_text all \\x17";
      # "ctrl+delete" = "send_text all \\x1bd";
      # Optional: Rebind Interrupt so you can still stop processes
      "ctrl+c" = "copy_and_clear_or_interrupt";
      "ctrl+v" = "paste_from_clipboard";
      # "ctrl+left" = "send_text all \\x1bb";
      # "ctrl+right" = "send_text all \\x1bf";

      # # Selection (Ctrl + Shift + Left/Right)
      # # These sequences are often interpreted by the shell as movement
      # # unless the application (like a text editor) is listening for selection.
      # "ctrl+shift+left" = "send_text all \\x1b[1;6D";
      # "ctrl+shift+right" = "send_text all \\x1b[1;6C";
      "allow_remote_control" = "yes";
    };
  };
}
