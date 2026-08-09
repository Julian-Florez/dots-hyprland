#!/usr/bin/env python3
import shlex
import subprocess
import http.server
import socketserver
import os.path as path
import urllib.parse
from sys import argv
from urllib.request import urlopen
from urllib.parse import urlparse, parse_qsl, unquote

def get_public_ip():
    urls = [
        "https://api.ipify.org",
        "https://icanhazip.com",
        "https://ifconfig.me/ip",
        "https://ipinfo.io/ip"
    ]
    for url in urls:
        try:
            with urlopen(url, timeout=5) as response:
                ip = response.read().decode("utf8").strip()
                if ip:
                    return ip
        except Exception:
            continue
    # Fallback if entirely offline or IP services are blocked
    return "127.0.0.1"

# Machine's public IP (serves as an Auth key)
public_ip = get_public_ip()

class HttpRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        parsed_url = urlparse(self.path[1:])
        filepath = "/" + unquote(parsed_url.path)
        auth_key = dict(parse_qsl(parsed_url.query)).get("key", None)

        authorized_request = (auth_key == public_ip or auth_key == "127.0.0.1") and self.is_office_file(filepath)

        if not authorized_request:
            self.handle_bad_request()
            return

        if not path.exists(filepath):
            self.send_response(404)
            self.end_headers()
            return

        self.send_response(200)
        self.end_headers()

        with open(filepath, "rb") as file:
            self.wfile.write(file.read())

    def is_office_file(self, filepath):
        if not path.exists(filepath):
            return False
        
        # Check by extension first
        ext = path.splitext(filepath)[1].lower()
        valid_extensions = [".docx", ".xlsx", ".pptx", ".doc", ".xls", ".ppt"]
        if ext not in valid_extensions:
            return False

        # Verify magic bytes (ZIP header for OOXML, OLE2 header for legacy binary)
        try:
            with open(filepath, "rb") as f:
                header = f.read(8)
                if header.startswith(b"PK\x03\x04"):
                    return True
                if header.startswith(b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1"):
                    return True
        except Exception:
            return False

        return False

    def handle_bad_request(self):
        self.send_response(400)
        self.end_headers()

if __name__ == "__main__":
    if len(argv) == 1:
        print("Port not specified.")
        exit(1)

    # Initialize a request handler object
    request_handler = HttpRequestHandler
    PORT = int(argv[1])
    
    # Allow port reuse to prevent "Address already in use" errors
    socketserver.TCPServer.allow_reuse_address = True
    server = socketserver.TCPServer(("", PORT), request_handler)

    print("Server is running on PORT", PORT)
    server.serve_forever()
