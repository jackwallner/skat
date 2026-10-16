#!/usr/bin/env python3
"""Android launcher icon from the iOS app icon (no redrawing, so they never drift).

The iOS icon is already full bleed: three German-suited cards on deep blue
cloth. The whole square becomes the adaptive foreground at 72dp of the 108dp
canvas, so its edges line up with the visible viewport and the outer cards
stay inside the circular mask. The background layer is the cloth's average
edge colour. Also writes the legacy square and round icons and the 512px Play
icon.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "SkatTrainer/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
RES = ROOT / "android/app/src/main/res"
DENSITIES = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
ART_DP = 72


def edge_colour(icon: Image.Image) -> tuple[int, int, int]:
    """The mean colour of a 24px frame around the art."""
    small = icon.resize((256, 256), Image.BOX)
    pixels = [small.getpixel((x, y)) for x in range(256) for y in range(256) if min(x, y, 255 - x, 255 - y) < 6]
    return tuple(round(sum(p[i] for p in pixels) / len(pixels)) for i in range(3))


def foreground(art: Image.Image, px: int) -> Image.Image:
    canvas = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    side = round(px * ART_DP / 108)
    canvas.paste(art.resize((side, side), Image.LANCZOS).convert("RGBA"), ((px - side) // 2, (px - side) // 2))
    return canvas


def round_icon(art: Image.Image, px: int) -> Image.Image:
    square = art.resize((px, px), Image.LANCZOS).convert("RGBA")
    scale = 4
    mask = Image.new("L", (px * scale, px * scale), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, px * scale - 1, px * scale - 1), fill=255)
    square.putalpha(mask.resize((px, px), Image.LANCZOS))
    return square


def main() -> None:
    icon = Image.open(SOURCE).convert("RGB")
    art = icon
    hex_felt = "#{:02X}{:02X}{:02X}".format(*edge_colour(icon))
    for name, px in DENSITIES.items():
        folder = RES / f"mipmap-{name}"
        folder.mkdir(parents=True, exist_ok=True)
        foreground(art, px).save(folder / "ic_launcher_foreground.png")
    for name, px in LEGACY.items():
        folder = RES / f"mipmap-{name}"
        art.resize((px, px), Image.LANCZOS).save(folder / "ic_launcher.png")
        round_icon(art, px).save(folder / "ic_launcher_round.png")
    xml = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
"""
    anydpi = RES / "mipmap-anydpi-v26"
    (anydpi / "ic_launcher.xml").write_text(xml)
    (anydpi / "ic_launcher_round.xml").write_text(xml)
    colors = RES / "values/colors.xml"
    text = colors.read_text()
    start = text.index('<color name="ic_launcher_background">')
    end = text.index("</color>", start) + len("</color>")
    colors.write_text(text[:start] + f'<color name="ic_launcher_background">{hex_felt}</color>' + text[end:])
    assets = ROOT / "android/play-assets"
    assets.mkdir(parents=True, exist_ok=True)
    art.resize((512, 512), Image.LANCZOS).save(assets / "icon-512.png")
    print(f"wrote adaptive icon layers (cloth {hex_felt}) and play-assets/icon-512.png")


if __name__ == "__main__":
    main()
