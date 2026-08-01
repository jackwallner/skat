#!/usr/bin/env python3
"""Attach a 1024x1024 review image to an App Store Connect IAP version.

The v2 image resource belongs to the version container, not the parent IAP.
Usage:
    python3 scripts/asc-attach-iap-version-image.py \
        --version-id <in-app-purchase-version-id>
"""
from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import asc_lib

V2_API = "https://api.appstoreconnect.apple.com/v2"
DEFAULT_IMAGE = "SkatTrainer/Assets.xcassets/AppIcon.appiconset/icon-1024.png"


def v2_request(token: str, method: str, path: str, body: dict | None = None) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    request = urllib.request.Request(
        V2_API + path,
        data=data,
        method=method,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            raw = response.read().decode()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        detail = error.read().decode()
        raise RuntimeError(f"{method} {path} -> {error.code}: {detail}") from error


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version-id", required=True)
    parser.add_argument("--image", default=DEFAULT_IMAGE)
    args = parser.parse_args()

    image_path = Path(args.image)
    if not image_path.is_file():
        raise SystemExit(f"error: no image: {image_path}")

    key_id, issuer_id, key_path = asc_lib.load_credentials()
    token = asc_lib.bearer_token(key_id, issuer_id, key_path)
    client = asc_lib.ASCClient(token)
    existing = client.get(f"/inAppPurchaseVersions/{args.version_id}/image").get("data")
    if existing:
        print(f"image already attached: {existing['id']}")
        return 0

    blob = image_path.read_bytes()
    reserved = v2_request(token, "POST", "/inAppPurchaseImages", {
        "data": {
            "type": "inAppPurchaseImages",
            "attributes": {"fileSize": len(blob), "fileName": image_path.name},
            "relationships": {
                "version": {
                    "data": {"type": "inAppPurchaseVersions", "id": args.version_id}
                }
            },
        }
    })["data"]

    for operation in reserved["attributes"]["uploadOperations"]:
        chunk = blob[operation["offset"]:operation["offset"] + operation["length"]]
        upload = urllib.request.Request(
            operation["url"], data=chunk, method=operation["method"]
        )
        for header in operation.get("requestHeaders", []):
            upload.add_header(header["name"], header["value"])
        with urllib.request.urlopen(upload, timeout=300) as response:
            response.read()

    v2_request(token, "PATCH", f"/inAppPurchaseImages/{reserved['id']}", {
        "data": {
            "type": "inAppPurchaseImages",
            "id": reserved["id"],
            "attributes": {"uploaded": True},
        }
    })
    print(f"attached image {reserved['id']} to IAP version {args.version_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
