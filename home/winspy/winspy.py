import subprocess
import json
import tkinter as tk
from tkinter import font

class HyprSpy:
    def __init__(self, root):
        self.root = root
        self.root.title("HyprSpy")
        self.root.geometry("450x380")
        self.root.attributes("-topmost", True)

        # State tracking for modifiers
        self.is_frozen = False
        self.modifiers_held = set()

        # UI Styling
        self.bg_color = "#1e1e2e"
        self.fg_color = "#cdd6f4"
        self.freeze_color = "#f38ba8" 
        self.custom_font = font.Font(family="Monospace", size=10)
        
        self.display = tk.Text(
            root,
            font=self.custom_font,
            bg=self.bg_color,
            fg=self.fg_color,
            padx=15,
            pady=15,
            borderwidth=2,
            relief="flat",
            cursor="hand2",
            highlightthickness=2,
            highlightbackground=self.bg_color
        )
        self.display.pack(expand=True, fill="both")
        
        # Bindings
        self.display.bind("<Button-1>", self.copy_line)
        self.display.bind("<Key>", lambda e: "break") # Disable typing
        
        # Track key presses globally for this window
        self.root.bind("<KeyPress>", self.on_key_down)
        self.root.bind("<KeyRelease>", self.on_key_up)

        self.update_info()

    def on_key_down(self, event):
        if event.keysym in ("Control_L", "Control_R", "Shift_L", "Shift_R", "Alt_L", "Alt_R"):
            self.modifiers_held.add(event.keysym)
            self.is_frozen = True

    def on_key_up(self, event):
        if event.keysym in ("Control_L", "Control_R", "Shift_L", "Shift_R", "Alt_L", "Alt_R"):
            self.modifiers_held.discard(event.keysym)
            if not self.modifiers_held:
                self.is_frozen = False

    def get_hypr_data(self):
        try:
            win_proc = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True)
            win_data = json.loads(win_proc.stdout)
            cur_proc = subprocess.run(["hyprctl", "cursorpos", "-j"], capture_output=True, text=True)
            cur_data = json.loads(cur_proc.stdout)
            return win_data, cur_data
        except:
            return None, None

    def copy_line(self, event):
        index = self.display.index(f"@{event.x},{event.y}")
        line_num = index.split('.')[0]
        line_content = self.display.get(f"{line_num}.0", f"{line_num}.end").strip()
        
        if line_content and "=" not in line_content:
            to_copy = line_content.split(":", 1)[1].strip() if ":" in line_content else line_content
            self.root.clipboard_clear()
            self.root.clipboard_append(to_copy)
            
            # Brief Flash
            self.display.tag_add("flash", f"{line_num}.0", f"{line_num}.end")
            self.display.tag_config("flash", background="#45475a")
            self.root.after(150, lambda: self.display.tag_remove("flash", "1.0", "end"))

    def update_info(self):
        if not self.is_frozen:
            win, cur = self.get_hypr_data()
            self.display.config(highlightbackground=self.bg_color)
            self.root.title("HyprSpy")

            if win and win.get("address") != "0x":
                text = (
                    f"WINDOW INFORMATION\n"
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
                    f"HOLD SHIFT/CTRL/ALT TO FREEZE"
                )
            else:
                text = "No active window detected\n(Desktop Focused)"
            
            self.display.config(state="normal")
            self.display.delete("1.0", "end")
            self.display.insert("1.0", text)
            self.display.config(state="disabled")
        else:
            self.display.config(highlightbackground=self.freeze_color)
            self.root.title("HyprSpy (FROZEN)")

        self.root.after(100, self.update_info)

if __name__ == "__main__":
    root = tk.Tk()
    app = HyprSpy(root)
    root.mainloop()