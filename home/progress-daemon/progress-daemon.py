#!/usr/bin/env python3
import socket
import json
import os
import tkinter as tk
from threading import Thread
# Configuration
SOCKET_PATH = "/tmp/progress_bars.sock"

class ProgressApp:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Global Progress")
        # Hyprland/Wayland positioning (Floating)
        self.root.geometry("300x400+1600+600") 
        self.root.overrideredirect(True) # No window decorations
        self.root.attributes("-topmost", True)
        self.root.configure(bg="#1e1e2e") # Catppuccin Mocha-ish

        self.bars = {} # pid: {frame, label, bar, percentage}
        self.container = tk.Frame(self.root, bg="#1e1e2e")
        self.container.pack(fill="both", expand=True, padx=10, pady=10)

        self.listen_thread = Thread(target=self.server, daemon=True)
        self.listen_thread.start()

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
                        # Clean up JS-style JSON if necessary
                        msg = json.loads(data.replace("'", '"'))
                        self.root.after(0, self.update_bars, msg)
                    except Exception as e:
                        print(f"Error: {e}")
                conn.close()

    def update_bars(self, msg):
        pid = msg.get('pid')
        
        if msg.get('action') == 'close':
            if pid in self.bars:
                self.bars[pid]['frame'].destroy()
                del self.bars[pid]
        else:
            name = msg.get('name', 'Process')
            prog = msg.get('progress', 0)
            color = msg.get('color', '#00a')

            if pid not in self.bars:
                f = tk.Frame(self.container, bg="#1e1e2e")
                lbl = tk.Label(f, text=name, fg="white", bg="#1e1e2e", font=("Sans", 9))
                canvas = tk.Canvas(f, height=10, bg="#313244", highlightthickness=0)
                bar = canvas.create_rectangle(0, 0, 0, 10, fill=color)
                
                lbl.pack(side="top", anchor="w")
                canvas.pack(fill="x", pady=(0, 5))
                f.pack(fill="x")
                
                self.bars[pid] = {'frame': f, 'canvas': canvas, 'bar': bar, 'perc': prog, 'name': name}
            
            # Update values
            self.bars[pid]['perc'] = prog
            canvas = self.bars[pid]['canvas']
            # Simple width math
            width = 280 * (prog / 100)
            canvas.coords(self.bars[pid]['bar'], 0, 0, width, 10)

        self.sort_bars()

    def sort_bars(self):
        # Sort by percentage descending
        sorted_pids = sorted(self.bars.keys(), key=lambda x: self.bars[x]['perc'], reverse=True)
        for i, pid in enumerate(sorted_pids):
            self.bars[pid]['frame'].pack_forget()
            self.bars[pid]['frame'].pack(fill="x", side="top")

    def run(self):
        self.root.mainloop()

if __name__ == "__main__":
    ProgressApp().run()