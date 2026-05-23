#!/usr/bin/env python3
"""Mock GitHub Releases server for testing Waydir's in-app updater.

Usage:
    python3 scripts/mock_update_server.py --asset <path> --version <ver>

Point the installed app at it:
    WAYDIR_GITHUB_API_BASE=http://127.0.0.1:8765 waydir
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse


def build_release_json(version: str, asset_path: str, download_url: str) -> list[dict]:
    name = os.path.basename(asset_path)
    size = os.path.getsize(asset_path)
    published = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    return [
        {
            "tag_name": f"v{version}",
            "name": f"Waydir {version}",
            "body": f"Mock update to {version} for local testing.",
            "prerelease": False,
            "published_at": published,
            "html_url": f"http://localhost/mock/releases/v{version}",
            "assets": [
                {
                    "name": name,
                    "browser_download_url": download_url,
                    "size": size,
                }
            ],
        }
    ]


def make_handler(version: str, asset_path: str, public_origin: str, content_type: str):
    asset_basename = os.path.basename(asset_path)
    download_url = f"{public_origin}/download/{asset_basename}"

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, format, *args):  # noqa: A002, N802
            sys.stderr.write(
                f"[mock] {self.address_string()} - {format % args}\n"
            )

        def do_GET(self):  # noqa: N802
            parsed = urlparse(self.path)
            path = parsed.path

            if path == "/repos/Waydir/Waydir/releases":
                payload = json.dumps(
                    build_release_json(version, asset_path, download_url)
                ).encode("utf-8")
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(payload)))
                self.end_headers()
                self.wfile.write(payload)
                return

            if path == f"/download/{asset_basename}":
                size = os.path.getsize(asset_path)
                self.send_response(200)
                self.send_header("Content-Type", content_type)
                self.send_header("Content-Length", str(size))
                self.send_header(
                    "Content-Disposition",
                    f'attachment; filename="{asset_basename}"',
                )
                self.end_headers()
                with open(asset_path, "rb") as f:
                    while True:
                        chunk = f.read(64 * 1024)
                        if not chunk:
                            break
                        self.wfile.write(chunk)
                return

            self.send_response(404)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"not found\n")

    return Handler


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--asset",
        "--rpm",
        dest="asset",
        required=True,
        help="Path to the installer/archive to serve (rpm/deb/exe/zip/dmg/tar.gz)",
    )
    ap.add_argument("--version", required=True, help="Version string (e.g. 0.4.2)")
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--port", type=int, default=8765)
    ap.add_argument(
        "--public-origin",
        default=None,
        help="Origin advertised in browser_download_url "
        "(defaults to http://<host>:<port>)",
    )
    args = ap.parse_args()

    asset_path = os.path.abspath(args.asset)
    if not os.path.isfile(asset_path):
        print(f"error: asset not found: {asset_path}", file=sys.stderr)
        return 2

    ext = os.path.splitext(asset_path)[1].lower()
    content_type = {
        ".rpm": "application/x-rpm",
        ".deb": "application/vnd.debian.binary-package",
        ".exe": "application/vnd.microsoft.portable-executable",
        ".zip": "application/zip",
        ".dmg": "application/x-apple-diskimage",
        ".gz": "application/gzip",
    }.get(ext, "application/octet-stream")

    public_origin = args.public_origin or f"http://{args.host}:{args.port}"
    handler = make_handler(args.version, asset_path, public_origin, content_type)
    httpd = ThreadingHTTPServer((args.host, args.port), handler)

    print(
        f"[mock] serving v{args.version} from {asset_path}\n"
        f"[mock] api:      http://{args.host}:{args.port}/repos/Waydir/Waydir/releases\n"
        f"[mock] download: {public_origin}/download/{os.path.basename(asset_path)}\n"
        f"[mock] run app:  WAYDIR_GITHUB_API_BASE=http://{args.host}:{args.port} waydir",
        file=sys.stderr,
    )
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[mock] shutting down", file=sys.stderr)
        httpd.server_close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
