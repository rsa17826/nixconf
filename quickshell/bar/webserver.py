#!/usr/bin/env python3
"""
HTTP <-> stdio bridge for CountdownTimerRow.
Run as a child Process from QML (TimerServer.qml). Each incoming HTTP
request is forwarded to QML as a JSON line on stdout, and this script
blocks until a matching JSON reply line arrives on stdin.
"""

import sys
import json
import threading
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = 8765

pending = {} # reqId -> threading.Event
responses = {} # reqId -> response dict
lock = threading.Lock()
stdout_lock = threading.Lock()


def send_request(method, path, body):
  req_id = str(uuid.uuid4())
  ev = threading.Event()
  with lock:
    pending[req_id] = ev

  msg = {"reqId": req_id, "method": method, "path": path, "body": body}
  with stdout_lock:
    sys.stdout.write(json.dumps(msg) + "\n")
    sys.stdout.flush()

  ev.wait(timeout=5)
  with lock:
    resp = responses.pop(req_id, None)
    pending.pop(req_id, None)

  return resp or {"status": 504, "body": {"error": "timeout waiting for QML"}}


def stdin_reader():
  for line in sys.stdin:
    line = line.strip()
    if not line:
      continue

    try:
      msg = json.loads(line)

    except json.JSONDecodeError:
      continue

    req_id = msg.get("reqId")
    with lock:
      responses[req_id] = msg
      ev = pending.get(req_id)

    if ev:
      ev.set()



class Handler(BaseHTTPRequestHandler):
  def _handle(self, method):
    try:
      length = int(self.headers.get("Content-Length", 0))
      body = json.loads(self.rfile.read(length)) if length else None

    except (ValueError, json.JSONDecodeError):
      self.send_response(400)
      self.send_header("Content-Type", "application/json")
      self.end_headers()
      self.wfile.write(json.dumps({"error": "invalid JSON body"}).encode())
      return

    resp = send_request(method, self.path, body)
    self.send_response(resp.get("status", 200))
    self.send_header("Content-Type", "application/json")
    self.end_headers()
    self.wfile.write(json.dumps(resp.get("body", {})).encode())

  def do_GET(self):
    self._handle("GET")

  def do_POST(self):
    self._handle("POST")

  def do_PUT(self):
    self._handle("PUT")

  def do_DELETE(self):
    self._handle("DELETE")

  def log_message(self, fmt, *args):
    pass # keep stdout clean for the JSON protocol; QML can log if needed


if __name__ == "__main__":
  threading.Thread(target=stdin_reader, daemon=True).start()
  ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
