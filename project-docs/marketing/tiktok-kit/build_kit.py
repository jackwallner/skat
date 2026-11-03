#!/usr/bin/env python3
"""Render the Skat TikTok slideshow kit into iCloud Drive.

    python3 build_kit.py [--out <dir>]

Port of the Mahj kit generator (~/mahj/project-docs/marketing/tiktok-kit).
Slides are 1080x1920 JPEGs. Backgrounds are drawn here (card-table felt); every
card and screen is cut from real Skat Trainer 1.2.3 captures, so nothing on a
slide is AI art. All content stays inside the TikTok safe area
(SAFE below): the top bar, the right icon rail and the bottom caption block
cover everything outside it.
"""
from __future__ import annotations

import argparse
import csv
import functools
import pathlib
import random
import shutil

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from scipy import ndimage

import posts as P

HERE = pathlib.Path(__file__).resolve().parent
CAPS = pathlib.Path.home() / "ios/appstore-screenshots/captures/skat"
ICON = HERE.parents[2] / "SkatTrainer/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
ICLOUD = pathlib.Path.home() / "Library/Mobile Documents/com~apple~CloudDocs/Skat TikTok Kit"
W, H = 1080, 1920
SAFE = (60, 150, 950, 1500)  # left, top, right, bottom
CX = (SAFE[0] + SAFE[2]) // 2
FONT = "/System/Library/Fonts/SFNS.ttf"
SERIF = "/System/Library/Fonts/NewYork.ttf"
CREAM, INK, SAGE, MUTED = (246, 242, 233), (40, 48, 38), (63, 107, 70), (93, 102, 86)
# Card-table felt: green, bordeaux, navy, teal, plum.
FELTS = [(38, 104, 70), (118, 38, 50), (34, 56, 98), (24, 96, 96), (84, 46, 92)]

R = "refresh-20260916/"
SHOTS = {
    "quick": "01_quick_session.png", "quick_answered": R + "05-quick-answered-current.png",
    "struktur": "02_struktur.png", "struktur_answered": R + "03-structure-answered-current.png",
    "stich": "03_stich.png", "stich_answered": R + "02-stich-answered-current.png",
    "druecken": "04_druecken.png", "druecken_answered": R + "01-discard-answered-current.png",
    "home": "05_home.png", "karten": "06_karten.png",
    "meister_answered": R + "07-quick-second-answered-current.png",
    "null_answered": R + "08-quick-third-answered-current.png", "spielarten": R + "12-spielarten-room-current.png",
}
# Card crops in raw 1206x2622 capture pixels: (file, left, top, right, bottom).
RACKS = {
    "buben": ("01_quick_session.png", 270, 1195, 930, 1445),
    "struktur": ("02_struktur.png", 200, 1065, 1000, 1295),
    "stich": ("03_stich.png", 330, 1260, 870, 1510),
    "blatt": ("04_druecken.png", 30, 1245, 1176, 1715),
    "karo": (R + "07-quick-second-answered-current.png", 210, 925, 1000, 1165),
}
TILE_SOURCES = ["blatt", "struktur", "buben"]


def font(size: int, weight: str = "Bold", serif: bool = False) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(SERIF if serif else FONT, size)
    try:
        f.set_variation_by_name(weight)
    except Exception:  # noqa: BLE001
        pass
    return f


def wrap(draw: ImageDraw.ImageDraw, text: str, f: ImageFont.FreeTypeFont, width: int) -> list[str]:
    lines: list[str] = []
    for para in text.split("\n"):
        cur = ""
        for word in para.split():
            trial = f"{cur} {word}".strip()
            if draw.textlength(trial, font=f) <= width:
                cur = trial
            else:
                lines.append(cur)
                cur = word
        lines.append(cur)
    return lines


