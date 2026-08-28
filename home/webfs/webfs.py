#!/usr/bin/env python3
"""
webfs - serve your filesystem over HTTP on port 54220.

URL path forms (Host is expected to be fs.localhost, already routed to :54220):

    fs.localhost/~/file.txt     -> $HOME/file.txt
    fs.localhost/./file.txt     -> <cwd-webfs-was-started-in>/file.txt
    fs.localhost///file.txt     -> /file.txt   (absolute, from filesystem root)

    GET  -> returns file content
    HEAD -> stats the file (no body); headers report Content-Length,
            Last-Modified, and X-File-Type (file|dir)
    POST -> overwrites file content with the request body (creates the file
            if it doesn't exist; parent dirs must already exist)
    PUT  -> appends the request body to the file (creates the file
            if it doesn't exist; parent dirs must already exist)

Permission rules (one per line, in a rules file, default ./.webfsrules):

    ./                  # allow everything under cwd
    !./node_modules     # ...except node_modules
    /temp1              # allow this absolute path
    /temp2
    ~/notes             # allow this path under $HOME

Lines starting with '!' are deny rules that carve an exception out of a
broader allow rule. The most specific (longest) matching rule wins.

Any request that doesn't match an existing rule triggers an interactive
prompt on the terminal webfs is running in:

    [a]llow once  [r]ule (allow + remember for this run)  [d]eny  [D]eny all

Run with --all to disable permission checking entirely (full access).
"""

import argparse
import http.server
import mimetypes
import os
import socketserver
import sys
import threading
import urllib.parse

HOME = os.path.expanduser("~")


def resolve_path(url_path: str, start_dir: str):
    """Turn a request path into an absolute filesystem path, or None if
    the form is not recognized."""
    path = urllib.parse.unquote(url_path.split("?", 1)[0])

    if path == "/~" or path.startswith("/~/"):
        rest = path[2:].lstrip("/")
        return os.path.normpath(os.path.join(HOME, rest))

    if path == "/." or path.startswith("/./"):
        rest = path[2:].lstrip("/")
        return os.path.normpath(os.path.join(start_dir, rest))

    if path.startswith("///") or (path.startswith("//") and not path.startswith("///")):
        rest = path.lstrip("/")
        return os.path.normpath("/" + rest)

    return None


class Rule:
    def __init__(self, raw: str, base_dir: str):
        raw = raw.strip()
        self.deny = raw.startswith("!")
        if self.deny:
            raw = raw[1:].strip()
        if raw.startswith("~"):
            resolved = os.path.normpath(os.path.join(HOME, raw[1:].lstrip("/")))
        elif raw.startswith("./") or raw == ".":
            resolved = os.path.normpath(os.path.join(base_dir, raw[1:].lstrip("/")))
        elif raw.startswith("/"):
            resolved = os.path.normpath(raw)
        else:
            resolved = os.path.normpath(os.path.join(base_dir, raw))
        self.path = resolved
        self.raw = raw

    def matches(self, target: str) -> bool:
        return target == self.path or target.startswith(self.path.rstrip("/") + os.sep)

    def __repr__(self):
        return ("!" if self.deny else "") + self.raw


class PermissionManager:
    def __init__(self, rules_file: str, start_dir: str, allow_all: bool):
        self.start_dir = start_dir
        self.allow_all = allow_all
        self.deny_all_unknown = False
        self.lock = threading.Lock()
        self.rules = []
        self.rules_file = rules_file
        if rules_file and os.path.isfile(rules_file):
            with open(rules_file) as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    self.rules.append(Rule(line, start_dir))

    def _best_match(self, target: str):
        candidates = [r for r in self.rules if r.matches(target)]
        if not candidates:
            return None
        candidates.sort(key=lambda r: len(r.path), reverse=True)
        return candidates[0]

    def check(self, target: str) -> bool:
        if self.allow_all:
            return True

        with self.lock:
            best = self._best_match(target)
            if best is not None:
                return not best.deny

            if self.deny_all_unknown:
                return False

            return self._prompt(target)

    def _prompt(self, target: str) -> bool:
        sys.stderr.write("\n")
        sys.stderr.write(f"webfs: request for path not covered by any rule:\n")
        sys.stderr.write(f"  {target}\n")
        sys.stderr.write("  [a] allow once  [r] allow + add rule  [d] deny  [D] deny all further prompts\n")
        sys.stderr.write("webfs> ")
        sys.stderr.flush()
        try:
            choice = sys.stdin.readline().strip()
        except Exception:
            choice = "d"

        if choice == "a":
            return True
        if choice == "r":
            rule = Rule(target, self.start_dir)
            self.rules.append(rule)
            sys.stderr.write(f"webfs: added rule for {target}\n")
            return True
        if choice == "D":
            self.deny_all_unknown = True
            sys.stderr.write("webfs: denying all further unrecognized requests\n")
            return False
        # default: deny (covers 'd' and anything else)
        return False


