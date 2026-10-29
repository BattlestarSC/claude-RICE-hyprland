#!/usr/bin/env python3
"""Palette tooling: color math, contrast rules and reports for colors/**/*.toml.

Usage:
    tools/palette.py check  <palette.toml>...   # exit 1 if any rule fails
    tools/palette.py report <palette.toml>...   # markdown contrast table (WCAG + APCA)
    tools/palette.py json   <palette.toml>...   # dump palettes as JSON

Dev-only tool. The installer must never depend on it (vanilla Arch has no python).

Two contrast models are used:
  * WCAG 2.x ratio: the legal/accessibility baseline. Blind to polarity, so it
    overrates light-on-dark text and says nothing about glare.
  * APCA Lc (WCAG 3 draft, 0.0.98G constants): perceptual lightness contrast,
    polarity-aware. Used to cap halation and to keep accents at an even perceived
    lightness. Reported as |Lc|; negative Lc (light on dark) is folded to positive.
Rules live in RULES below and are documented in docs/colors/proposals.md; change both together.
"""

from __future__ import annotations

import json
import math
import sys
import tomllib
from collections.abc import Callable
from pathlib import Path

ROLE_ORDER = {
    "base": ["crust", "mantle", "base", "surface0", "surface1", "surface2",
             "overlay", "subtext", "text", "bright"],
    "accent": ["red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink"],
    "accent_bright": ["red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink"],
}


# ---------------------------------------------------------------- color math

def hex_to_rgb(value: str) -> tuple[float, float, float]:
    v = value.lstrip("#")
    if len(v) != 6:
        raise ValueError(f"expected #RRGGBB, got {value!r}")
    return tuple(int(v[i:i + 2], 16) / 255 for i in (0, 2, 4))  # type: ignore[return-value]


def rgb_to_hex(rgb: tuple[float, float, float]) -> str:
    return "#" + "".join(f"{round(min(1.0, max(0.0, c)) * 255):02X}" for c in rgb)


def _lin(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _delin(c: float) -> float:
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def hex_to_oklch(value: str) -> tuple[float, float, float]:
    r, g, b = (_lin(c) for c in hex_to_rgb(value))
    l_ = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m_ = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s_ = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
    a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
    bb = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
    return L, math.hypot(a, bb), math.degrees(math.atan2(bb, a)) % 360


def oklch_to_hex(L: float, C: float, H: float) -> str:
    """OKLCH -> sRGB hex. Out-of-gamut colors are brought in by reducing chroma."""
    for _ in range(40):
        a, b = C * math.cos(math.radians(H)), C * math.sin(math.radians(H))
        l_ = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
        m_ = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
        s_ = (L - 0.0894841775 * a - 1.2914855480 * b) ** 3
        rgb = (4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_,
               -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_,
               -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_)
        if all(-1e-4 <= c <= 1 + 1e-4 for c in rgb):
            return rgb_to_hex(tuple(_delin(min(1.0, max(0.0, c))) for c in rgb))  # type: ignore[arg-type]
        C *= 0.95
    return rgb_to_hex(tuple(_delin(min(1.0, max(0.0, c))) for c in rgb))  # type: ignore[arg-type]


def mix_oklch(a: str, b: str, t: float) -> str:
    """Interpolate two colors in OKLCH (shortest hue path). t=0 -> a, t=1 -> b."""
    La, Ca, Ha = hex_to_oklch(a)
    Lb, Cb, Hb = hex_to_oklch(b)
    if Ca < 0.02:  # near-neutral: hue is meaningless, borrow the other's
        Ha = Hb
    if Cb < 0.02:
        Hb = Ha
    dh = ((Hb - Ha + 180) % 360) - 180
    return oklch_to_hex(La + (Lb - La) * t, Ca + (Cb - Ca) * t, Ha + dh * t)


# ---------------------------------------------------------------- contrast

def luminance(value: str) -> float:
    r, g, b = (_lin(c) for c in hex_to_rgb(value))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a: str, b: str) -> float:
    """WCAG 2.x contrast ratio, 1..21."""
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def apca(text: str, bg: str) -> float:
    """APCA-W3 0.0.98G lightness contrast Lc, returned as an absolute value (0..~108)."""
    def screen_y(h: str) -> float:
        r, g, b = hex_to_rgb(h)
        y = 0.2126729 * r ** 2.4 + 0.7151522 * g ** 2.4 + 0.0721750 * b ** 2.4
        return y + (0.022 - y) ** 1.414 if y < 0.022 else y

    yt, yb = screen_y(text), screen_y(bg)
    if abs(yb - yt) < 0.0005:
        return 0.0
    if yb > yt:  # dark text on light background
        s = (yb ** 0.56 - yt ** 0.57) * 1.14
        return 0.0 if s < 0.1 else (s - 0.027) * 100
    s = (yb ** 0.65 - yt ** 0.62) * 1.14  # light text on dark background
    return 0.0 if s > -0.1 else -(s + 0.027) * 100