def rounded(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, img.width - 1, img.height - 1), radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def shadow(base: Image.Image, img: Image.Image, xy: tuple[int, int], blur: int = 18,
           alpha: int = 80, drop: int = 10) -> None:
    """Paste img with a soft shadow shaped like its own alpha."""
    pad = blur * 3
    sh = Image.new("RGBA", (img.width + pad * 2, img.height + pad * 2), (0, 0, 0, 0))
    a = img.getchannel("A").point(lambda v: v * alpha // 255)
    sh.paste((0, 0, 0, 255), (pad, pad), a)
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(sh, (xy[0] - pad, xy[1] - pad + drop))
    base.alpha_composite(img, xy)


def cloth(seed: int) -> Image.Image:
    """Card-table felt with a soft fibre texture, seeded per post."""
    rng = np.random.default_rng(seed)
    color = np.array(FELTS[seed % len(FELTS)], dtype=float)
    fibre = ndimage.gaussian_filter(rng.normal(0, 1, (H, W)), 1.2) * 9
    blotch = ndimage.gaussian_filter(rng.normal(0, 1, (H // 8, W // 8)), 6)
    blotch = np.kron(blotch / (np.abs(blotch).max() + 1e-6), np.ones((8, 8)))[:H, :W] * 10
    img = color + (fibre + blotch)[..., None]
    yy, xx = np.mgrid[0:H, 0:W]
    vignette = 1 - 0.22 * (((xx - W / 2) / W) ** 2 + ((yy - H / 2) / H) ** 2) * 4
    img *= vignette[..., None]
    return Image.fromarray(np.clip(img, 0, 255).astype("uint8")).convert("RGBA")


@functools.cache
def rack_tiles(key: str) -> tuple[Image.Image, ...]:
    """Cut each tile out of a real rack capture, sorted left to right, top to bottom."""
    name, *box = RACKS[key]
    im = Image.open(CAPS / name).convert("RGB").crop(tuple(box))
    a = np.asarray(im).astype(int)
    bg = np.median(np.concatenate([a[0], a[-1]]), axis=0)
    mask = ndimage.binary_fill_holes(ndimage.binary_closing(np.abs(a - bg).sum(2) > 18, iterations=3))
    lab, _ = ndimage.label(mask)
    boxes = [(s[1].start, s[0].start, s[1].stop, s[0].stop) for s in ndimage.find_objects(lab)]
    boxes = [b for b in boxes if b[2] - b[0] > 60 and b[3] - b[1] > 80]
    unit = float(np.median([b[2] - b[0] for b in boxes]))
    tiles = []
    for l, t, r, b in sorted(boxes, key=lambda b: (b[1] // 100, b[0])):
        n = max(1, round((r - l) / unit))  # touching tiles come out as one box
        step = (r - l) / n
        for i in range(n):
            tile = im.crop((int(l + i * step), t, int(l + (i + 1) * step), b - 6))
            tiles.append(rounded(tile, 18))
    return tuple(tiles)


def text_boxes(im: Image.Image, lines: list[str], f, center_y: int, pad: int = 24) -> int:
    """TikTok's native 'classic' caption look: dark text on white rounded boxes."""
    d = ImageDraw.Draw(im)
    lh = f.size + 2 * 12
    y = center_y - len(lines) * lh // 2
    for line in lines:
        w = d.textlength(line, font=f)
        x = CX - w / 2
        d.rounded_rectangle((x - pad, y, x + w + pad, y + lh + 2), 18, fill=(255, 255, 255))
        d.text((x, y + 6), line, font=f, fill=(22, 22, 22))
        y += lh
    return y


def hook_slide(post: dict, seed: int) -> Image.Image:
    im = cloth(seed)
    rng = random.Random(seed)
    key = post.get("rack") if post.get("rack") in TILE_SOURCES else TILE_SOURCES[seed % len(TILE_SOURCES)]
    tiles = list(rack_tiles(key))
    rng.shuffle(tiles)
    scale, slots = 1.45, []
    for row in range(2):
        for col in range(4 - row):
            x = SAFE[0] + 40 + col * 215 + (107 if row else 0) + rng.randint(-12, 12)
            y = 950 + row * 235 + rng.randint(-16, 16)
            slots.append((x, y))
    for (x, y), tile in zip(slots, tiles):
        t = tile.resize((int(tile.width * scale), int(tile.height * scale)), Image.LANCZOS)
        t = t.rotate(rng.uniform(-8, 8), resample=Image.BICUBIC, expand=True)
        shadow(im, t, (x, y), blur=10, alpha=110, drop=8)
    f = font(76)
    d = ImageDraw.Draw(im)
    lines = wrap(d, post["hook"], f, 800)
    y = text_boxes(im, lines, f, 540)
    sf = font(38, "Semibold")
    label = "wischen \u2192"
    lw = d.textlength(label, font=sf)
    d.rounded_rectangle((CX - lw / 2 - 26, y + 30, CX + lw / 2 + 26, y + 30 + 64), 32, fill=(22, 22, 22))
    d.text((CX - lw / 2, y + 40), label, font=sf, fill=(255, 255, 255))
    return im.convert("RGB")


def quiz_slide(post: dict, seed: int) -> Image.Image:
    """Quiz hook: the real rack and lettered options on slide 1, so answering takes one comment.

    Mahj post 1 (Oct 18) held viewers 6.4s and only 15% reached the last slide,
    so the puzzle can't wait for slide 2.
    """
    im = cloth(seed)
    d = ImageDraw.Draw(im)
    f = font(72)
    y = text_boxes(im, wrap(d, post["quiz_q"], f, 820), f, SAFE[1] + 260)
    inner = SAFE[2] - SAFE[0] - 60
    name, *box = RACKS[post["rack"]]
    rack = Image.open(CAPS / name).convert("RGB").crop(tuple(box))
    rack = rack.resize((inner, int(rack.height * inner / rack.width)), Image.LANCZOS)
    card = Image.new("RGBA", (SAFE[2] - SAFE[0], rack.height + 60), (0, 0, 0, 0))
    ImageDraw.Draw(card).rounded_rectangle((0, 0, card.width - 1, card.height - 1), 40, fill=(*CREAM, 248))
    top = y + 50
    shadow(im, card, (SAFE[0], top), blur=22, alpha=60, drop=12)
    im.alpha_composite(rounded(rack, 24), (SAFE[0] + 30, top + 30))
    y = top + card.height + 40
    lf, of = font(50), font(46, "Semibold")
    cw, ch, gap = (SAFE[2] - SAFE[0] - 30) // 2, 112, 30
    for i, opt in enumerate(post["options"]):
        x0 = SAFE[0] + (i % 2) * (cw + gap)
        y0 = y + (i // 2) * (ch + 24)
        chip = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        ImageDraw.Draw(chip).rounded_rectangle((0, 0, cw - 1, ch - 1), 30, fill=(255, 255, 255, 250))
        shadow(im, chip, (x0, y0), blur=12, alpha=50, drop=6)
        letter = "ABCD"[i]
        d.text((x0 + 30, y0 + ch / 2), letter, font=lf, fill=SAGE, anchor="lm")
        size = 46
        while d.textlength(opt, font=of) > cw - 120:
            size -= 2
            of = font(size, "Semibold")
        d.text((x0 + 90, y0 + ch / 2), opt, font=of, fill=INK, anchor="lm")
        of = font(46, "Semibold")
    y += 2 * ch + 24 + 44
    sf = font(40, "Semibold")
    label = "A, B, C oder D? Lösung auf Folie 3 →"
    lw = d.textlength(label, font=sf)
    d.rounded_rectangle((CX - lw / 2 - 30, y, CX + lw / 2 + 30, y + 72), 36, fill=(22, 22, 22))
    d.text((CX, y + 36), label, font=sf, fill=(255, 255, 255), anchor="mm")
    return im.convert("RGB")


def card_slide(seed: int, text: str, rack: str | None) -> Image.Image:
    im = cloth(seed)
    d = ImageDraw.Draw(im)
    f = font(62, "Semibold")
    inner = SAFE[2] - SAFE[0] - 110
    lines = wrap(d, text, f, inner)
    lh = f.size + 20
    rack_img = None
    if rack:
        name, *box = RACKS[rack]
        rack_img = Image.open(CAPS / name).convert("RGB").crop(tuple(box))
        rack_img = rack_img.resize((inner + 30, int(rack_img.height * (inner + 30) / rack_img.width)),
                                   Image.LANCZOS)
    card_h = len(lines) * lh + 120 + ((rack_img.height + 44) if rack_img else 0)
    top = max(SAFE[1] + 40, (SAFE[1] + SAFE[3]) // 2 - card_h // 2 - 40)
    card = Image.new("RGBA", (SAFE[2] - SAFE[0], card_h), (0, 0, 0, 0))
    ImageDraw.Draw(card).rounded_rectangle((0, 0, card.width - 1, card_h - 1), 40, fill=(*CREAM, 248))
    shadow(im, card, (SAFE[0], top), blur=22, alpha=60, drop=12)
    y = top + 60
    if rack_img:
        im.alpha_composite(rounded(rack_img, 24), (SAFE[0] + 40, y))
        y += rack_img.height + 44
    for line in lines:
        d.text((SAFE[0] + 55, y), line, font=f, fill=INK)
        y += lh
    return im.convert("RGB")


def app_slide(text: str, shots: tuple[str, str]) -> Image.Image:
    im = Image.new("RGBA", (W, H), (*CREAM, 255))
    d = ImageDraw.Draw(im)
    f = font(54, "Semibold")
    lines = wrap(d, text, f, SAFE[2] - SAFE[0] - 20)
    y = SAFE[1] + 40
    for line in lines:
        d.text((CX - d.textlength(line, font=f) / 2, y), line, font=f, fill=INK)
        y += f.size + 14
    badge_top = SAFE[3] - 150
    sw, gap = 425, 36
    shot_top = y + 50
    shot_h = badge_top - 50 - shot_top
    for i, key in enumerate(shots):
        s = Image.open(CAPS / SHOTS[key]).convert("RGB")
        s = s.resize((sw, int(s.height * sw / s.width)), Image.LANCZOS)
        s = s.crop((0, 0, sw, min(s.height, shot_h)))
        shadow(im, rounded(s, 36), (CX - sw - gap // 2 + i * (sw + gap), shot_top), blur=22, alpha=70)
    icon = rounded(Image.open(ICON).convert("RGB").resize((120, 120), Image.LANCZOS), 27)
    nf, sf = font(46), font(30, "Regular")
    name, sub = "Skat Trainer", "Kostenlos starten im App Store · von mir gebaut"
    tw = max(d.textlength(name, font=nf), d.textlength(sub, font=sf))
    x = int(CX - (120 + 26 + tw) / 2)
    shadow(im, icon, (x, badge_top), blur=10, alpha=60, drop=5)
    d.text((x + 146, badge_top + 14), name, font=nf, fill=INK)
    d.text((x + 146, badge_top + 72), sub, font=sf, fill=MUTED)
    return im.convert("RGB")


def schedule() -> list[dict]:
    by_fmt = {k: [p for p in P.POSTS if p["fmt"] == k] for k in P.FORMATS}
    return [by_fmt[k][r] for r in range(6) for k in P.FORMATS]


def cta_variant(post: dict) -> str:
    """Alternate the two CTAs inside each format: 3 posts each, so formats compare fairly."""
    same = [p["id"] for p in P.POSTS if p["fmt"] == post["fmt"]]
    return "comment" if same.index(post["id"]) % 2 == 0 else "name"


def caption_txt(post: dict, cta: str, value_only: bool = False) -> str:
    tags = " ".join(post["tags"])
    if value_only:
        return (
            f"VALUE-ONLY VERSION: no app slide, no app mention, so no disclosure toggle.\n\n"
            f"TITLE (photo mode title field):\n{post.get('quiz_q', post['hook'])}\n\n"
            f"CAPTION (paste as is):\n{post['caption']} {post.get('question', P.QUESTIONS[post['fmt']])}\n\n"
            f"{tags}\n\n"
            f"If someone asks how to practice, reply: Ich habe dafür eine App gebaut, sie heißt Skat Trainer im App Store.\n"
            f"SOUND (Commercial Music Library): {P.SOUNDS[post['sound']]}\n"
        )
    return (
        f"TITLE (photo mode title field):\n{post['hook']}\n\n"
        f"CAPTION (paste as is):\n{post['caption']} {post.get('question', P.QUESTIONS[post['fmt']])}\n\n"
        f"{P.CTAS[cta]}\n\n{tags}\n\n"
        f"PINNED COMMENT (post it yourself, then pin):\n{P.PINNED}\n\n"
        f"REPLY to every \"app\" or \"name?\" comment:\n{P.REPLY}\n\n"
        f"BEFORE POSTING: More options > Disclose post content > Your brand.\n"
        f"SOUND (Commercial Music Library): {P.SOUNDS[post['sound']]}\n\n"
        f"FORMAT: {post['fmt']} {P.FORMATS[post['fmt']]}   CTA: {cta}\n"
    )


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=str(ICLOUD))
    ap.add_argument("--only", help="render just these post ids, comma separated (for QA)")
    ap.add_argument("--value-only", action="store_true",
                    help="with --only: drop the app slide and the CTA, into a '(value only)' folder")
    args = ap.parse_args()
    out = pathlib.Path(args.out)
    only = set(args.only.split(",")) if args.only else None
    if args.value_only and not only:
        ap.error("--value-only needs --only")
    slots = ["1 Morning", "2 Midday", "3 Evening"]
    if out.exists() and not only:
        for child in out.glob("Day *"):
            shutil.rmtree(child)
    rows = []
    for i, post in enumerate(schedule()):
        day, slot = i // 3 + 1, slots[i % 3]
        cta = cta_variant(post)
        rows.append({"day": day, "slot": slot, "post": post["id"],
                     "format": f"{post['fmt']} {P.FORMATS[post['fmt']]}", "cta": cta,
                     "hook": post["hook"], "account": "A" if (i % 3) != 1 else "B",
                     "views_24h": "", "views_72h": "", "saves": "", "app_comments": "",
                     "profile_views": "", "trials_next_72h": "", "call": ""})
        if only and post["id"] not in only:
            continue
        suffix = " (value only)" if args.value_only else ""
        folder = out / f"Day {day:02d}" / f"{slot} - {post['id']} {P.FORMATS[post['fmt']]}{suffix}"
        folder.mkdir(parents=True, exist_ok=True)
        rack = post.get("rack")
        slides = [
            quiz_slide(post, i) if post.get("options") else hook_slide(post, i),
            card_slide(i, post["s2"], rack if post["fmt"] == "C" else None),
            card_slide(i, post["s3"], rack if post["fmt"] != "C" else None),
            app_slide(post["s4"], post["shots"]),
            card_slide(i, post["s5"], None),
        ]
        if args.value_only:
            del slides[3]
            for old in folder.glob("*.jpg"):
                old.unlink()
        for n, s in enumerate(slides, 1):
            s.save(folder / f"{n}.jpg", quality=92)
        (folder / "caption.txt").write_text(caption_txt(post, cta, args.value_only))
    if not only:
        with open(out / "Tracker.csv", "w", newline="") as fh:
            w = csv.DictWriter(fh, fieldnames=list(rows[0]))
            w.writeheader()
            w.writerows(rows)
    print(f"wrote {len(only) if only else len(rows)} posts to {out}")


if __name__ == "__main__":
    main()
