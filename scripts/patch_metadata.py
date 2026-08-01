#!/usr/bin/env python3
"""Apply one reviewed metadata change without editing every locale by hand."""
from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
METADATA = ROOT / "fastlane" / "metadata"
LOCALES = ROOT / "scripts" / "asc-supported-locales.json"
FIELDS = {"name", "subtitle", "keywords", "description", "promotional_text", "release_notes", "support_url", "marketing_url", "privacy_url"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--field", required=True, choices=sorted(FIELDS))
    parser.add_argument("--value", required=True)
    parser.add_argument("--locale", action="append")
    parser.add_argument("--all-locales", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not args.all_locales and not args.locale:
        raise SystemExit("error: pass --locale or --all-locales")
    locales = args.locale or json.loads(LOCALES.read_text(encoding="utf-8"))["locales"]
    for locale in sorted(set(locales)):
        target = METADATA / locale / f"{args.field}.txt"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(args.value.rstrip() + "\n", encoding="utf-8")
        print(target)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
