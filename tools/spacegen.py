#!/usr/bin/env python3
"""Generate palette-colored space art as SVG: starfields, nebulae, planets, wallpapers.

Usage:
    tools/spacegen.py <palette.toml> starfield W H [--seed N] [--opaque] > out.svg
    tools/spacegen.py <palette.toml> planet SIZE ROLE [--ring] [--seed N] > out.svg
    tools/spacegen.py <palette.toml> wallpaper W H [--seed N] > out.svg

Deterministic for a given palette + seed, so committed outputs are reproducible. SVG keeps
it sharp at 4K and tiny on disk; the installer rasterizes with `rsvg-convert` where a
consumer needs PNG (rofi url() via gdk-pixbuf, hyprpaper). Dev-only.
"""

from __future__ import annotations

import argparse
import math
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from palette import load, mix_oklch  # noqa: E402

# Star color weights: mostly neutral, a few tinted ones, like a real sky.
STAR_COLORS = [("subtext", 62), ("bright", 18), ("cyan", 9), ("yellow", 6), ("purple", 3), ("pink", 2)]


def color(pal: dict, role: str) -> str:
    return pal["accent"].get(role) or pal["base"][role]


def _stars(pal: dict, w: int, h: int, rng: random.Random, density: float) -> list[str]:
    roles, weights = zip(*STAR_COLORS)
    out = []
    count = int(w * h * density)
    for _ in range(count):
        x, y = rng.uniform(0, w), rng.uniform(0, h)
        big = rng.random() < 0.04
        r = rng.uniform(1.1, 2.0) if big else rng.uniform(0.35, 1.0)
        op = rng.uniform(0.75, 1.0) if big else rng.uniform(0.3, 0.85)
        c = color(pal, rng.choices(roles, weights)[0])
        if big:  # soft halo for the few bright stars
            out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r * 3.2:.1f}" fill="{c}" opacity="{op * 0.18:.2f}"/>')
        out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.2f}" fill="{c}" opacity="{op:.2f}"/>')
    return out


def _nebula(pal: dict, w: int, h: int, rng: random.Random, uid: str, strength: float = 1.0) -> tuple[list[str], list[str]]:
    defs, shapes = [], []
    blobs = [("purple", 0.30), ("red", 0.20), ("cyan", 0.12), ("blue", 0.14)]
    for i, (role, op) in enumerate(blobs):
        gid = f"{uid}n{i}"
        defs.append(f'<radialGradient id="{gid}"><stop offset="0" stop-color="{color(pal, role)}" stop-opacity="{op * strength:.2f}"/>'
                    f'<stop offset="1" stop-color="{color(pal, role)}" stop-opacity="0"/></radialGradient>')
        cx, cy = rng.uniform(0.1, 0.9) * w, rng.uniform(0.15, 0.85) * h
        rx, ry = rng.uniform(0.25, 0.5) * w, rng.uniform(0.2, 0.45) * h
        rot = rng.uniform(-35, 35)
        shapes.append(f'<ellipse cx="{cx:.0f}" cy="{cy:.0f}" rx="{rx:.0f}" ry="{ry:.0f}" fill="url(#{gid})" '
                      f'transform="rotate({rot:.1f} {cx:.0f} {cy:.0f})"/>')
    return defs, shapes


def starfield(pal: dict, w: int, h: int, seed: int, opaque: bool) -> str:
    rng = random.Random(seed)
    defs, neb = _nebula(pal, w, h, rng, "s", 0.7)
    bg = f'<rect width="{w}" height="{h}" fill="{pal["base"]["mantle"]}"/>' if opaque else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">'
            f'<defs>{"".join(defs)}</defs>{bg}{"".join(neb)}{"".join(_stars(pal, w, h, rng, 1 / 2600))}</svg>')


