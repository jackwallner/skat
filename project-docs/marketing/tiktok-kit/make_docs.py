#!/usr/bin/env python3
"""Write checklist.html from the kit schedule, print both guides to PDF and make the avatar.

    python3 make_docs.py [--start 2026-11-10] [--out <dir>]

--start is Day 01; the 7 warmup days come before it.
"""
from __future__ import annotations

import argparse
import datetime as dt
import pathlib
import subprocess

from PIL import Image

import build_kit as K
import posts as P

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
SLOTS = ["7:00, account A", "12:00, account B", "19:00, account A"]


def fmt_date(d: dt.date) -> str:
    return f"{d:%a %b} {d.day}"


def checklist(start: dt.date) -> str:
    warm = []
    for i in range(7):
        d = start - dt.timedelta(days=7 - i)
        task = "Scroll 10 min on A and B, twice"
        if i >= 4:
            task += " + one non-promo post on each"
        if i == 6:
            task += ". Check: For You is mostly Skat"
        warm.append(f'<tr><td class="cb"></td><td><b>W{i + 1}</b></td><td>{fmt_date(d)}</td>'
                    f'<td colspan="3">{task}</td></tr>')
    sched = K.schedule()
    days = []
    for day in range(14):
        cells = "".join(f'<td>{p["id"]} <span>{P.FORMATS[p["fmt"]]}</span></td>' for p in sched[day * 3:day * 3 + 3])
        d = start + dt.timedelta(days=day)
        days.append(f'<tr><td class="cb"></td><td><b>Day {day + 1:02d}</b></td><td>{fmt_date(d)}</td>{cells}</tr>')
    head = "".join(f"<th>{s}</th>" for s in SLOTS)
    tpl = (K.HERE / "checklist.template.html").read_text()
    return (tpl.replace("{{WARMUP}}", "".join(warm)).replace("{{HEAD}}", head)
            .replace("{{DAYS}}", "".join(days)))


def pdf(html: pathlib.Path, out: pathlib.Path) -> None:
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                    f"--print-to-pdf={out}", html.as_uri()], check=True, capture_output=True)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--start", default="2026-11-10")
    ap.add_argument("--out", default=str(K.ICLOUD))
    args = ap.parse_args()
    out = pathlib.Path(args.out)
    (K.HERE / "checklist.html").write_text(checklist(dt.date.fromisoformat(args.start)))
    pdf(K.HERE / "guide.html", out / "Posting guide.pdf")
    pdf(K.HERE / "checklist.html", out / "Daily checklist.pdf")
    Image.open(K.ICON).convert("RGB").resize((720, 720), Image.LANCZOS).save(out / "skattipps-avatar.png")
    print(f"wrote guide, checklist and avatar to {out}")


if __name__ == "__main__":
    main()
