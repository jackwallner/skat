#!/usr/bin/env python3
"""Pre-submit check that the paywall can actually sell something.

The sibling Cribbage Trainer build was rejected because RevenueCat served an
offering with zero packages: products existed only on the Test Store app, so an
App Store build had nothing to purchase and the CTA threw productsUnavailable.
Nothing in the build, the tests, or the ASC readiness report catches that,
because every one of those pieces was individually fine.

This asks the two questions that matter, in the order the app asks them:

1. What does RevenueCat serve an iOS App Store build? (public SDK key, the
   same endpoint the SDK hits) - must be three packages.
2. Does every product id it serves exist in App Store Connect for this app,
   in a state StoreKit can fetch?

Exits non-zero if either answer is wrong. Run before submitting for review.
Needs ASC creds sourced (see ~/.baseball_credentials).
"""

from __future__ import annotations

import json
import sys
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from asc_lib import (  # noqa: E402
    ASCClient, bearer_token, bundle_id_from_appfile, find_app, list_all, load_credentials,
)

# Public SDK key, same one the app ships in SubscriptionService.swift.
PUBLIC_KEY = "appl_hCITKfPBvZWFXEfrHDEsRuvAAYy"
EXPECTED_PACKAGES = {"$rc_monthly", "$rc_annual", "$rc_lifetime"}

# States in which StoreKit can still fetch the product (sandbox or production).
FETCHABLE = {
    "APPROVED", "READY_TO_SUBMIT", "WAITING_FOR_REVIEW", "IN_REVIEW",
    "PENDING_BINARY_APPROVAL",
}


def offerings_as_the_sdk_sees_them() -> dict[str, str]:
    url = "https://api.revenuecat.com/v1/subscribers/$RCAnonymousID:storeconfigcheck/offerings"
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {PUBLIC_KEY}")
    req.add_header("X-Platform", "iOS")
    req.add_header("X-Version", "5.0.0")
    with urllib.request.urlopen(req) as resp:
        data = json.load(resp)
    current = next(
        (o for o in data["offerings"] if o["identifier"] == data["current_offering_id"]),
        None,
    )
    if current is None:
        sys.exit("FAIL: RevenueCat has no current offering")
    return {p["identifier"]: p["platform_product_identifier"] for p in current["packages"]}


def app_store_product_states() -> dict[str, str]:
    key_id, issuer_id, key_path = load_credentials()
    client = ASCClient(bearer_token(key_id, issuer_id, key_path))
    app = find_app(client, bundle_id_from_appfile())
    states: dict[str, str] = {}
    for product in list_all(client, f"/apps/{app['id']}/inAppPurchasesV2?limit=50"):
        states[product["attributes"]["productId"]] = product["attributes"]["state"]
    for group in list_all(client, f"/apps/{app['id']}/subscriptionGroups?limit=10"):
        for sub in list_all(client, f"/subscriptionGroups/{group['id']}/subscriptions?limit=50"):
            states[sub["attributes"]["productId"]] = sub["attributes"]["state"]
    return states


def main() -> int:
    served = offerings_as_the_sdk_sees_them()
    states = app_store_product_states()

    problems: list[str] = []
    missing_packages = EXPECTED_PACKAGES - set(served)
    if missing_packages:
        problems.append(f"offering is missing {sorted(missing_packages)}")

    for package, product_id in sorted(served.items()):
        state = states.get(product_id, "NOT IN APP STORE CONNECT")
        ok = state in FETCHABLE
        print(f"{package:14} {product_id:45} {state}{'' if ok else '   <-- PROBLEM'}")
        if not ok:
            problems.append(f"{product_id} is {state}")

    if problems:
        print("\nFAIL: " + "; ".join(problems))
        return 1
    print(f"\nOK: {len(served)} packages, every product fetchable")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
