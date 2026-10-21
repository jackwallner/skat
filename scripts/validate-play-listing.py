#!/usr/bin/env python3
"""Validate the Google Play listing text for all 50 locales.

Layout (fastlane supply): android/play-assets/metadata/android/<locale>/
{title,short_description,full_description}.txt. Run from anywhere; exits 1 on failure.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "android/play-assets/metadata/android"
LOCALES = (
    "en-US en-GB en-AU en-CA en-IN de-DE fr-FR fr-CA es-ES es-419 es-US pt-BR pt-PT "
    "it-IT nl-NL sv-SE no-NO da-DK fi-FI pl-PL cs-CZ sk sl hr hu-HU ro el-GR tr-TR "
    "ru-RU uk ar iw-IL hi-IN bn-BD mr-IN ta-IN te-IN kn-IN ml-IN id ms ms-MY th vi "
    "ja-JP ko-KR zh-CN zh-TW zh-HK ca"
).split()
LIMITS = {"title": 30, "short_description": 80, "full_description": 4000}
BRAND = "Skat Trainer"
URLS = (
    "https://jackwallner.github.io/skat/android-privacy.html",
    "https://jackwallner.github.io/skat/android-terms.html",
)
# The word for "German" each non-German listing must use when it says the app is in German.
GERMAN = {
    "en-US": "German", "en-GB": "German", "en-AU": "German", "en-CA": "German", "en-IN": "German",
    "fr-FR": "allemand", "fr-CA": "allemand", "es-ES": "alemán", "es-419": "alemán", "es-US": "alemán",
    "pt-BR": "alemão", "pt-PT": "alemão", "it-IT": "tedesco", "nl-NL": "Duits", "sv-SE": "tyska",
    "no-NO": "tysk", "da-DK": "tysk", "fi-FI": "saksaksi", "pl-PL": "niemiecku", "cs-CZ": "němčině",
    "sk": "nemčine", "sl": "nemščini", "hr": "njemačkom", "hu-HU": "németül", "ro": "germană",
    "el-GR": "γερμανικά", "tr-TR": "Almanca", "ru-RU": "немецком", "uk": "німецькою", "ar": "الألمانية",
    "iw-IL": "בגרמנית", "hi-IN": "जर्मन", "bn-BD": "জার্মান", "mr-IN": "जर्मन", "ta-IN": "ஜெர்மன்",
    "te-IN": "జర్మన్", "kn-IN": "ಜರ್ಮನ್", "ml-IN": "ജർമൻ", "id": "Jerman", "ms": "Jerman",
    "ms-MY": "Jerman", "th": "เยอรมัน", "vi": "tiếng Đức", "ja-JP": "ドイツ語", "ko-KR": "독일어",
    "zh-CN": "德语", "zh-TW": "德語", "zh-HK": "德語", "ca": "alemany",
}
ANY = re.compile(
    r"—|\b(apple|iphone|ipad|app store)\b|[$€£¥₹]|\b(usd|eur|gbp)\b|\d\s?(dollars?|euros?)\b"
    r"|\b(cure[sd]?|diagnos\w*|therap\w+|heals?)\b|\btreat(s|ment)?\b",
    re.I,
)
TITLE_BAD = re.compile(
    r"\b(free|best|new|gratis|kostenlos|gratuit|gratuito|beste|meilleur|mejor|melhor|migliore|nieuw|neu)\b|#\s?1",
    re.I,
)

def read(loc: str, name: str) -> str:
    return (ROOT / loc / f"{name}.txt").read_text(encoding="utf-8")

def check(loc: str) -> list[str]:
    errs: list[str] = []
    if not (ROOT / loc).is_dir():
        return [f"{loc}: missing folder"]
    text = {}
    for name, limit in LIMITS.items():
        try:
            text[name] = read(loc, name)
        except FileNotFoundError:
            errs.append(f"{loc}: missing {name}.txt")
            continue
        n = len(text[name])
        if n == 0 or n > limit:
            errs.append(f"{loc}: {name} is {n} chars (limit {limit})")
        if text[name] != text[name].strip() and name != "full_description":
            errs.append(f"{loc}: {name} has stray whitespace")
        if m := ANY.search(text[name]):
            errs.append(f"{loc}: {name} contains banned text {m.group(0)!r}")
    if "title" in text:
        if BRAND not in text["title"]:
            errs.append(f"{loc}: title lacks the brand {BRAND!r}")
        if m := TITLE_BAD.search(text["title"]):
            errs.append(f"{loc}: title contains {m.group(0)!r}")
    full = text.get("full_description", "")
    for u in URLS:
        if u not in full:
            errs.append(f"{loc}: full_description lacks {u}")
    if loc != "de-DE" and GERMAN[loc] not in full:
        errs.append(f"{loc}: full_description does not say the app is in German ({GERMAN[loc]!r})")
    return errs

def main() -> int:
    errs: list[str] = []
    extra = sorted(p.name for p in ROOT.iterdir() if p.is_dir() and p.name not in LOCALES)
    if extra:
        errs.append(f"unexpected locale folders: {extra}")
    titles: dict[str, str] = {}
    for loc in LOCALES:
        errs += check(loc)
        if (ROOT / loc / "title.txt").exists():
            titles[loc] = read(loc, "title")
    if len(LOCALES) != 50 or len(set(LOCALES)) != 50:
        errs.append("locale list is not 50 unique codes")
    for e in errs:
        print("FAIL", e)
    print(f"{len(LOCALES)} locales checked, {len(errs)} problems")
    return 1 if errs else 0

if __name__ == "__main__":
    sys.exit(main())
