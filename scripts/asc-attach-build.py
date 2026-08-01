#!/usr/bin/env python3
"""Attach a valid uploaded build to the current editable App Store version.

Usage:
    source ~/.baseball_credentials
    ASC_APP_VERSION=1.0 ASC_BUILD_NUMBER=15 python3 scripts/asc-attach-build.py

The upload to TestFlight and the version attachment are separate App Store
Connect operations. This script makes the second operation explicit and
idempotent, so a future Cardport app can reuse the same release handoff.
"""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from asc_lib import (
    ASCClient,
    bearer_token,
    bundle_id_from_appfile,
    find_app,
    find_version_by_string,
    list_all,
    load_credentials,
)


ROOT = Path(__file__).resolve().parent.parent


def project_setting(name: str) -> str:
    project = (ROOT / "project.yml").read_text(encoding="utf-8")
    match = re.search(rf"^\s*{re.escape(name)}:\s*[\"']?([^\"'\n]+)", project, re.MULTILINE)
    if not match:
        raise SystemExit(f"error: project.yml has no {name}")
    return match.group(1).strip()


def main() -> int:
    version_string = os.environ.get("ASC_APP_VERSION") or project_setting("MARKETING_VERSION")
    build_number = os.environ.get("ASC_BUILD_NUMBER") or project_setting("CURRENT_PROJECT_VERSION")

    client = ASCClient(bearer_token(*load_credentials()))
    app = find_app(client, bundle_id_from_appfile())
    version = find_version_by_string(client, app["id"], version_string)
    if not version:
        raise SystemExit(f"error: no App Store version {version_string}")

    builds = list_all(client, f"/builds?filter[app]={app['id']}&limit=200&sort=-version")
    matching = [b for b in builds if str(b["attributes"].get("version")) == build_number]
    if not matching:
        raise SystemExit(f"error: no uploaded build {build_number} for {app['id']}")
    build = matching[0]
    attrs = build["attributes"]
    if attrs.get("processingState") != "VALID":
        raise SystemExit(
            f"error: build {build_number} is {attrs.get('processingState')}, not VALID"
        )
    if attrs.get("expired"):
        raise SystemExit(f"error: build {build_number} is expired")

    version_id = version["id"]
    current = client.get(f"/appStoreVersions/{version_id}/build").get("data")
    if current and current["id"] == build["id"]:
        print(f"build {build_number} is already attached to version {version_string}")
        return 0

    client.patch(
        f"/appStoreVersions/{version_id}",
        {
            "data": {
                "type": "appStoreVersions",
                "id": version_id,
                "relationships": {
                    "build": {"data": {"type": "builds", "id": build["id"]}}
                },
            }
        },
    )
    attached = client.get(f"/appStoreVersions/{version_id}/build").get("data")
    if not attached or attached["id"] != build["id"]:
        raise SystemExit("error: App Store Connect did not confirm the build attachment")
    print(f"attached build {build_number} to version {version_string}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