def _planet_body(pal: dict, cx: float, cy: float, r: float, role: str, ring: bool, rng: random.Random, uid: str) -> tuple[list[str], list[str]]:
    base = color(pal, role)
    light = mix_oklch(base, pal["base"]["bright"], 0.35)
    dark = mix_oklch(base, pal["base"]["crust"], 0.75)
    defs = [
        f'<radialGradient id="{uid}b" cx="0.35" cy="0.32" r="0.75"><stop offset="0" stop-color="{light}"/>'
        f'<stop offset="0.55" stop-color="{base}"/><stop offset="1" stop-color="{dark}"/></radialGradient>',
        f'<radialGradient id="{uid}t" cx="0.78" cy="0.8" r="0.9"><stop offset="0.25" stop-color="{pal["base"]["crust"]}" stop-opacity="0.85"/>'
        f'<stop offset="0.75" stop-color="{pal["base"]["crust"]}" stop-opacity="0"/></radialGradient>',
        f'<clipPath id="{uid}c"><circle cx="{cx}" cy="{cy}" r="{r}"/></clipPath>',
        f'<clipPath id="{uid}top"><rect x="{cx - 3 * r}" y="{cy - 3 * r}" width="{6 * r}" height="{3 * r}"/></clipPath>',
        f'<clipPath id="{uid}bot"><rect x="{cx - 3 * r}" y="{cy}" width="{6 * r}" height="{3 * r}"/></clipPath>',
    ]
    bands = []
    for _ in range(rng.randint(3, 5)):  # atmospheric bands
        y = cy + rng.uniform(-0.8, 0.8) * r
        bands.append(f'<ellipse cx="{cx}" cy="{y:.1f}" rx="{r * 1.3:.1f}" ry="{r * rng.uniform(0.04, 0.12):.1f}" '
                     f'fill="{rng.choice([light, dark])}" opacity="{rng.uniform(0.12, 0.3):.2f}"/>')
    tilt = rng.uniform(-24, -12)
    ring_c = mix_oklch(color(pal, "yellow"), base, 0.4)
    ring_el = (f'<ellipse cx="{cx}" cy="{cy}" rx="{r * 1.85:.1f}" ry="{r * 0.42:.1f}" fill="none" stroke="{ring_c}" '
               f'stroke-width="{r * 0.16:.1f}" opacity="0.75" transform="rotate({tilt:.1f} {cx} {cy})"/>'
               f'<ellipse cx="{cx}" cy="{cy}" rx="{r * 1.55:.1f}" ry="{r * 0.33:.1f}" fill="none" stroke="{ring_c}" '
               f'stroke-width="{r * 0.05:.1f}" opacity="0.5" transform="rotate({tilt:.1f} {cx} {cy})"/>')
    shapes = []
    if ring:  # back half of the ring, behind the planet
        shapes.append(f'<g clip-path="url(#{uid}top)" transform="rotate({tilt:.1f} {cx} {cy}) rotate({-tilt:.1f} {cx} {cy})">{ring_el}</g>')
    shapes.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="url(#{uid}b)"/>')
    shapes.append(f'<g clip-path="url(#{uid}c)">{"".join(bands)}</g>')
    shapes.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="url(#{uid}t)"/>')
    if ring:  # front half over the planet
        shapes.append(f'<g clip-path="url(#{uid}bot)">{ring_el}</g>')
    return defs, shapes


def planet(pal: dict, size: int, role: str, ring: bool, seed: int) -> str:
    rng = random.Random(seed)
    r = size * (0.26 if ring else 0.42)
    defs, shapes = _planet_body(pal, size / 2, size / 2, r, role, ring, rng, "p")
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}" width="{size}" height="{size}">'
            f'<defs>{"".join(defs)}</defs>{"".join(shapes)}</svg>')


def wallpaper(pal: dict, w: int, h: int, seed: int) -> str:
    rng = random.Random(seed)
    ndefs, neb = _nebula(pal, w, h, rng, "w", 1.0)
    stars = _stars(pal, w, h, rng, 1 / 3200)
    s = min(w, h)
    bodies = [(0.80 * w, 0.30 * h, 0.075 * s, "orange", True), (0.16 * w, 0.76 * h, 0.045 * s, "blue", False),
              (0.60 * w, 0.84 * h, 0.022 * s, "purple", False)]
    pdefs, pshapes = [], []
    for i, (cx, cy, r, role, ring) in enumerate(bodies):
        d, sh = _planet_body(pal, round(cx, 1), round(cy, 1), round(r, 1), role, ring, rng, f"w{i}")
        pdefs += d
        pshapes += sh
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">'
            f'<defs>{"".join(ndefs + pdefs)}</defs><rect width="{w}" height="{h}" fill="{pal["base"]["crust"]}"/>'
            f'{"".join(neb)}{"".join(stars)}{"".join(pshapes)}</svg>')


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("palette", type=Path)
    ap.add_argument("kind", choices=["starfield", "planet", "wallpaper"])
    ap.add_argument("args", nargs="+")
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--ring", action="store_true")
    ap.add_argument("--opaque", action="store_true")
    a = ap.parse_args()
    pal = load(a.palette)
    if a.kind == "starfield":
        out = starfield(pal, int(a.args[0]), int(a.args[1]), a.seed, a.opaque)
    elif a.kind == "planet":
        out = planet(pal, int(a.args[0]), a.args[1], a.ring, a.seed)
    else:
        out = wallpaper(pal, int(a.args[0]), int(a.args[1]), a.seed)
    sys.stdout.write(out + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