class Handler(http.server.BaseHTTPRequestHandler):
    server_version = "webfs/1.0"

    def _resolve(self):
        target = resolve_path(self.path, self.server.webfs_start_dir)
        if target is None:
            self.send_error(400, "Unrecognized path form. Use /~/, /./ or /// prefixes.")
            return None
        return target

    def do_GET(self):
        target = self._resolve()
        if target is None:
            return
        if not self.server.webfs_perms.check(target):
            self.send_error(403, "Permission denied")
            return
        if not os.path.isfile(target):
            self.send_error(404, "File not found")
            return
        try:
            with open(target, "rb") as f:
                data = f.read()
        except OSError as e:
            self.send_error(500, str(e))
            return
        ctype, _ = mimetypes.guess_type(target)
        self.send_response(200)
        self.send_header("Content-Type", ctype or "application/octet-stream")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_HEAD(self):
        target = self._resolve()
        if target is None:
            return
        if not self.server.webfs_perms.check(target):
            self.send_error(403, "Permission denied")
            return
        if not os.path.exists(target):
            self.send_error(404, "File not found")
            return
        try:
            st = os.stat(target)
        except OSError as e:
            self.send_error(500, str(e))
            return
        ctype, _ = mimetypes.guess_type(target)
        self.send_response(200)
        self.send_header("Content-Type", ctype or "application/octet-stream")
        self.send_header("Content-Length", str(st.st_size if os.path.isfile(target) else 0))
        self.send_header("Last-Modified", self.date_time_string(int(st.st_mtime)))
        self.send_header("X-File-Type", "dir" if os.path.isdir(target) else "file")
        self.end_headers()

    def do_POST(self):
        target = self._resolve()
        if target is None:
            return
        if not self.server.webfs_perms.check(target):
            self.send_error(403, "Permission denied")
            return
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length) if length else b""
        try:
            with open(target, "wb") as f:
                f.write(body)
        except OSError as e:
            self.send_error(500, str(e))
            return
        self.send_response(200)
        self.send_header("Content-Length", "2")
        self.end_headers()
        self.wfile.write(b"ok")

    def do_PUT(self):
        target = self._resolve()
        if target is None:
            return
        if not self.server.webfs_perms.check(target):
            self.send_error(403, "Permission denied")
            return
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length) if length else b""
        try:
            with open(target, "ab") as f:
                f.write(body)
        except OSError as e:
            self.send_error(500, str(e))
            return
        self.send_response(200)
        self.send_header("Content-Length", "2")
        self.end_headers()
        self.wfile.write(b"ok")

    def log_message(self, fmt, *args):
        sys.stderr.write("webfs: " + (fmt % args) + "\n")


class ThreadingServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True


def main():
    ap = argparse.ArgumentParser(description="Serve your filesystem over HTTP.")
    ap.add_argument("--port", type=int, default=54220)
    ap.add_argument("--rules", default=".webfsrules", help="Path to rules file (default: ./.webfsrules)")
    ap.add_argument("--all", action="store_true", help="Allow full filesystem access, no prompts")
    args = ap.parse_args()

    start_dir = os.getcwd()
    perms = PermissionManager(args.rules, start_dir, args.all)

    server = ThreadingServer(("0.0.0.0", args.port), Handler)
    server.webfs_start_dir = start_dir
    server.webfs_perms = perms

    sys.stderr.write(f"webfs: serving from cwd={start_dir}, home={HOME}\n")
    sys.stderr.write(f"webfs: listening on 0.0.0.0:{args.port}\n")
    if args.all:
        sys.stderr.write("webfs: --all set, full filesystem access enabled (no prompts)\n")
    elif perms.rules:
        sys.stderr.write("webfs: loaded rules:\n")
        for r in perms.rules:
            sys.stderr.write(f"  {r}\n")
    else:
        sys.stderr.write(f"webfs: no rules file found at {args.rules}; unrecognized paths will prompt\n")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        sys.stderr.write("\nwebfs: shutting down\n")


if __name__ == "__main__":
    main()
