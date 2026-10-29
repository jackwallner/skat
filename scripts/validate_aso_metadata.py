#!/usr/bin/env python3
"""Validate App Store search and conversion fields for configured locales."""
from __future__ import annotations

import argparse
import json
import re
import unicodedata
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
METADATA = ROOT / "fastlane" / "metadata"
SUPPORTED_LOCALES = ROOT / "scripts" / "asc-supported-locales.json"
LIMITS = {
    "name": 30,
    "subtitle": 30,
    "keywords": 100,
    "promotional_text": 170,
    "description": 4000,
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--locales",
        nargs="+",
        default=None,
        help="Locale folders to validate (default: every configured locale).",
    )
    return parser.parse_args()


def read_field(locale: str, field: str) -> str:
    path = METADATA / locale / f"{field}.txt"
    if not path.is_file():
        return ""
    value = path.read_text(encoding="utf-8")
    return value[:-1] if value.endswith("\n") else value


def words(text: str) -> set[str]:
    normalized = unicodedata.normalize("NFKC", text).casefold()
    found: list[str] = []
    current: list[str] = []

    for character in normalized:
        category = unicodedata.category(character)
        if category[0] in {"L", "N"} or (category[0] == "M" and current):
            current.append(character)
        elif current:
            found.append("".join(current))
            current = []

    if current:
        found.append("".join(current))

    return set(found)


def validate_locale(locale: str) -> list[str]:
    errors: list[str] = []
    values = {field: read_field(locale, field) for field in LIMITS}

    for field, limit in LIMITS.items():
        value = values[field]
        if not value:
            errors.append(f"{locale}/{field}.txt is empty or missing")
            continue
        if value != value.strip():
            errors.append(f"{locale}/{field}.txt has leading or trailing whitespace")
        if "\u2014" in value:
            errors.append(f"{locale}/{field}.txt contains an em dash")
        if len(value) > limit:
            errors.append(f"{locale}/{field}.txt is {len(value)} characters, limit is {limit}")

    keywords = values["keywords"]
    if keywords:
        if len(keywords.encode("utf-8")) > 100:
            errors.append(
                f"{locale}/keywords.txt is {len(keywords.encode('utf-8'))} bytes, limit is 100"
            )
        if re.search(r",\s", keywords):
            errors.append(f"{locale}/keywords.txt contains whitespace after a comma")

        tokens = [token for token in keywords.split(",") if token]
        if len(tokens) != len(keywords.split(",")):
            errors.append(f"{locale}/keywords.txt contains an empty keyword")
        keyword_words = [word for token in tokens for word in words(token)]
        duplicates = sorted({word for word in keyword_words if keyword_words.count(word) > 1})
        if duplicates:
            errors.append(
                f"{locale}/keywords.txt contains duplicate tokens: {', '.join(duplicates)}"
            )

        repeated = sorted(set(keyword_words) & words(values["name"] + " " + values["subtitle"]))
        if repeated:
            errors.append(
                f"{locale}/keywords.txt repeats name or subtitle tokens: {', '.join(repeated)}"
            )

    return errors


def main() -> int:
    args = parse_args()
    locales = args.locales
    if locales is None:
        locales = json.loads(SUPPORTED_LOCALES.read_text(encoding="utf-8"))["locales"]
    errors = [error for locale in locales for error in validate_locale(locale)]
    if errors:
        print(f"ASO metadata validation failed with {len(errors)} error(s):")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"ASO metadata valid: {len(locales)} locales, field limits and keyword rules passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
