#!/usr/bin/env python3
"""Validate the App Store search and conversion fields for selected locales."""
from __future__ import annotations

import argparse
import re
import unicodedata
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
METADATA = ROOT / "fastlane" / "metadata"
DEFAULT_LOCALES = (
    "en-US",
    "de-DE",
    "ru",
    "zh-Hans",
    "zh-Hant",
)
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
        default=list(DEFAULT_LOCALES),
        help="Locale folders to validate (default: en-US, de-DE, ru, zh-Hans, zh-Hant).",
    )
    return parser.parse_args()


def read_field(locale: str, field: str) -> str:
    path = METADATA / locale / f"{field}.txt"
    if not path.is_file():
        return ""
    return path.read_text(encoding="utf-8").rstrip("\n")


def normalize_token(token: str) -> str:
    return unicodedata.normalize("NFKC", token).casefold()


def words(text: str) -> set[str]:
    return {normalize_token(token) for token in re.findall(r"[^\W_]+", text, re.UNICODE)}


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
        if any(character.isspace() for character in keywords):
            errors.append(f"{locale}/keywords.txt contains whitespace between keywords")

        tokens = [token for token in keywords.split(",") if token]
        if len(tokens) != len(keywords.split(",")):
            errors.append(f"{locale}/keywords.txt contains an empty keyword")
        normalized = [normalize_token(token) for token in tokens]
        if len(normalized) != len(set(normalized)):
            errors.append(f"{locale}/keywords.txt contains duplicate keywords")

        repeated = sorted(set(normalized) & words(values["name"] + " " + values["subtitle"]))
        if repeated:
            errors.append(
                f"{locale}/keywords.txt repeats name or subtitle tokens: {', '.join(repeated)}"
            )

    return errors


def main() -> int:
    args = parse_args()
    errors = [error for locale in args.locales for error in validate_locale(locale)]
    if errors:
        print(f"ASO metadata validation failed with {len(errors)} error(s):")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"ASO metadata valid: {len(args.locales)} locales, field limits and keyword rules passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
