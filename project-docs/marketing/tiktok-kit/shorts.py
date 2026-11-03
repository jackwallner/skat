#!/usr/bin/env python3
"""Five German animated lesson shorts for Skat Trainer, on the Mahj shorts engine.

    python3 shorts.py [name ...] [--still t1,t2,...]    # default: render all into the iCloud kit

Reuses ~/ios/growth/animated-shorts-2026-10-27/render.py (watercolour pass, captions, score,
end card) and ~/ios/growth/tiktok-2026-10-29/kit.py (Lesson, pills, rings, motion). This
module's build_kit is imported first, so the engine draws Skat felt, cards and icon.

There is no narration: open German voices are either English-only (Kokoro) or fine-tuned
from a non-commercial dataset (Piper Thorsten from Lessac). Each line is shown as a caption
timed to reading speed, over the engine's own synthesized score.
"""
from __future__ import annotations

import functools
import json
import pathlib
import shutil
import subprocess
import sys
import wave

import numpy as np
from PIL import Image, ImageDraw

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import build_kit as K  # noqa: E402  (must load before render.py, which imports "build_kit")
import posts as P  # noqa: E402

GROWTH = pathlib.Path.home() / "ios/growth"
sys.path.insert(1, str(GROWTH / "animated-shorts-2026-10-27"))
sys.path.insert(1, str(GROWTH / "tiktok-2026-10-29"))
import render as R  # noqa: E402
import kit  # noqa: E402
from kit import AMBER, CREAM, GREEN, INK, OUT, RED, bell, lerp, seg  # noqa: E402

assert R.K is K, "render.py picked up the Mahj build_kit"
OUT_DIR = K.ICLOUD / "Animated shorts"
WPS = 2.3  # caption reading speed, words per second
GOLD = (232, 170, 60)

# ---------------------------------------------------------------- cards

NAMES = {
    "buben": ["Bc", "Bs", "Bh", "Bd"],
    "karo": ["7d", "8d", "9d", "10d", "Ad"],
    "blatt": ["7c", "Dc", "Ac", "8s", "Ks", "7h", "10h", "Bh", "Ah", "9d", "10d", "Ad"],
}


@functools.cache
def cards() -> dict[str, Image.Image]:
    out: dict[str, Image.Image] = {}
    for key, names in NAMES.items():
        for name, im in zip(names, K.rack_tiles(key)):
            out.setdefault(name, im)
    return out


