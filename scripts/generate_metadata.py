#!/usr/bin/env python3
"""Seed every supported App Store Connect locale from the canonical locale.

The card-app release workflow keeps one authoritative en-US copy, then creates
complete fallback folders for every ASC-supported locale. Missing local
translations are deliberate English fallbacks until a real translation is
reviewed. This script never overwrites existing locale text unless --force is
passed.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
METADATA = ROOT / "fastlane" / "metadata"
LOCALES = ROOT / "scripts" / "asc-supported-locales.json"
FIELDS = (
    "name",
    "subtitle",
    "keywords",
    "description",
    "promotional_text",
    "release_notes",
    "support_url",
    "marketing_url",
    "privacy_url",
    "apple_tv_privacy_policy",
)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-locale", default="en-US")
    parser.add_argument("--write", action="store_true", help="Write missing files")
    parser.add_argument("--force", action="store_true", help="Replace every locale with the source text")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    source_dir = METADATA / args.source_locale
    if not source_dir.is_dir():
        raise SystemExit(f"error: source locale does not exist: {source_dir}")

    locales = json.loads(LOCALES.read_text(encoding="utf-8"))["locales"]
    planned = 0
    written = 0
    for locale in locales:
        destination = METADATA / locale
        for field in FIELDS:
            source = source_dir / f"{field}.txt"
            target = destination / f"{field}.txt"
            if not source.exists():
                continue
            if not args.force and target.exists() and read(target).strip():
                continue
            planned += 1
            if args.write:
                destination.mkdir(parents=True, exist_ok=True)
                target.write_text(read(source), encoding="utf-8")
                written += 1

    mode = "wrote" if args.write else "would write"
    print(f"{mode} {written if args.write else planned} metadata file(s) across {len(locales)} locales")
    if not args.write:
        print("Run again with --write. Add --force only when replacing reviewed translations is intentional.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
