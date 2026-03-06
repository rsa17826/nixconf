#!/usr/bin/env python3
import socket
import json
import os
import tkinter as tk
import time
from threading import Thread

SOCKET_PATH = "/tmp/progress_bars.sock"


class ProgressApp:
  def __init__(self):
    self.root = tk.Tk()
    self.root.title("Global Progress")
    self.root.geometry("300x1")
    self.root.overrideredirect(True)
    self.root.attributes("-topmost", True)
    self.root.configure(bg="#1e1e2e")

    self.bars = {}  # pid: {frame, canvas, bar, perc, last_seen, max_idle}
    self.container = tk.Frame(self.root, bg="#1e1e2e")
    self.container.pack(fill="both", expand=True, padx=10, pady=10)

    # Start background threads
    Thread(target=self.server, daemon=True).start()
    self.check_timeouts()

  def server(self):
    if os.path.exists(SOCKET_PATH):
      os.remove(SOCKET_PATH)
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
      s.bind(SOCKET_PATH)
      s.listen()
      while True:
        conn, _ = s.accept()
        data = conn.recv(1024).decode()
        if data:
          try:
            msg = json.loads(data.replace("'", '"'))
            self.root.after(0, self.update_bars, msg)
          except:
            pass
        conn.close()

  def update_bars(self, msg):
    pid = msg.get("pid")
    max_idle = msg.get("max_idle", 10)  # Default to 10 seconds

    if msg.get("action") == "close":
      self.remove_bar(pid)
    else:
      name, prog, color = (
        msg.get("name", "Process"),
        msg.get("progress", 0),
        msg.get("color", "#00a"),
      )

      if pid not in self.bars:
        f = tk.Frame(self.container, bg="#1e1e2e")
        lbl = tk.Label(f, text=name, fg="white", bg="#1e1e2e", font=("Sans", 9))
        canvas = tk.Canvas(f, height=10, bg="#313244", highlightthickness=0)
        bar = canvas.create_rectangle(0, 0, 0, 10, fill=color)
        lbl.pack(side="top", anchor="w")
        canvas.pack(fill="x", pady=(0, 5))
        self.bars[pid] = {"frame": f, "canvas": canvas, "bar": bar}

      # Update data
      self.bars[pid].update(
        {"perc": prog, "last_seen": time.time(), "max_idle": max_idle}
      )

      width = 280 * (prog / 100)
      self.bars[pid]["canvas"].coords(self.bars[pid]["bar"], 0, 0, width, 10)

    self.sort_and_resize()

  def check_timeouts(self):
    """Periodically check for idle progress bars."""
    now = time.time()
    to_delete = [
      pid
      for pid, data in self.bars.items()
      if now - data["last_seen"] > data["max_idle"]
    ]

    for pid in to_delete:
      self.remove_bar(pid)

    if to_delete:
      self.sort_and_resize()

    self.root.after(1000, self.check_timeouts)  # Check every second

  def remove_bar(self, pid):
    if pid in self.bars:
      self.bars[pid]["frame"].destroy()
      del self.bars[pid]

  def sort_and_resize(self):
    sorted_pids = sorted(
      self.bars.keys(), key=lambda x: self.bars[x]["perc"], reverse=True
    )
    for pid in sorted_pids:
      self.bars[pid]["frame"].pack_forget()
      self.bars[pid]["frame"].pack(fill="x", side="top")

    self.root.update_idletasks()
    new_height = max(self.container.winfo_reqheight() + 20, 1)
    self.root.geometry(f"300x{new_height}")

  def run(self):
    self.root.mainloop()


if __name__ == "__main__":
  ProgressApp().run()
