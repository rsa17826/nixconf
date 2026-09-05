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

      # Get our own address so we know when to freeze
      self.own_address = self.get_own_address()
      self.is_frozen = False

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

      self.display.bind("<Button-1>", self.copy_line)
      self.display.bind("<Key>", lambda e: "break")

      self.update_info()

  def get_own_address(self):
      """Focus the window briefly to capture its Hyprland address."""
      try:
          # We wait a tiny bit for the window to map
          self.root.update()
          proc = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True)
          return json.loads(proc.stdout).get("address")

      except:
          return None


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
          # Extract only the value after the colon
          to_copy = line_content.split(":", 1)[1].strip() if ":" in line_content else line_content
          self.root.clipboard_clear()
          self.root.clipboard_append(to_copy)

          # Flash effect
          self.display.tag_add("flash", f"{line_num}.0", f"{line_num}.end")
          self.display.tag_config("flash", background="#45475a")
          self.root.after(150, lambda: self.display.tag_remove("flash", "1.0", "end"))


  def update_info(self):
      win, cur = self.get_hypr_data()

      # Check if the currently active window is this script
      current_active = win.get("address") if win else None
      self.is_frozen = (current_active == self.own_address and self.own_address is not None)

      if not self.is_frozen:
          self.display.config(highlightbackground=self.bg_color)
          self.root.title("HyprSpy (Scanning...)")

          if win and current_active != "0x":
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
                  f"CLICK THIS WINDOW TO FREEZE & COPY"
              )
          else:
              text = "No active window detected\n(Desktop Focused)"

          self.display.config(state="normal")
          self.display.delete("1.0", "end")
          self.display.insert("1.0", text)
          self.display.config(state="disabled")
      else:
          # Frozen state logic
          self.display.config(highlightbackground=self.freeze_color)
          self.root.title("HyprSpy (FROZEN - Click elsewhere to resume)")

      self.root.after(100, self.update_info)


if __name__ == "__main__":
  root = tk.Tk()
  app = HyprSpy(root)
  root.mainloop()
