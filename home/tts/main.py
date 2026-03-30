#!/usr/bin/env python3
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

ESPEAK = "/run/current-system/sw/bin/espeak-ng"


class Handler(BaseHTTPRequestHandler):
  def do_GET(self):
    q = parse_qs(urlparse(self.path).query)
    text = q.get("t", [""])[0]
    rate = q.get("r", ["350"])[0]
    if text:
      subprocess.Popen([ESPEAK, "-s", rate, text])
    self.send_response(200)
    self.send_header("Access-Control-Allow-Origin", "*")
    self.send_header("Content-Length", "0")
    self.end_headers()

  def log_message(self, *a):
    pass


HTTPServer(("127.0.0.1", 5533), Handler).serve_forever()
