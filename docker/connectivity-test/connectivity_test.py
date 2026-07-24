#!/usr/bin/env python3
"""Minimal port-80 connectivity test tool for dual-home-cloudwan-test (architecture.md §6).

Two modes, selected by argv[1]:
  listen            - run an HTTP server on port 80 for a bounded duration
  check <target_ip> - attempt a single TCP connection to <target_ip>:80, print
                       PASS/FAIL, and exit 0/1 accordingly
"""
import http.server
import socket
import sys
import time

LISTEN_DURATION_SECONDS = 300
CHECK_TIMEOUT_SECONDS = 5
PORT = 80


def listen() -> None:
    print(f"Listening on port {PORT} for up to {LISTEN_DURATION_SECONDS}s", flush=True)
    server = http.server.HTTPServer(("0.0.0.0", PORT), http.server.SimpleHTTPRequestHandler)
    server.timeout = LISTEN_DURATION_SECONDS
    deadline = time.time() + LISTEN_DURATION_SECONDS
    while time.time() < deadline:
        server.handle_request()
    print("Listen duration elapsed, exiting", flush=True)


def check(target_ip: str) -> None:
    print(f"Checking TCP connectivity to {target_ip}:{PORT} (timeout {CHECK_TIMEOUT_SECONDS}s)", flush=True)
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(CHECK_TIMEOUT_SECONDS)
    result = s.connect_ex((target_ip, PORT))
    s.close()
    if result == 0:
        print("PASS", flush=True)
        sys.exit(0)
    print(f"FAIL (errno {result})", flush=True)
    sys.exit(1)


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "listen"
    if mode == "listen":
        listen()
    elif mode == "check":
        if len(sys.argv) < 3:
            print("Usage: check <target_ip>", file=sys.stderr)
            sys.exit(2)
        check(sys.argv[2])
    else:
        print(f"Unknown mode: {mode}", file=sys.stderr)
        sys.exit(2)