# ---------------------------------------------------------------- rules

Metric = Callable[[str, str], float]
# (name, metric, foreground ref, background ref, min, max or None, why)
Rule = tuple[str, Metric, str, str, float, "float | None", str]

RULES: list[Rule] = [
    ("WCAG", contrast, "base.text", "base.base", 11.0, 15.5, "body text readable"),
    ("WCAG", contrast, "base.subtext", "base.base", 7.0, None, "secondary text meets AAA"),
    ("WCAG", contrast, "base.overlay", "base.base", 4.5, None, "comments / ANSI 8 meet AA"),
    ("WCAG", contrast, "base.text", "base.surface1", 9.0, None, "text on selection"),
    ("WCAG", contrast, "base.surface2", "base.base", 1.4, None, "inactive borders visible"),
    *[("WCAG", contrast, f"accent.{a}", "base.base", 6.0, None, "accent on editor bg")
      for a in ROLE_ORDER["accent"]],
    *[("WCAG", contrast, f"accent.{a}", "base.surface1", 4.5, None, "accent inside a selection")
      for a in ROLE_ORDER["accent"]],
    *[("WCAG", contrast, f"accent_bright.{a}", "base.base", 7.0, None, "bright ANSI variant")
      for a in ROLE_ORDER["accent_bright"]],
    ("WCAG", contrast, "base.crust", "accent.cyan", 7.0, None, "dark text on a cyan pill"),
    # APCA: caps glare and evens out accents. Added in palette round 2.
    ("APCA", apca, "base.text", "base.base", 75.0, 92.0, "body text fluent, no halation"),
    ("APCA", apca, "base.subtext", "base.base", 60.0, None, "secondary text"),
    ("APCA", apca, "base.overlay", "base.base", 45.0, None, "comments are read, not just seen"),
    *[("APCA", apca, f"accent.{a}", "base.base", 55.0, 82.0, "accent lightness band")
      for a in ROLE_ORDER["accent"]],
]

# Max allowed spread (max - min) of accent APCA Lc on base: no token shouts, none recedes.
ACCENT_SPREAD_MAX = 18.0


def load(path: Path) -> dict:
    with path.open("rb") as fh:
        data = tomllib.load(fh)
    for group, roles in ROLE_ORDER.items():
        missing = [r for r in roles if r not in data.get(group, {})]
        if missing:
            raise SystemExit(f"{path}: [{group}] missing {', '.join(missing)}")
    return data


def lookup(data: dict, ref: str) -> str:
    group, role = ref.split(".")
    return data[group][role]


def accent_spread(data: dict) -> float:
    vals = [apca(data["accent"][r], data["base"]["base"]) for r in ROLE_ORDER["accent"]]
    return max(vals) - min(vals)


def failures(data: dict) -> list[str]:
    out = []
    for kind, metric, fg, bg, lo, hi, why in RULES:
        v = metric(lookup(data, fg), lookup(data, bg))
        if v < lo or (hi is not None and v > hi):
            bound = f">= {lo}" + (f" and <= {hi}" if hi else "")
            out.append(f"{kind} {fg} on {bg} = {v:.1f} (want {bound}; {why})")
    spread = accent_spread(data)
    if spread > ACCENT_SPREAD_MAX:
        out.append(f"APCA accent spread = {spread:.1f} (want <= {ACCENT_SPREAD_MAX}; even accent lightness)")
    return out


def check(paths: list[Path]) -> int:
    failed = 0
    for path in paths:
        for msg in failures(load(path)):
            failed += 1
            print(f"FAIL {path.name}: {msg}")
    if not failed:
        print(f"OK: {len(paths)} palette(s), {len(RULES) + 1} rules each")
    return 1 if failed else 0


def report(paths: list[Path]) -> int:
    for path in paths:
        data = load(path)
        bg, sel = data["base"]["base"], data["base"]["surface1"]
        print(f"### {data['meta']['name']}\n")
        print("| role | hex | WCAG on base | APCA Lc on base | WCAG on surface1 |")
        print("| --- | --- | ---: | ---: | ---: |")
        for group in ("base", "accent", "accent_bright"):
            for role in ROLE_ORDER[group]:
                h = data[group][role]
                print(f"| {group}.{role} | `{h}` | {contrast(h, bg):.2f} | {apca(h, bg):.1f} | {contrast(h, sel):.2f} |")
        print(f"\nAccent APCA spread: {accent_spread(data):.1f}\n")
    return 0


def dump(paths: list[Path]) -> int:
    print(json.dumps({p.stem: load(p) for p in paths}, indent=2))
    return 0


def main(argv: list[str]) -> int:
    if len(argv) < 3 or argv[1] not in {"check", "report", "json"}:
        print(__doc__, file=sys.stderr)
        return 2
    paths = [Path(p) for p in argv[2:]]
    return {"check": check, "report": report, "json": dump}[argv[1]](paths)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