@functools.cache
def card(code: str, width: int) -> Image.Image:
    src = cards()[code]
    h = int(width * src.height / src.width)
    im = src.resize((width, h), Image.LANCZOS)
    pad = 24
    out = Image.new("RGBA", (width + pad * 2, h + pad * 2), (0, 0, 0, 0))
    sh = Image.new("RGBA", out.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((pad, pad + 8, pad + width, pad + h + 8), int(width * 0.12),
                                         fill=(10, 20, 14, 110))
    from PIL import ImageFilter
    out.alpha_composite(sh.filter(ImageFilter.GaussianBlur(9)))
    out.alpha_composite(im, (pad, pad))
    return out


@functools.cache
def back(width: int) -> Image.Image:
    src = cards()["Bc"]
    h = int(width * src.height / src.width)
    im = Image.new("RGBA", (width + 48, h + 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((24, 24, 24 + width, 24 + h), int(width * 0.12), fill=(246, 242, 233), outline=(200, 190, 170),
                        width=3)
    d.rounded_rectangle((34, 34, 14 + width, 14 + h), int(width * 0.09), fill=(30, 96, 74))
    for k in range(-h, width, 22):
        d.line((34 + k, 34, 34 + k + h, 34 + h), fill=(52, 122, 96), width=4)
    d.rounded_rectangle((24, 24, 24 + width, 24 + h), int(width * 0.12), outline=(246, 242, 233), width=12)
    return im


def put(layer: Image.Image, code: str, x: float, y: float, width: int, angle: float = 0.0, alpha: float = 1.0,
        dim: float = 0.0) -> None:
    if alpha <= 0.01:
        return
    s = back(width) if code == "BACK" else card(code, width)
    if dim > 0:
        s = s.copy()
        rgb = Image.blend(s.convert("RGB"), Image.new("RGB", s.size, (120, 128, 118)), dim * 0.6)
        rgb.putalpha(s.getchannel("A"))
        s = rgb
    R.paste_center(layer, kit.fade(s, alpha), x, y, angle)


def ch(width: int) -> float:
    """Card height for a card width."""
    return width * 1.34


def row(n: int, cx: float, cy: float, width: int, gap: int = 18) -> list[tuple[float, float]]:
    return [(cx + (i - (n - 1) / 2) * (width + gap), cy) for i in range(n)]


def ring(layer, x, y, width, color, alpha):
    kit.ring(layer, x, y, width, color, alpha)


def deal(layer, codes, slots, width, t, t0, step=0.1, dims=None, alphas=None):
    for i, (code, (x, y)) in enumerate(zip(codes, slots)):
        dy, a = kit.land(seg(t, t0 + i * step, t0 + i * step + 0.45), 140)
        a *= alphas[i] if alphas else 1.0
        put(layer, code, x, y + dy, width, alpha=a, dim=dims[i] if dims else 0.0)


# ---------------------------------------------------------------- engine hooks

def narrate(lines: list[str], work: pathlib.Path):
    """Silent stand-in for the voice: each line lasts as long as it takes to read."""
    out = []
    for i, line in enumerate(lines):
        words = line.split()
        dur = max(2.4, len(words) / WPS + 0.6)
        weights = np.array([len(w) + 3 for w in words], float)
        starts = np.concatenate([[0.15], 0.15 + np.cumsum(weights)[:-1] / weights.sum() * (dur - 0.6)])
        path = work / f"vo{i}_44k.wav"
        with wave.open(str(path), "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(R.SR)
            wf.writeframes(np.zeros(int(dur * R.SR), np.int16).tobytes())
        out.append((path, dur, [(float(s), w) for s, w in zip(starts, words)]))
    return out


def end_overlay(t: float):
    p, q = OUT(seg(t, 0.15, 0.95)), OUT(seg(t, 0.45, 1.25))
    ic = R.icon(340).copy()
    ic.putalpha(ic.getchannel("A").point(lambda v: int(v * p)))
    label = Image.new("RGBA", (1000, 260), (0, 0, 0, 0))
    d = ImageDraw.Draw(label)
    d.text((500, 60), "Skat Trainer", font=K.font(92, "Semibold", serif=True), fill=R.INK + (int(255 * q),),
           anchor="mm")
    d.text((500, 170), "Kostenlos im App Store", font=K.font(46, "Medium"), fill=K.MUTED + (int(255 * q),),
           anchor="mm")
    return [(ic, (540 - ic.width // 2, int(560 + 40 * (1 - p)))), (label, (40, int(1000 + 24 * (1 - q))))]


def soundtrack_quiet_voice(short, scenes, total, path):
    """render.soundtrack normalises the voice by its peak; silence would divide 0 by ~0, which is fine,
    but there is nothing to duck, so the score plays a little louder."""
    rng = np.random.default_rng(5)
    sfx = np.zeros(int(total * R.SR) + R.SR)
    if short.sfx:
        short.sfx(scenes, sfx, rng)
    music = R.score(total, scenes[-1]["start"])[: len(sfx)]
    mix = 0.55 * music / (np.abs(music).max() + 1e-9) + sfx
    mix = mix[: int(total * R.SR)]
    mix = mix / (np.abs(mix).max() + 1e-9) * 0.9
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(R.SR)
        wf.writeframes((mix * 32767).astype(np.int16).tobytes())


R.narrate = narrate
R.scene6_overlay = end_overlay
R.soundtrack = soundtrack_quiet_voice


@functools.cache
def felt(seed: int):
    return kit.cloth_bg(seed)


def bgs(seed: int, n: int = 5):
    return [lambda: felt(seed)] * n


# ---------------------------------------------------------------- S1 Buben

S1_LINES = [
    "Die vier Buben, in 20 Sekunden.",
    "Im Farbspiel und im Grand sind alle vier Buben Trumpf.",
    "Ganz oben steht der Kreuz-Bube, dann Pik, Herz und Karo.",
    "Ein Bube zählt immer zum Trumpf, auch wenn seine Farbe angespielt wird.",
    "Nur im Null sind sie normale Karten, zwischen Zehn und Dame.",
]
SHUFFLED = ["Bh", "Bd", "Bc", "Bs"]
ORDER = ["Bc", "Bs", "Bh", "Bd"]


def s1_hook(t, dur, layer):
    for i, (code, (x, y)) in enumerate(zip(SHUFFLED, row(4, 540, 900, 200, 30))):
        dy, a = kit.land(seg(t, -0.4 + i * 0.12, 0.05 + i * 0.12), 160)
        put(layer, code, x, y + dy, 200, angle=(i - 1.5) * 4, alpha=a)


def s1_trump(t, dur, layer):
    t_tr = S1.at(1, "trumpf", 1.8)
    for i, (code, (x, y)) in enumerate(zip(SHUFFLED, row(4, 540, 860, 200, 30))):
        lift = -30 * OUT(seg(t, t_tr - 0.2 + i * 0.08, t_tr + 0.3 + i * 0.08))
        put(layer, code, x, y + lift, 200)
        ring(layer, x, y + lift, 200, GOLD, seg(t, t_tr + i * 0.08, t_tr + 0.4 + i * 0.08))
    kit.pill(layer, "Trumpf", 540, 1110, 56, GREEN, pop=seg(t, t_tr, t_tr + 0.6))


def s1_order(t, dur, layer):
    src = dict(zip(SHUFFLED, row(4, 540, 700, 170, 30)))
    dst = dict(zip(ORDER, row(4, 540, 1020, 200, 30)))
    cues = [S1.at(2, w, d) for w, d in (("kreuzbube", 0.8), ("pik", 2.0), ("herz", 2.4), ("karo", 3.0))]
    for k, code in enumerate(ORDER):
        p = seg(t, cues[k] - 0.3, cues[k] + 0.3)
        x, y = kit.fly(p, src[code], dst[code], arc=60)
        put(layer, code, x, y, int(lerp(170, 200, p)))
        kit.pill(layer, str(k + 1), dst[code][0], 1020 - ch(200) / 2 - 50, 44, AMBER, INK, pop=seg(t, cues[k], cues[k] + 0.5))


def s1_suit(t, dur, layer):
    t_in = 0.2
    deal(layer, ["Bh", "7h", "10h"], row(3, 540, 860, 210, 60), 210, t, t_in)
    t_tr = S1.at(3, "trumpf", 1.6)
    x, y = row(3, 540, 860, 210, 60)[0]
    ring(layer, x, y, 210, GOLD, seg(t, t_tr, t_tr + 0.4))
    kit.pill(layer, "Trumpf", x, 860 + ch(210) / 2 + 70, 46, GREEN, pop=seg(t, t_tr, t_tr + 0.5))
    t_h = S1.at(3, "farbe", 2.8)
    kit.pill(layer, "Herz", 540 + 135, 860 + ch(210) / 2 + 70, 46, RED, pop=seg(t, t_h, t_h + 0.5))


def s1_null(t, dur, layer):
    slots = row(6, 540, 860, 150, 14)
    codes = ["7d", "8d", "9d", "10d", "Bd", "Ad"]
    t_b = S1.at(4, "zwischen", 2.2)
    for i, code in enumerate(codes):
        if code == "Bd":
            p = seg(t, t_b - 0.3, t_b + 0.3)
            x, y = kit.fly(p, (540, 520), slots[i], arc=0)
            put(layer, code, x, y, 150, alpha=min(1, p * 3))
            ring(layer, *slots[i], 150, GOLD, seg(t, t_b + 0.3, t_b + 0.7))
        else:
            dy, a = kit.land(seg(t, 0.1 + i * 0.08, 0.5 + i * 0.08), 120)
            put(layer, code, slots[i][0], slots[i][1] + dy, 150, alpha=a)
    kit.pill(layer, "Null", 540, 1100, 56, INK, pop=seg(t, S1.at(4, "null", 0.6), S1.at(4, "null", 0.6) + 0.5))


S1 = kit.Lesson("skat-buben", S1_LINES, ("Die vier Buben,", "in 20 Sekunden"),
                [s1_hook, s1_trump, s1_order, s1_suit, s1_null], bgs(0))

# ---------------------------------------------------------------- S2 Augen

S2_LINES = [
    "Augen zählen beim Skat, in 25 Sekunden.",
    "Das Ass zählt 11, die Zehn 10.",
    "König 4, Dame 3, Bube 2.",
    "Die 9, die 8 und die 7 zählen nichts.",
    "Zusammen sind es 120 Augen. Mit 61 gewinnst du.",
]


def value_row(layer, t, codes, values, cues, width=210, cy=880, dims=None):
    slots = row(len(codes), 540, cy, width, 40)
    for i, (code, val) in enumerate(zip(codes, values)):
        dy, a = kit.land(seg(t, 0.1 + i * 0.1, 0.5 + i * 0.1), 140)
        dim = (dims or [0] * len(codes))[i] * seg(t, cues[i], cues[i] + 0.4)
        put(layer, code, slots[i][0], slots[i][1] + dy, width, alpha=a, dim=dim)
        color = RED if val == "0" else AMBER
        kit.pill(layer, val, slots[i][0], cy + ch(width) / 2 + 70, 52, color, INK if val != "0" else CREAM,
                 pop=seg(t, cues[i], cues[i] + 0.5))


def s2_hook(t, dur, layer):
    for i, (code, (x, y)) in enumerate(zip(["Ad", "10h", "Ks", "Dc", "Bh"], row(5, 540, 900, 170, 16))):
        dy, a = kit.land(seg(t, -0.4 + i * 0.1, 0.05 + i * 0.1), 160)
        put(layer, code, x, y + dy, 170, angle=(i - 2) * 4, alpha=a)


def s2_high(t, dur, layer):
    value_row(layer, t, ["Ad", "10h"], ["11", "10"], [S2.at(1, "11", 1.0), S2.at(1, "10", 2.0)], width=240)


def s2_mid(t, dur, layer):
    value_row(layer, t, ["Ks", "Dc", "Bh"], ["4", "3", "2"],
              [S2.at(2, "4", 0.5), S2.at(2, "3", 1.2), S2.at(2, "2", 1.9)])


def s2_zero(t, dur, layer):
    c = S2.at(3, "nichts", 2.4)
    value_row(layer, t, ["9d", "8s", "7c"], ["0", "0", "0"], [c, c + 0.12, c + 0.24], dims=[1, 1, 1])


def s2_total(t, dur, layer):
    t0, t1 = S2.at(4, "120", 1.0), S2.at(4, "61", 2.6)
    n = int(120 * OUT(seg(t, 0.2, t0 + 0.2)))
    kit.text(layer, str(n), 540, 760, 260, CREAM, alpha=seg(t, 0.0, 0.3), stroke=8)
    kit.text(layer, "Augen", 540, 930, 70, CREAM, alpha=seg(t, 0.2, 0.6), stroke=5)
    kit.pill(layer, "61 gewinnt", 540, 1110, 62, GREEN, pop=seg(t, t1, t1 + 0.6))


S2 = kit.Lesson("skat-augen", S2_LINES, ("Augen zählen,", "in 25 Sekunden"),
                [s2_hook, s2_high, s2_mid, s2_zero, s2_total], bgs(2))

# ---------------------------------------------------------------- S3 Reizen

S3_LINES = [
    "Woher kommt die 18 beim Skat?",
    "Karo hat den Grundwert 9.",
    "Mit 1 oder ohne 1 heißt: Spiel 2.",
    "2 mal 9 ergibt 18, der kleinste Reizwert.",
    "Danach kommen 20, 22, 23 und 24.",
]


def s3_hook(t, dur, layer):
    kit.text(layer, "18?", 540, 860, 300, AMBER, alpha=1.0, stroke=10)


def s3_base(t, dur, layer):
    deal(layer, ["7d", "10d", "Ad"], row(3, 540, 830, 200, 30), 200, t, 0.1)
    t9 = S3.at(1, "9", 1.6)
    kit.pill(layer, "Karo = 9", 540, 1100, 60, AMBER, INK, pop=seg(t, t9, t9 + 0.6))


def s3_spitzen(t, dur, layer):
    deal(layer, ["Bc"], [(540, 830)], 230, t, 0.1)
    t2 = S3.at(2, "2", 2.2)
    kit.pill(layer, "mit 1", 540, 830 - ch(230) / 2 - 70, 50, GREEN, pop=seg(t, S3.at(2, "mit", 0.2), S3.at(2, "mit", 0.2) + 0.5))
    kit.pill(layer, "Spiel 2", 540, 1110, 60, AMBER, INK, pop=seg(t, t2, t2 + 0.6))


def s3_math(t, dur, layer):
    t18 = S3.at(3, "18", 1.2)
    kit.text(layer, "2 × 9", 540, 760, 170, CREAM, alpha=seg(t, 0.1, 0.5), stroke=8)
    kit.text(layer, "= 18", 540, 950, 200, AMBER, alpha=seg(t, t18 - 0.2, t18 + 0.2), stroke=9)


def s3_ladder(t, dur, layer):
    vals = ["18", "20", "22", "23", "24"]
    cues = [0.0] + [S3.at(4, w, 0.8 + k * 0.5) for k, w in enumerate(("20", "22", "23", "24"))]
    for k, v in enumerate(vals):
        y = 1100 - k * 120
        kit.pill(layer, v, 540, y, 64, AMBER if k == 0 else CREAM, INK, pop=seg(t, cues[k], cues[k] + 0.5))


S3 = kit.Lesson("skat-18", S3_LINES, ("Woher kommt", "die 18?"),
                [s3_hook, s3_base, s3_spitzen, s3_math, s3_ladder], bgs(1))

# ---------------------------------------------------------------- S4 Drücken

S4_LINES = [
    "Welche zwei Karten drückst du?",
    "Du planst ein Herzspiel.",
    "Die Trümpfe und die Asse bleiben auf der Hand.",
    "Kreuz-7 und Pik-8 wandern in den Skat.",
    "Kleine Karten in Nebenfarben bringen keine Augen und fehlen dir kaum.",
]
HAND = NAMES["blatt"]
TRUMPS = {"Bh", "7h", "10h", "Ah"}
ACES = {"Ac", "Ad"}
DROP = ["7c", "8s"]
HW = 128


def hand_slots():
    return row(6, 540, 620, HW, 14) + row(6, 540, 620 + ch(HW) + 30, HW, 14)


def s4_hand(t, dur, layer, lesson_line=None, rings=(), gone=0.0):
    slots = hand_slots()
    for i, code in enumerate(HAND):
        if code in DROP and gone > 0:
            continue
        dy, a = kit.land(seg(t, -0.5 + i * 0.05, -0.1 + i * 0.05), 120)
        put(layer, code, slots[i][0], slots[i][1] + dy, HW, alpha=a)
    for codes, color, p in rings:
        for i, code in enumerate(HAND):
            if code in codes:
                ring(layer, *slots[i], HW, color, p)


def s4_hook(t, dur, layer):
    s4_hand(t, dur, layer)


def s4_trump(t, dur, layer):
    p = seg(t, S4.at(1, "herzspiel", 0.8), S4.at(1, "herzspiel", 0.8) + 0.4)
    s4_hand(5, dur, layer, rings=[(TRUMPS, GOLD, p)])
    kit.pill(layer, "Herz ist Trumpf", 540, 1080, 52, RED, pop=p)


def s4_keep(t, dur, layer):
    p = seg(t, S4.at(2, "asse", 1.4), S4.at(2, "asse", 1.4) + 0.4)
    s4_hand(5, dur, layer, rings=[(TRUMPS, GOLD, 1.0), (ACES, GREEN, p)])


def s4_drop(t, dur, layer):
    slots = hand_slots()
    s4_hand(5, dur, layer, rings=[(TRUMPS, GOLD, 1.0), (ACES, GREEN, 1.0)], gone=1.0)
    skat = [(470, 1090), (610, 1090)]
    for k in range(2):
        put(layer, "BACK", *skat[k], 120, angle=(k - 0.5) * 8, alpha=1 - seg(t, 1.2, 1.6))
    cues = [S4.at(3, "kreuz7", 0.5), S4.at(3, "pik8", 1.3)]
    for k, code in enumerate(DROP):
        i = HAND.index(code)
        p = seg(t, cues[k], cues[k] + 0.7)
        x, y = kit.fly(p, slots[i], skat[k], arc=80)
        put(layer, code, x, y, HW, angle=(k - 0.5) * 8 * p)
    kit.pill(layer, "Skat", 290, 1090, 44, INK, pop=seg(t, 0.3, 0.8))


def s4_why(t, dur, layer):
    s4_hand(5, dur, layer, rings=[(TRUMPS, GOLD, 1.0), (ACES, GREEN, 1.0)], gone=1.0)
    for k, code in enumerate(DROP):
        put(layer, code, 470 + k * 140, 1090, HW, angle=(k - 0.5) * 8)
    p = seg(t, S4.at(4, "augen", 1.6), S4.at(4, "augen", 1.6) + 0.5)
    kit.pill(layer, "0 Augen", 800, 1090, 48, AMBER, INK, pop=p)


S4 = kit.Lesson("skat-druecken", S4_LINES, ("Welche zwei", "drückst du?"),
                [s4_hook, s4_trump, s4_keep, s4_drop, s4_why], bgs(3))

# ---------------------------------------------------------------- S5 Bedienen

S5_LINES = [
    "Bedienen beim Skat, in 20 Sekunden.",
    "Kreuz ist Trumpf, und Herz wird angespielt.",
    "Hast du Herz, musst du Herz legen.",
    "Der Herz-Bube zählt dabei zum Trumpf, du legst eine echte Herzkarte.",
    "Hast du kein Herz, darfst du stechen oder abwerfen.",
]
S5_HAND = ["7h", "10h", "Bh", "Ks", "Ac"]
LED = (540, 560)


def s5_table(t, layer, led_alpha=1.0):
    put(layer, "Ah", *LED, 190, angle=-4, alpha=led_alpha)


def s5_hand(layer, t, t0=-1.0, marks=None):
    slots = row(5, 540, 960, 160, 16)
    for i, code in enumerate(S5_HAND):
        dy, a = kit.land(seg(t, t0 + i * 0.08, t0 + 0.4 + i * 0.08), 120)
        dim = 0.0
        if marks and code in marks and marks[code][0] == "x":
            dim = marks[code][1]
        put(layer, code, slots[i][0], slots[i][1] + dy, 160, alpha=a, dim=dim)
    return slots


def s5_hook(t, dur, layer):
    s5_table(t, layer)
    s5_hand(layer, t, -0.6)


def s5_lead(t, dur, layer):
    p = seg(t, S5.at(1, "angespielt", 1.8), S5.at(1, "angespielt", 1.8) + 0.5)
    s5_table(t, layer, led_alpha=1.0)
    s5_hand(layer, t)
    kit.pill(layer, "Trumpf: Kreuz", 540, 380, 46, GREEN, pop=seg(t, 0.2, 0.7))
    ring(layer, *LED, 190, RED, p)


def s5_follow(t, dur, layer):
    s5_table(t, layer)
    kit.pill(layer, "Trumpf: Kreuz", 540, 380, 46, GREEN)
    p = seg(t, S5.at(2, "legen", 1.6), S5.at(2, "legen", 1.6) + 0.5)
    slots = s5_hand(layer, t, marks={c: ("x", p) for c in ("Ks", "Ac", "Bh")})
    for i, code in enumerate(S5_HAND):
        x, y = slots[i]
        if code in ("7h", "10h"):
            kit.check(layer, x, y - ch(160) / 2 - 10, 34, GREEN, p)
        else:
            kit.cross(layer, x, y - ch(160) / 2 - 10, 34, RED, p)


def s5_bube(t, dur, layer):
    s5_table(t, layer)
    kit.pill(layer, "Trumpf: Kreuz", 540, 380, 46, GREEN)
    slots = s5_hand(layer, t, marks={c: ("x", 1.0) for c in ("Ks", "Ac")})
    i = S5_HAND.index("Bh")
    p = seg(t, S5.at(3, "trumpf", 1.6), S5.at(3, "trumpf", 1.6) + 0.4)
    ring(layer, *slots[i], 160, GOLD, p)
    kit.pill(layer, "Trumpf", slots[i][0], 960 + ch(160) / 2 + 55, 42, GREEN, pop=p)
    for code in ("7h", "10h"):
        x, y = slots[S5_HAND.index(code)]
        kit.check(layer, x, y - ch(160) / 2 - 10, 34, GREEN, 1.0)


def s5_free(t, dur, layer):
    s5_table(t, layer)
    kit.pill(layer, "Trumpf: Kreuz", 540, 380, 46, GREEN)
    codes = ["Bc", "Ks", "Ac"]
    slots = row(3, 540, 960, 180, 40)
    deal(layer, codes, slots, 180, t, 0.1)
    ts, ta = S5.at(4, "stechen", 2.0), S5.at(4, "abwerfen", 2.6)
    kit.pill(layer, "stechen", slots[0][0], 960 + ch(180) / 2 + 55, 42, GREEN, pop=seg(t, ts, ts + 0.5))
    kit.pill(layer, "abwerfen", (slots[1][0] + slots[2][0]) / 2, 960 + ch(180) / 2 + 55, 42, AMBER, INK,
             pop=seg(t, ta, ta + 0.5))


S5 = kit.Lesson("skat-bedienen", S5_LINES, ("Bedienen,", "in 20 Sekunden"),
                [s5_hook, s5_lead, s5_follow, s5_bube, s5_free], bgs(4))

# ---------------------------------------------------------------- output

SHORTS = {
    "skat-buben": (S1, "V1 Die vier Buben in 20 Sekunden",
                   "Die Reihenfolge der Buben beim Skat: Kreuz, Pik, Herz, Karo. Und warum sie im Null ganz normale Karten sind."),
    "skat-augen": (S2, "V2 Augen zählen in 25 Sekunden",
                   "Alle Kartenwerte beim Skat auf einen Blick: Ass 11, Zehn 10, König 4, Dame 3, Bube 2. 120 Augen, 61 gewinnen."),
    "skat-18": (S3, "V3 Woher kommt die 18",
                "Warum Skat-Reizen bei 18 anfängt: Karo, Grundwert 9, mit oder ohne 1, Spiel 2."),
    "skat-druecken": (S4, "V4 Welche zwei drückst du",
                      "Drücken im Herzspiel: Trümpfe und Asse bleiben, kleine Karten in Nebenfarben gehen in den Skat."),
    "skat-bedienen": (S5, "V5 Bedienen in 20 Sekunden",
                      "Die Bedienpflicht beim Skat: angespielte Farbe bedienen, Buben zählen zum Trumpf, sonst stechen oder abwerfen."),
}


def caption_txt(desc: str) -> str:
    tags = " ".join(P.TAGS_LEARN)
    return (
        "POST AS: Video (upload video.mp4).\n\n"
        "COVER: pick the first frame (the headline over the cards).\n\n"
        f"CAPTION (paste as is):\n{desc} Speichern für den nächsten Skatabend.\n\n{P.CTAS['name']}\n\n{tags}\n\n"
        f"PINNED COMMENT (post it yourself, then pin):\n{P.PINNED}\n\n"
        f"REPLY to every \"App\" or \"Wie heißt die?\" comment:\n{P.REPLY}\n\n"
        "SOUND: keep the video's own music (an original score, no voice). Add nothing from the library.\n\n"
        "BEFORE POSTING (TikTok's Next button can publish straight away, so set this on the post screen first):\n"
        "More options > Disclose post content > Your brand.\n\n"
        "FORMAT: V Animated short   CTA: name\n"
    )


def main() -> None:
    args = sys.argv[1:]
    still = args[args.index("--still"):] if "--still" in args else []
    names = [a for a in args if not a.startswith("--") and a not in still] or list(SHORTS)
    for name in names:
        lesson, folder, desc = SHORTS[name]
        out_dir = OUT_DIR / folder
        if still:
            qa = pathlib.Path(R.tempfile.gettempdir()) / "skat-shorts-qa" / name
            qa.mkdir(parents=True, exist_ok=True)
            sys.argv = [sys.argv[0], str(qa / "video.mp4"), *still]
            kit.run(lesson)
            continue
        tmp = pathlib.Path(R.tempfile.mkdtemp(prefix="skat-short-")) / "video.mp4"
        sys.argv = [sys.argv[0], str(tmp)]
        kit.run(lesson)
        out_dir.mkdir(parents=True, exist_ok=True)
        shutil.move(tmp, out_dir / "video.mp4")
        (out_dir / "caption.txt").write_text(caption_txt(desc))


if __name__ == "__main__":
    main()
