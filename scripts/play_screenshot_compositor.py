#!/usr/bin/env python3
"""Composite raw Android captures into Google Play screenshots and the feature graphic.

Same frame and copy as the App Store set (scripts/appstore_screenshot_compositor.py),
laid out for Play: 1080x1920 portrait screenshots (Play rejects anything
longer than 2:1, and the raw 1080x2400 emulator captures are 2.22:1), plus the
1024x500 feature graphic. Reads android/play-assets/raw/ and writes
android/play-assets/screenshots/ and android/play-assets/feature-graphic.png.

Usage: python3 scripts/play_screenshot_compositor.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

import appstore_screenshot_compositor as ios

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "android" / "play-assets" / "raw"
OUT = ROOT / "android" / "play-assets" / "screenshots"
FEATURE = ROOT / "android" / "play-assets" / "feature-graphic.png"
ICON = ROOT / "android" / "play-assets" / "icon-512.png"

W, H = 1080, 1920
TOP = 84
EYEBROW = 26
HEADLINE = 74
LINE = 88
RULE_Y = TOP + 60 + 2 * LINE + 18
SHOT_TOP = RULE_Y + 44
SHOT_H = H - SHOT_TOP - 48
SHOT_W = round(SHOT_H * 1080 / 2400)
CORNER = 56


def background(accent: tuple, size: tuple) -> Image.Image:
    width, height = size
    img = Image.new("RGB", size, ios.CREAM)
    draw = ImageDraw.Draw(img)
    for y in range(height):
        t = y / height
        draw.line([(0, y), (width, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(ios.CREAM, ios.CREAM_DEEP)))
    glow = Image.new("RGBA", (1400, 1400), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([(0, 0), (1400, 1400)], fill=(*accent, 22))
    glow = glow.filter(ImageFilter.GaussianBlur(150))
    img.paste(glow, (width // 2 - 700, -560), glow)
    mark = Image.new("RGBA", (520, 560), (0, 0, 0, 0))
    ImageDraw.Draw(mark).text((0, -30), ios.WATERMARK_GLYPH, font=ios.cjk_font(480), fill=(*accent, 14))
    mark = mark.rotate(-8, expand=True, resample=Image.BICUBIC)
    img.paste(mark, (width - mark.width + 70, height - mark.height + 50), mark)
    return img


def render(shot: ios.Shot) -> Path:
    canvas = background(shot.accent, (W, H))
    draw = ImageDraw.Draw(canvas, "RGBA")
    eyebrow_font = ios.sans(EYEBROW, "Heavy")
    spaced = " ".join(shot.eyebrow)
    eb_w = draw.textlength(spaced, font=eyebrow_font)
    eb_x = (W - eb_w) / 2
    for dot_x in (eb_x - 20, eb_x + eb_w + 20):
        draw.ellipse([(dot_x - 4, TOP + 10), (dot_x + 4, TOP + 18)], fill=(*shot.accent, 200))
    draw.text((eb_x, TOP), spaced, font=eyebrow_font, fill=(*shot.accent, 235))

    font = ios.serif(HEADLINE, "Bold")
    lines = ios.wrap_headline(shot.headline, font, W - 180, draw)
    top = TOP + 60 + (2 - len(lines)) * LINE / 2
    for i, line in enumerate(lines):
        draw.text(((W - draw.textlength(line, font=font)) / 2, top + i * LINE), line, font=font, fill=ios.INK)
    draw.rounded_rectangle([(W / 2 - 44, RULE_Y), (W / 2 + 44, RULE_Y + 5)], radius=3, fill=shot.accent)

    raw = Image.open(RAW / shot.raw).convert("RGB")
    if raw.size != (1080, 2400):
        raise ValueError(f"{shot.raw} is {raw.size}, expected 1080x2400")
    scaled = raw.resize((SHOT_W, SHOT_H), Image.LANCZOS)
    left = (W - SHOT_W) // 2
    shadow = Image.new("RGBA", (SHOT_W + 100, SHOT_H + 100), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([(50, 62), (50 + SHOT_W, 62 + SHOT_H)], radius=CORNER, fill=(20, 16, 12, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas.paste(shadow, (left - 50, SHOT_TOP - 50), shadow)
    canvas.paste(scaled, (left, SHOT_TOP), ios.rounded_mask((SHOT_W, SHOT_H), CORNER))
    edge = ImageDraw.Draw(canvas, "RGBA")
    edge.rounded_rectangle([(left, SHOT_TOP), (left + SHOT_W, SHOT_TOP + SHOT_H)], radius=CORNER, outline=(*shot.accent, 130), width=3)

    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / shot.out
    canvas.save(path, "PNG")
    return path


def feature_graphic() -> Path:
    canvas = background(ios.JADE, (1024, 500))
    draw = ImageDraw.Draw(canvas, "RGBA")
    icon = Image.open(ICON).convert("RGB").resize((260, 260), Image.LANCZOS)
    canvas.paste(icon, (70, 120), ios.rounded_mask((260, 260), 58))
    title = ios.serif(64, "Bold")
    draw.text((380, 150), "Skat Trainer", font=title, fill=ios.INK)
    draw.rounded_rectangle([(384, 262), (464, 267)], radius=3, fill=ios.JADE)
    tagline = ios.sans(34, "Semibold")
    draw.text((382, 290), "Reizen, drücken, stechen", font=tagline, fill=ios.INK_SECONDARY)
    draw.text((382, 334), "in kurzen Übungsrunden", font=tagline, fill=ios.INK_SECONDARY)
    canvas.save(FEATURE, "PNG")
    return FEATURE


def main() -> None:
    for shot in ios.SHOTS:
        path = render(shot)
        print(f"wrote {path.relative_to(ROOT)} {Image.open(path).size}")
    path = feature_graphic()
    print(f"wrote {path.relative_to(ROOT)} {Image.open(path).size}")


if __name__ == "__main__":
    main()
