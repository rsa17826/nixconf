import subprocess
import json
import tkinter as tk
from tkinter import font


class HyprSpy:
    def __init__(self, root):
        self.root = root
        self.root.title("HyprSpy")
        self.root.geometry("400x300")
        self.root.attributes("-topmost", True)  # Always on top

        # UI Styling
        self.custom_font = font.Font(family="Monospace", size=10)
        self.label = tk.Label(
            root,
            text="Waiting for window...",
            justify="left",
            anchor="nw",
            font=self.custom_font,
            padx=10,
            pady=10,
            bg="#1e1e2e",  # Catppuccin-style dark theme
            fg="#cdd6f4",
        )
        self.label.pack(expand=True, fill="both")
        self.root.configure(bg="#1e1e2e")

        self.update_info()

    def get_hypr_data(self):
        try:
            # Get active window info
            win_proc = subprocess.run(
                ["hyprctl", "activewindow", "-j"], capture_output=True, text=True
            )
            print(win_proc)
            win_data = json.loads(win_proc.stdout)

            # Get cursor position
            cur_proc = subprocess.run(
                ["hyprctl", "cursorpos", "-j"], capture_output=True, text=True
            )
            print(cur_proc)
            cur_data = json.loads(cur_proc.stdout)

            return win_data, cur_data
        except Exception as e:
          print(e)
          return None, None

    def update_info(self):
        win, cur = self.get_hypr_data()

        if win and win.get("address") != "0x":
            text = (
                f"WINDOW INFORMATION\n"
                f"{'='*30}\n"
                f"Title:    {win.get('title')[:50]}\n"
                f"Class:    {win.get('class')}\n"
                f"Address:  {win.get('address')}\n"
                f"PID:      {win.get('pid')}\n\n"
                f"WORKSPACE & STATE\n"
                f"{'='*30}\n"
                f"ID:       {win.get('workspace', {}).get('id')}\n"
                f"Floating: {win.get('floating')}\n"
                f"Pinned:   {win.get('pinned')}\n\n"
                f"CURSOR\n"
                f"{'='*30}\n"
                f"Relative: {cur.get('x')}, {cur.get('y')}"
            )
        else:
            text = "No active window detected\n(Desktop Focused)"+str(win)

        self.label.config(text=text)
        self.root.after(100, self.update_info)  # Refresh every 100ms


if __name__ == "__main__":
    root = tk.Tk()
    app = HyprSpy(root)
    root.mainloop()
