#!/usr/bin/env python3
"""Synchronize den Skat+-Abschnitt in den Fastlane-Metadaten."""
from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent / "fastlane" / "metadata"
PLUS_HEADING = "SKAT+ (optionale Mitgliedschaft)"
PLUS_BODY = (
    "Die vier Grundlagenräume bleiben dauerhaft kostenlos. Skat+ ergänzt einen "
    "zusätzlichen Übungssatz in jedem Anfängerraum und den Meistertisch für "
    "anspruchsvolle Entscheidungen zu Drücken, Verteidigung und Stichspiel."
)
SUBSCRIPTIONS_HEADING = "ABONNEMENTS UND KÄUFE"


def replace_plus_section(text: str) -> str:
    pattern = re.compile(
        rf"(?ims)^[^\n]*(?:SKAT\+|DER MEISTERTISCH)[^\n]*\n.*?"
        rf"(?=^\s*{re.escape(SUBSCRIPTIONS_HEADING)}\s*$)",
    )
    replacement = f"{PLUS_HEADING}\n{PLUS_BODY}\n\n"
    updated, count = pattern.subn(replacement, text, count=1)
    if count:
        return updated
    marker = re.search(rf"(?im)^\s*{re.escape(SUBSCRIPTIONS_HEADING)}\s*$", text)
    if marker:
        return text[: marker.start()] + replacement + text[marker.start() :]
    return text.rstrip() + "\n\n" + replacement


def main() -> None:
    en_us = ROOT / "en-US" / "description.txt"
    source = en_us.read_text(encoding="utf-8")
    for locale_dir in sorted(ROOT.iterdir()):
        description = locale_dir / "description.txt"
        if not description.is_file():
            continue
        original = source if locale_dir.name == "en-US" else description.read_text(encoding="utf-8")
        updated = replace_plus_section(original)
        description.write_text(updated, encoding="utf-8")
        print(f"updated {description}")


if __name__ == "__main__":
    main()
