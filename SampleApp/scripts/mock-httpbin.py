#!/usr/bin/env python3
"""Tiny deterministic stand-in for httpbin used by the end-to-end CI job.

Responds to any GET with a 200 and an httpbin-/get-shaped JSON body, matching
the schema in Sources/SampleLib/openapi.yaml. This keeps the end-to-end test
off the public internet so it can't flake on an external host.

Usage: mock-httpbin.py [port]   (default port: 8080)
"""
import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8080


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = json.dumps(
            {
                "args": {},
                "headers": {h: v for h, v in self.headers.items()},
                "origin": "127.0.0.1",
                "url": self.path,
            }
        ).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass  # keep CI logs quiet


if __name__ == "__main__":
    HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
