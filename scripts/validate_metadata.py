#!/usr/bin/env python3
"""Validate local App Store metadata before an ASC upload."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parent.parent
METADATA = ROOT / "fastlane" / "metadata"
LOCALES = ROOT / "scripts" / "asc-supported-locales.json"
LIMITS = {
    "name": 30,
    "subtitle": 30,
    "keywords": 100,
    "promotional_text": 170,
    "description": 4000,
    "release_notes": 4000,
}
BYTE_LIMIT_FIELDS = {"keywords"}
REQUIRED = tuple(LIMITS) + ("support_url", "marketing_url", "privacy_url")
DEFAULT_FORBIDDEN = ("mahj", "mahjong", "nmjl", "bridge trainer", "bridge+")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--expected-product", default="Skat Trainer")
    parser.add_argument("--forbid", action="append", default=list(DEFAULT_FORBIDDEN))
    return parser.parse_args()


def value(locale: str, field: str) -> str:
    path = METADATA / locale / f"{field}.txt"
    return path.read_text(encoding="utf-8").strip() if path.exists() else ""


def is_url(text: str) -> bool:
    parsed = urlparse(text)
    return parsed.scheme == "https" and bool(parsed.netloc)


def main() -> int:
    args = parse_args()
    locales = json.loads(LOCALES.read_text(encoding="utf-8"))["locales"]
    errors: list[str] = []
    folders = {path.name for path in METADATA.iterdir() if path.is_dir()}
    missing_folders = sorted(set(locales) - folders)
    if missing_folders:
        errors.append(f"missing locale folders: {', '.join(missing_folders)}")

    for locale in locales:
        for field in REQUIRED:
            text = value(locale, field)
            if not text:
                errors.append(f"{locale}/{field}.txt is empty or missing")
                continue
            limit = LIMITS.get(field)
            measured = len(text.encode("utf-8")) if field in BYTE_LIMIT_FIELDS else len(text)
            unit = "bytes" if field in BYTE_LIMIT_FIELDS else "chars"
            if limit and measured > limit:
                errors.append(f"{locale}/{field}.txt is {measured} {unit}, limit is {limit}")
            if "—" in text:
                errors.append(f"{locale}/{field}.txt contains an em dash")
            if "\\n" in text:
                errors.append(f"{locale}/{field}.txt contains a literal newline escape")
            if field.endswith("_url") and not is_url(text):
                errors.append(f"{locale}/{field}.txt is not an https URL: {text}")
            lowered = text.casefold()
            for forbidden in args.forbid:
                if forbidden.casefold() in lowered:
                    errors.append(f"{locale}/{field}.txt contains forbidden template term: {forbidden}")

    en_name = value("en-US", "name")
    if args.expected_product.casefold() not in en_name.casefold():
        errors.append(f"en-US/name.txt does not contain {args.expected_product!r}")

    localized_name_values = {
        value(locale, "name")
        for locale in locales
        if value(locale, "name")
    }
    localized_description_values = {
        value(locale, "description")
        for locale in locales
        if value(locale, "description")
    }
    if len(localized_name_values) < 10:
        errors.append("store names look like a single-language fallback")
    if len(localized_description_values) < 10:
        errors.append("store descriptions look like a single-language fallback")

    for locale in ("en-US", "fr-FR", "es-ES", "ja", "zh-Hans"):
        if value(locale, "name") == value("de-DE", "name"):
            errors.append(f"{locale}/name.txt is still the German storefront name")
        if value(locale, "description") == value("de-DE", "description"):
            errors.append(f"{locale}/description.txt is still the German storefront description")

    if errors:
        print(f"Metadata validation failed with {len(errors)} error(s):")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"Metadata valid: {len(locales)} locales, limits and fallback fields present")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
