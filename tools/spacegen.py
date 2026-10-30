#!/usr/bin/env python3
"""Generate palette-colored space art as SVG: starfields, nebulae, planets, wallpapers.

Usage:
    tools/spacegen.py <palette.toml> starfield W H [--seed N] [--opaque] > out.svg
    tools/spacegen.py <palette.toml> planet SIZE ROLE [--ring] [--seed N] > out.svg
    tools/spacegen.py <palette.toml> wallpaper W H [--seed N] > out.svg
    tools/spacegen.py <palette.toml> ascii W H [--cell 12x24] [--seed N] > out.svg   # Orbiter-style ASCII scene

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


# ---------------------------------------------------------------- ASCII scene
# Orbiter-style: a scene computed per character cell, drawn with a density ramp. Everything
# is analytic (sphere shading, value noise), so it needs no rasterizer and stays deterministic.

RAMP = " .:-=+*#%@"


def _hash(ix: int, iy: int, seed: int) -> float:
    h = (ix * 374761393 + iy * 668265263 + seed * 2147483647) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((h ^ (h >> 16)) & 0xFFFFFF) / 0xFFFFFF


def _noise(x: float, y: float, seed: int) -> float:
    ix, iy = math.floor(x), math.floor(y)
    fx, fy = x - ix, y - iy
    sx, sy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = _hash(ix, iy, seed), _hash(ix + 1, iy, seed)
    c, d = _hash(ix, iy + 1, seed), _hash(ix + 1, iy + 1, seed)
    return (a + (b - a) * sx) + ((c + (d - c) * sx) - (a + (b - a) * sx)) * sy


def _fbm(x: float, y: float, seed: int, octaves: int = 4) -> float:
    total, amp, norm = 0.0, 0.5, 0.0
    for o in range(octaves):
        total += amp * _noise(x, y, seed + o * 101)
        norm += amp
        x, y, amp = x * 2.03, y * 2.03, amp * 0.5
    return total / norm


def ascii_cells(pal: dict, cols: int, rows: int, seed: int = 7, aspect: float = 0.5) -> list[list[tuple[str, str]]]:
    """Grid of (char, hex color). aspect = cell width / cell height."""
    rng = random.Random(seed)
    W, H = float(cols), rows / aspect
    planet = (0.54 * W, 0.42 * H + 0.36 * W, 0.36 * W)       # cx, cy, r: a big arc rising from the bottom
    moon = (0.15 * W, 0.22 * H, 0.04 * W)
    light = (-0.55, -0.62, 0.56)
    ll = math.sqrt(sum(c * c for c in light))
    light = tuple(c / ll for c in light)
    nebula = [(rng.uniform(0.15, 0.85) * W, rng.uniform(0.05, 0.45) * H, rng.uniform(0.18, 0.3) * W, role)
              for role in ("purple", "blue")]
    cache: dict[tuple[str, int], str] = {}

    def tint(role: str, level: float) -> str:
        q = max(1, min(10, round(level * 10)))
        key = (role, q)
        if key not in cache:
            cache[key] = mix_oklch(color(pal, role), pal["base"]["crust"], 1 - (0.18 + 0.82 * q / 10))
        return cache[key]

    def ramp(b: float) -> str:
        return RAMP[max(0, min(len(RAMP) - 1, int(b * (len(RAMP) - 1) + 0.5)))]

    roles, weights = zip(*STAR_COLORS)

    def body(x: float, y: float, cx: float, cy: float, r: float, kind: str) -> tuple[str, str] | None:
        nx, ny = (x - cx) / r, (y - cy) / r
        d2 = nx * nx + ny * ny
        if d2 > 1:
            if kind == "planet" and d2 <= 1.07 ** 2 and ny < 0.3:          # thin halo above the limb
                halo = (1.07 - math.sqrt(d2)) / 0.07
                if halo > 0.35:
                    return (":" if halo > 0.75 else "."), tint("cyan", 0.2 + 0.35 * halo)
            return None
        nz = math.sqrt(1 - d2)
        lam = max(0.0, nx * light[0] + ny * light[1] + nz * light[2])
        b = 0.04 + 0.66 * lam                                               # tops out at '#', not '@'
        if kind == "moon":
            role = "overlay" if _noise(nx * 4, ny * 4, seed + 3) > 0.6 else "subtext"
            return ramp(b), tint(role, b)
        tx, ty = nx / (nz + 0.35) * 1.5, ny / (nz + 0.35) * 1.5           # cheap spherical warp
        land = _fbm(tx + 3.1, ty, seed) > 0.56
        cloud = _fbm(tx * 2.4, ty * 4.0 + 9, seed + 7, 3) > 0.64
        if cloud:
            role, b = "bright", b + 0.14
        elif land:
            role = "green" if _noise(tx * 3, ty * 3, seed) > 0.5 else "orange"
        else:
            role = "blue"
        if d2 > 0.9:
            role, b = "cyan", b * 0.85 + 0.06                               # atmosphere rim
        return ramp(min(b, 1.0)), tint(role, 0.15 + 0.85 * min(b, 1.0))

    def background(col: int, row: int, x: float, y: float) -> tuple[str, str]:
        if _hash(col, row, seed + 11) > 0.988:
            bright = _hash(col, row, seed + 12)
            srole = roles[int(_hash(col, row, seed + 13) * 1000) % len(roles)] if bright > 0.6 else "subtext"
            return ("*" if bright > 0.93 else "+" if bright > 0.75 else "."), tint(srole, 0.45 + 0.55 * bright)
        glow, role = 0.0, "purple"
        for nx_, ny_, nr, nrole in nebula:
            g = math.exp(-((x - nx_) ** 2 + (y - ny_) ** 2) / (2 * nr * nr)) * _fbm(x / 7, y / 7, seed + 5, 3)
            if g > glow:
                glow, role = g, nrole
        if glow > 0.3 and _hash(col, row, seed + 17) < glow * 0.55:        # sparse, dithered dust
            return ("." if glow < 0.42 else ":"), tint(role, 0.2 + 0.5 * glow)
        return " ", pal["base"]["crust"]

    grid = []
    for row in range(rows):
        line = []
        for col in range(cols):
            x, y = col + 0.5, (row + 0.5) / aspect
            cell = body(x, y, *planet, "planet") or body(x, y, *moon, "moon") or background(col, row, x, y)
            line.append(cell)
        grid.append(line)
    return grid


def ascii_svg(pal: dict, w: int, h: int, cell_w: int, cell_h: int, seed: int) -> str:
    """ASCII scene as SVG text, one <text> per row, color runs as <tspan>. Fits w x h exactly."""
    cols, rows = w // cell_w, h // cell_h
    grid = ascii_cells(pal, cols, rows, seed, cell_w / cell_h)
    fs = cell_h * 0.78
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {cols * cell_w} {rows * cell_h}" '
           f'width="{w}" height="{h}" preserveAspectRatio="xMidYMid slice">',
           f'<rect width="100%" height="100%" fill="{pal["base"]["crust"]}"/>',
           f'<g font-family="JetBrains Mono, IBM Plex Mono, DejaVu Sans Mono, monospace" font-size="{fs:.1f}" '
           f'xml:space="preserve">']
    for r, line in enumerate(grid):
        if all(ch == " " for ch, _ in line):
            continue
        spans: list[str] = []
        run, run_c = "", None

        def flush() -> None:
            if run:
                spans.append(f'<tspan fill="{run_c}">{run}</tspan>' if run_c and run.strip() else run)

        for ch, c in line:
            if ch == " ":          # spaces are colorless: extend whatever run is open
                run += ch
                continue
            if c != run_c and run:
                flush()
                run = ""
            run_c = c
            run += ch
        flush()
        out.append(f'<text x="0" y="{(r + 0.78) * cell_h:.1f}" textLength="{cols * cell_w}" '
                   f'lengthAdjust="spacing">{"".join(spans)}</text>')
    out.append("</g></svg>")
    return "".join(out)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("palette", type=Path)
    ap.add_argument("kind", choices=["starfield", "planet", "wallpaper", "ascii"])
    ap.add_argument("args", nargs="+")
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--ring", action="store_true")
    ap.add_argument("--opaque", action="store_true")
    ap.add_argument("--cell", default="12x24", help="ascii: character cell WxH in output pixels")
    a = ap.parse_args()
    pal = load(a.palette)
    if a.kind == "starfield":
        out = starfield(pal, int(a.args[0]), int(a.args[1]), a.seed, a.opaque)
    elif a.kind == "planet":
        out = planet(pal, int(a.args[0]), a.args[1], a.ring, a.seed)
    elif a.kind == "ascii":
        cw, ch = (int(v) for v in a.cell.split("x"))
        out = ascii_svg(pal, int(a.args[0]), int(a.args[1]), cw, ch, a.seed)
    else:
        out = wallpaper(pal, int(a.args[0]), int(a.args[1]), a.seed)
    sys.stdout.write(out + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
