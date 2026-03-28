#!/usr/bin/env python3
from typing import Any


from tkinter import Canvas, Frame, Label, Tk


import socket
import json
import os
import tkinter as tk
import time
from threading import Thread

SOCKET_PATH = "/tmp/progress_bars.sock"

from typing import TypedDict, cast


class BarType(TypedDict):
  canvas: Canvas
  frame: Frame
  bar: str
  perc: str | float | int
  last_seen: float
  max_idle: float
  update: float


class ProgressApp:
  def __init__(self) -> None:
    self.root: Tk = tk.Tk()
    self.root.title("Global Progress")
    self.root.geometry("300x1")
    self.root.overrideredirect(True)
    _ = self.root.attributes( # pyright: ignore[reportUnknownMemberType]
      "-topmost", True
    )
    _ = self.root.configure(bg="#1e1e2e")

    self.bars: dict[str, BarType] = (
      {}
    ) # pid: {frame, canvas, bar, perc, last_seen, max_idle}
    self.container: Frame = tk.Frame(self.root, bg="#1e1e2e")
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
        conn, _ = s.accept() # pyright: ignore[reportAny]
        data = conn.recv(1024).decode()
        if data:
          try:
            msg = json.loads( # pyright: ignore[reportAny]
              data.replace("'", '"')
            )
            _ = self.root.after(0, self.update_bars, msg)
          except:
            pass
        conn.close()

  def update_bars(self, msg: dict[str, str | int | float]) -> None:
    pid: str = str(msg.get("pid"))
    max_idle: float = float(msg.get("max_idle", 10)) # Default to 10 seconds

    if msg.get("action") == "close":
      self.remove_bar(pid)
    else:
      name, prog, color = cast(
        tuple[str, int, str],
        (
          msg.get("name", "Process"),
          msg.get("progress", 0),
          msg.get("color", "#00a"),
        ),
      )

      if pid not in self.bars:
        f: Frame = tk.Frame(self.container, bg="#1e1e2e")
        lbl: Label = tk.Label(
          f, text=name, fg="white", bg="#1e1e2e", font=("Sans", 9)
        )
        canvas: Canvas = tk.Canvas(
          f, height=10, bg="#313244", highlightthickness=0
        )
        bar: int = canvas.create_rectangle(0, 0, 0, 10, fill=color)
        lbl.pack(side="top", anchor="w")
        canvas.pack(fill="x", pady=(0, 5))
        self.bars[pid] = { # pyright: ignore[reportArgumentType]
          "frame": f,
          "canvas": canvas,
          "bar": bar,
        }

      # Update data
      self.bars[pid].update(
        {
          "perc": prog,
          "last_seen": time.time(),
          "max_idle": max_idle,
        } # pyright: ignore[reportArgumentType]
      )

      width = 280 * (prog / 100)
      self.bars[pid]["canvas"].coords(self.bars[pid]["bar"], 0, 0, width, 10)

    self.sort_and_resize()

  def check_timeouts(self) -> None:
    """Periodically check for idle progress bars."""
    now: float = time.time()
    to_delete: list[str] = [
      pid
      for pid, data in self.bars.items()
      if now - data["last_seen"] > data["max_idle"]
    ]

    for pid in to_delete:
      self.remove_bar(pid)

    if to_delete:
      self.sort_and_resize()

    _ = self.root.after(1000, self.check_timeouts) # Check every second

  def remove_bar(self, pid: str) -> None:
    if pid in self.bars:
      self.bars[pid]["frame"].destroy()
      del self.bars[pid]

  def sort_and_resize(self) -> None:
    sorted_pids: list[str] = sorted(
      self.bars.keys(), key=lambda x: self.bars[x]["perc"], reverse=True
    )
    for pid in sorted_pids:
      self.bars[pid]["frame"].pack_forget()
      self.bars[pid]["frame"].pack(fill="x", side="top")

    self.root.update_idletasks()
    new_height: int = max(self.container.winfo_reqheight() + 20, 1)
    self.root.geometry(f"300x{new_height}")

  def run(self) -> None:
    self.root.mainloop()


if __name__ == "__main__":
  ProgressApp().run()
