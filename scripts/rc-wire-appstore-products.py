#!/usr/bin/env python3
"""Wire the real App Store products into RevenueCat.

The project was scaffolded with Test Store products (`monthly`, `yearly`,
`lifetime`) and no App Store products at all. An App Store build fetches
nothing from that setup: the current offering comes back with zero packages,
`package(for:)` returns nil, and the paywall throws productsUnavailable. That
is what App Review saw.

This script creates the three App Store products from the bundle id RevenueCat
already has on the App Store app record, attaches them to the entitlement, and
attaches them to the $rc_monthly / $rc_annual / $rc_lifetime packages of the
current offering.

Idempotent: anything already correct is left alone. Read-only diagnosis of the
end state is the SDK-facing offerings endpoint, printed at the end.

Usage: python3 scripts/rc-wire-appstore-products.py
       (RC_SECRET_KEY read from CREDENTIALS below)
"""

from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

BASE = "https://api.revenuecat.com/v2"
CREDENTIALS = Path.home() / ".skat_credentials"
ENTITLEMENT = "pro"

# suffix -> (product type, name suffix, package lookup key, package name)
PLANS = {
    "monthly": ("subscription", "Monthly", "$rc_monthly", "Monthly"),
    "yearly": ("subscription", "Yearly", "$rc_annual", "Yearly"),
    "lifetime": ("one_time", "Lifetime", "$rc_lifetime", "Lifetime"),
}


def secret_key() -> str:
    for line in CREDENTIALS.read_text().splitlines():
        if line.startswith("RC_SECRET_KEY"):
            return line.split("=", 1)[1].strip().strip('"').strip("'")
    sys.exit(f"RC_SECRET_KEY not found in {CREDENTIALS}")


KEY = secret_key()


def request(method: str, path: str, body: dict | None = None) -> dict:
    req = urllib.request.Request(BASE + path, method=method)
    req.add_header("Authorization", f"Bearer {KEY}")
    req.add_header("Content-Type", "application/json")
    data = json.dumps(body).encode() if body is not None else None
    try:
        with urllib.request.urlopen(req, data=data) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"{method} {path} -> {e.code}: {e.read().decode()[:400]}")


def ensure_entitlement(pid: str, membership: str) -> dict:
    """Return the entitlement products should hang off.

    Prefer `pro`, the fleet's canonical key. These projects were scaffolded
    with the player-facing name as the key instead, and RevenueCat allows
    neither editing a lookup_key nor (in at least one project) creating `pro`:
    the create 409s on a `pro` the list endpoint never returns. So fall back to
    whatever single entitlement the project exposes; the app treats any active
    entitlement as membership rather than matching one hardcoded key.
    """
    entitlements = request("GET", f"/projects/{pid}/entitlements?limit=50")["items"]
    existing = next((e for e in entitlements if e["lookup_key"] == ENTITLEMENT), None)
    if existing:
        print(f"entitlement {ENTITLEMENT} exists: {existing['id']}")
        return existing
    try:
        created = request("POST", f"/projects/{pid}/entitlements", {
            "lookup_key": ENTITLEMENT,
            "display_name": membership,
        })
        print(f"created entitlement {ENTITLEMENT} ({created['id']})")
        return created
    except RuntimeError as e:
        if "already_exists" not in str(e) and "already an entitlement" not in str(e):
            raise
    if len(entitlements) != 1:
        sys.exit(f"cannot pick an entitlement: {[e['lookup_key'] for e in entitlements]}")
    fallback = entitlements[0]
    print(f"WARNING: using entitlement '{fallback['lookup_key']}' ({fallback['id']}); "
          f"'{ENTITLEMENT}' is reserved but invisible to the API")
    return fallback


def main() -> None:
    project = request("GET", "/projects")["items"][0]
    pid = project["id"]
    print(f"project: {project['name']} ({pid})")

    apps = request("GET", f"/projects/{pid}/apps")["items"]
    app = next(a for a in apps if a["type"] == "app_store")
    bundle_id = app["app_store"]["bundle_id"]
    print(f"app store app: {app['id']} ({bundle_id})")

    entitlements = request("GET", f"/projects/{pid}/entitlements?limit=50")["items"]
    membership = entitlements[0]["display_name"] if entitlements else project["name"]

    existing = request("GET", f"/projects/{pid}/products?limit=50")["items"]
    by_identifier = {p["store_identifier"]: p for p in existing if p["app_id"] == app["id"]}

    products: dict[str, dict] = {}
    for suffix, (kind, name, _, _) in PLANS.items():
        identifier = f"{bundle_id}.{suffix}"
        product = by_identifier.get(identifier)
        if product is None:
            product = request("POST", f"/projects/{pid}/products", {
                "store_identifier": identifier,
                "app_id": app["id"],
                "type": kind,
                "display_name": f"{membership} {name}",
            })
            print(f"created product {identifier} ({product['id']})")
        else:
            print(f"product exists: {identifier} ({product['id']})")
        products[suffix] = product

    entitlement = ensure_entitlement(pid, membership)
    attached = request(
        "GET", f"/projects/{pid}/entitlements/{entitlement['id']}/products?limit=50"
    )["items"]
    attached_ids = {p["id"] for p in attached}
    missing = [p["id"] for p in products.values() if p["id"] not in attached_ids]
    if missing:
        request(
            "POST",
            f"/projects/{pid}/entitlements/{entitlement['id']}/actions/attach_products",
            {"product_ids": missing},
        )
        print(f"attached {len(missing)} product(s) to entitlement {entitlement['lookup_key']}")
    else:
        print(f"entitlement {entitlement['lookup_key']} already holds every product")

    offerings = request("GET", f"/projects/{pid}/offerings?limit=50")["items"]
    offering = next((o for o in offerings if o.get("is_current")), offerings[0])
    print(f"offering: {offering['lookup_key']} ({offering['id']})")
    packages = request(
        "GET", f"/projects/{pid}/offerings/{offering['id']}/packages?limit=50"
    )["items"]
    by_lookup = {p["lookup_key"]: p for p in packages}

    for suffix, (_, _, lookup_key, package_name) in PLANS.items():
        package = by_lookup.get(lookup_key)
        if package is None:
            package = request("POST", f"/projects/{pid}/offerings/{offering['id']}/packages", {
                "lookup_key": lookup_key,
                "display_name": package_name,
            })
            print(f"created package {lookup_key} ({package['id']})")
        product_id = products[suffix]["id"]
        # Package products come back wrapped: {eligibility_criteria, product}.
        in_package = [
            entry.get("product", entry)
            for entry in request(
                "GET", f"/projects/{pid}/packages/{package['id']}/products?limit=50"
            )["items"]
        ]
        if any(p["id"] == product_id for p in in_package):
            print(f"{lookup_key}: {products[suffix]['store_identifier']} already attached")
            continue
        request(
            "POST", f"/projects/{pid}/packages/{package['id']}/actions/attach_products",
            {"products": [{"product_id": product_id, "eligibility_criteria": "all"}]},
        )
        print(f"{lookup_key}: attached {products[suffix]['store_identifier']}")

    print("done")


if __name__ == "__main__":
    main()
