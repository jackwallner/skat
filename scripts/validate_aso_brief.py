#!/usr/bin/env python3
"""Validate the human-written ASO research gate for a card app."""
from __future__ import annotations

import argparse
import re
from pathlib import Path


REQUIRED_HEADINGS = (
    "## Product and search intent",
    "## Competitor evidence",
    "## Keyword map",
    "## Metadata draft",
    "## Localization plan",
    "## Screenshot and experiment plan",
    "## Release gate",
)
PLACEHOLDERS = (
    "GAME TRAINER",
    "<replace",
    "<final name>",
    "<actual game>",
    "<slug>",
    "YYYY-MM-DD",
    "TBD",
    "TODO",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--brief", type=Path, required=True)
    parser.add_argument("--product-name", required=True)
    parser.add_argument("--allow-draft", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not args.brief.is_file():
        raise SystemExit(f"error: missing ASO brief: {args.brief}")
    text = args.brief.read_text(encoding="utf-8")
    errors: list[str] = []
    for heading in REQUIRED_HEADINGS:
        if heading not in text:
            errors.append(f"missing heading: {heading}")

    if len(text) < 900:
        errors.append("brief is too short to contain research evidence")
    if args.product_name.casefold() not in text.casefold():
        errors.append(f"brief does not name the product: {args.product_name}")
    if not args.allow_draft:
        for placeholder in PLACEHOLDERS:
            if placeholder.casefold() in text.casefold():
                errors.append(f"placeholder remains: {placeholder}")
        if re.search(r"^Status:\s*DRAFT\s*$", text, re.IGNORECASE | re.MULTILINE):
            errors.append("brief status is still DRAFT")

    if errors:
        print("ASO brief validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1
    print(f"ASO brief valid: {args.brief}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
