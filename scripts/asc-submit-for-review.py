#!/usr/bin/env python3
"""Submit the current editable App Store version for review.

Uses the modern reviewSubmissions flow:
  1. reuse an OPEN reviewSubmission for the app, or create one (platform IOS)
  2. add the app version and versioned subscription/IAP containers (idempotent)
  3. PATCH submitted=true  (this is where ASC validates everything)

Paths are relative to asc_lib.API (already ends in /v1) , do NOT prefix /v1.

A validation failure leaves the submission OPEN and prints the exact blockers,
so this is safe to run to discover what remains. Pass --dry-run to stop before
the final submit and just report the prepared submission.
"""
from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from asc_lib import (
    ASCClient, bearer_token, bundle_id_from_appfile, find_app,
    find_editable_version, list_all, load_credentials,
)

V2_API = "https://api.appstoreconnect.apple.com/v2"
# States a product version can be in and still need to travel with the binary.
# The rejected ones matter on a resubmit: canceling a submission drops every
# product version it carried to DEVELOPER_REJECTED, and leaving them out of the
# next submission ships the app with its purchases unreviewed.
READY_STATES = frozenset({
    "PREPARE_FOR_SUBMISSION",
    "READY_FOR_REVIEW",
    "DEVELOPER_REJECTED",
    "REJECTED",
})


def v2_list_all(client: ASCClient, path: str) -> list[dict]:
    """List a v2 relationship while reusing the ASC client's bearer token."""
    url = f"{V2_API}{path}"
    result: list[dict] = []
    while url:
        req = urllib.request.Request(url, headers={"Authorization": f"Bearer {client.token}"})
        try:
            with urllib.request.urlopen(req, timeout=120) as response:
                payload = json.loads(response.read().decode())
        except urllib.error.HTTPError as error:
            detail = error.read().decode()
            raise RuntimeError(f"GET {url} -> {error.code}: {detail}") from error
        result.extend(payload.get("data", []))
        url = payload.get("links", {}).get("next", "")
    return result


def current_version(versions: list[dict]) -> dict | None:
    ready = [version for version in versions if version.get("attributes", {}).get("state") in READY_STATES]
    return max(ready, key=lambda version: version.get("attributes", {}).get("version", 0), default=None)


def product_version_targets(client: ASCClient, app_id: str) -> list[tuple[str, str]]:
    """Return version relationships that must travel with the first app binary."""
    targets: list[tuple[str, str]] = []
    groups = list_all(client, f"/apps/{app_id}/subscriptionGroups")
    for group in groups:
        group_version = current_version(
            list_all(client, f"/subscriptionGroups/{group['id']}/versions")
        )
        if group_version:
            targets.append(("subscriptionGroupVersion", group_version["id"]))

        subscriptions = list_all(client, f"/subscriptionGroups/{group['id']}/subscriptions")
        for subscription in subscriptions:
            version = current_version(
                list_all(client, f"/subscriptions/{subscription['id']}/versions")
            )
            if version:
                targets.append(("subscriptionVersion", version["id"]))

    purchases = list_all(client, f"/apps/{app_id}/inAppPurchasesV2")
    for purchase in purchases:
        version = current_version(
            v2_list_all(client, f"/inAppPurchases/{purchase['id']}/versions")
        )
        if version:
            targets.append(("inAppPurchaseVersion", version["id"]))
    return targets


def existing_targets(client: ASCClient, submission_id: str) -> set[tuple[str, str]]:
    include = "appStoreVersion,subscriptionGroupVersion,subscriptionVersion,inAppPurchaseVersion"
    items = list_all(client, f"/reviewSubmissions/{submission_id}/items?include={include}")
    found: set[tuple[str, str]] = set()
    for item in items:
        for relationship in (
            "appStoreVersion",
            "subscriptionGroupVersion",
            "subscriptionVersion",
            "inAppPurchaseVersion",
        ):
            data = (item.get("relationships", {}).get(relationship, {}).get("data") or {})
            if isinstance(data, dict) and data.get("id"):
                found.add((relationship, data["id"]))
    return found


def add_item(client: ASCClient, submission_id: str, kind: str, resource_id: str,
             found: set[tuple[str, str]]) -> None:
    target = (kind, resource_id)
    if target in found:
        print(f"{kind} already an item: {resource_id}")
        return
    client.request("POST", "/reviewSubmissionItems", {
        "data": {
            "type": "reviewSubmissionItems",
            "relationships": {
                "reviewSubmission": {
                    "data": {"type": "reviewSubmissions", "id": submission_id}
                },
                kind: {"data": {"type": f"{kind}s", "id": resource_id}},
            },
        }
    })
    found.add(target)
    print(f"added {kind}: {resource_id}")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    key_id, issuer_id, key_path = load_credentials()
    c = ASCClient(bearer_token(key_id, issuer_id, key_path))
    app = find_app(c, bundle_id_from_appfile())
    app_id = app["id"]
    version = find_editable_version(c, app_id)
    if not version:
        print("No editable version.")
        return 1
    vid = version["id"]
    print(f"App {app_id}  version {version['attributes'].get('versionString')} ({vid})")

    # 1. Reuse an editable (not-yet-submitted) reviewSubmission or create one.
    #    Prefer the app relationship path; top-level filter[app] 404s for some keys.
    all_subs = list_all(c, f"/apps/{app_id}/reviewSubmissions?limit=50")
    open_sub = next(
        (s for s in all_subs if s["attributes"].get("state") == "READY_FOR_REVIEW"),
        None,
    )
    if open_sub:
        sub_id = open_sub["id"]
        print(f"Reusing open reviewSubmission {sub_id} (state={open_sub['attributes'].get('state')})")
    else:
        created = c.request("POST", "/reviewSubmissions", {
            "data": {
                "type": "reviewSubmissions",
                "attributes": {"platform": "IOS"},
                "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
            }
        })
        sub_id = created["data"]["id"]
        print(f"Created reviewSubmission {sub_id}")

    # 2. Add all version containers that Apple reviews with the first binary.
    #    ASC validates readiness on each POST as well as on the final submit.
    found = existing_targets(c, sub_id)
    targets = product_version_targets(c, app_id)
    print(f"Product version targets: {len(targets)}")
    try:
        for kind, resource_id in targets:
            add_item(c, sub_id, kind, resource_id, found)
        add_item(c, sub_id, "appStoreVersion", vid, found)
    except Exception as e:
        print("ADD ITEM FAILED (version or product is not ready for review):")
        print(str(e)[:4000])
        return 2

    if args.dry_run:
        print("Dry run: prepared but NOT submitted.")
        return 0

    # 3. Submit , ASC validates here; failure leaves the submission open.
    try:
        res = c.request("PATCH", f"/reviewSubmissions/{sub_id}", {
            "data": {
                "type": "reviewSubmissions",
                "id": sub_id,
                "attributes": {"submitted": True},
            }
        })
        st = res["data"]["attributes"].get("state")
        print(f"SUBMITTED. reviewSubmission state = {st}")
        return 0
    except Exception as e:
        print("SUBMIT FAILED (submission left open, nothing sent):")
        print(str(e)[:4000])
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
