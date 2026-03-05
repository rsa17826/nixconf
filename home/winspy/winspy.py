import subprocess
import json
import tkinter as tk
from tkinter import font


class HyprSpy:
    def __init__(self, root):
        self.root = root
        self.root.title("HyprSpy")
        self.root.geometry("450x350")
        self.root.attributes("-topmost", True)

        self.custom_font = font.Font(family="Monospace", size=10)

        # UI Setup
        self.label = tk.Label(
            root,
            text="Waiting for window...",
            justify="left",
            anchor="nw",
            font=self.custom_font,
            padx=15,
            pady=15,
            bg="#1e1e2e",
            fg="#cdd6f4",
            cursor="hand2",  # Changes cursor to indicate it's clickable
        )
        self.label.pack(expand=True, fill="both")
        self.root.configure(bg="#1e1e2e")

        # Bind click event for copying
        self.label.bind("<Button-1>", self.copy_to_clipboard)

        self.update_info()

    def is_frozen(self):
        """Check if Ctrl, Alt, or Shift are held down."""
        # Mask values for modifiers
        # Shift: 0x1, Control: 0x4, Alt: 0x8 (varies by system, using state check is safer)
        # We'll use a logic check on the event state or root state
        try:
            # Querying the root state for modifiers
            # 1=Shift, 4=Control, 8=Alt (Mod1)
            state = self.root.winfo_toplevel().tk.call("tk", "get_state", self.root)
            # Simpler approach for cross-distro stability: check event-less state
            return any(
                [self.root.tk.getboolean(self.root.tk.call("tk", "get_modifiers"))]
            )
        except:
            # Fallback: manually check standard key states via tkinter state strings
            # This works on most Linux/X11/Wayland backends for Tk
            return False

    def get_hypr_data(self):
        try:
            win_proc = subprocess.run(
                ["hyprctl", "activewindow", "-j"], capture_output=True, text=True
            )
            win_data = json.loads(win_proc.stdout)
            cur_proc = subprocess.run(
                ["hyprctl", "cursorpos", "-j"], capture_output=True, text=True
            )
            cur_data = json.loads(cur_proc.stdout)
            return win_data, cur_data
        except Exception as e:
            return None, None

    def copy_to_clipboard(self, event=None):
        self.root.clipboard_clear()
        self.root.clipboard_append(self.label.cget("text"))
        # Brief visual feedback
        original_bg = self.label.cget("bg")
        self.label.config(bg="#45475a")
        self.root.after(100, lambda: self.label.config(bg=original_bg))

    def update_info(self):
        # We use a slightly different way to check modifiers in Wayland/Tkinter:
        # Check if Shift (1), Ctrl (4), or Alt (8) are in the current state bitmask
        state = self.root.winfo_pointerx()  # Not used, but forces a state update

        # To make this robust on Hyprland, we check the global modifier state
        # Note: 0x1=Shift, 0x4=Ctrl, 0x8=Alt, 0x10=Mod2, 0x40=Mod4(Super)
        modifiers = self.root.tk.call("tk", "get_state", self.root)
        frozen = int(modifiers) & (0x1 | 0x4 | 0x8)

        if not frozen:
            self.root.title("HyprSpy")
            win, cur = self.get_hypr_data()
            if win and win.get("address") != "0x":
                text = (
                    f"WINDOW INFORMATION (Click to Copy)\n"
                    f"{'='*35}\n"
                    f"Title:    {win.get('title')[:50]}\n"
                    f"Class:    {win.get('class')}\n"
                    f"Address:  {win.get('address')}\n"
                    f"PID:      {win.get('pid')}\n\n"
                    f"WORKSPACE & STATE\n"
                    f"{'='*35}\n"
                    f"ID:       {win.get('workspace', {}).get('id')}\n"
                    f"Floating: {win.get('floating')}\n"
                    f"Pinned:   {win.get('pinned')}\n\n"
                    f"CURSOR\n"
                    f"{'='*35}\n"
                    f"Absolute: {cur.get('x')}, {cur.get('y')}\n\n"
                    f"[Hold Ctrl/Alt/Shift to Freeze]"
                )
            else:
                text = "No active window detected\n(Desktop Focused)"
            self.label.config(text=text)
        else:
            self.root.title("HyprSpy (FROZEN)")

        self.root.after(100, self.update_info)


if __name__ == "__main__":
    root = tk.Tk()
    app = HyprSpy(root)
    root.mainloop()
