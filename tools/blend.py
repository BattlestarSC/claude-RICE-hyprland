#!/usr/bin/env python3
"""Blend two palettes in OKLCH and normalize the result against the contrast rules.

Usage:
    tools/blend.py FROM.toml TO.toml --bg T --fg T --accent T
                   [--name NAME] [--tagline TEXT] [--gradient START END] [--cursor ROLE]

Each T is 0..1: 0 keeps FROM, 1 takes TO. The three groups blend independently:
    --bg      crust, mantle, base, surface0-2 (how dark / how much light the screen emits)
    --fg      overlay, subtext, text, bright   (text brightness; halation)
    --accent  the 8 accents                    (saturation and hue character)

After blending, accent lightness is clamped into the APCA band ACCENT_LC (spread <= 16),
comments are lifted to COMMENT_LC, and bright accents are derived from the accents.
Prints TOML to stdout. Dev-only.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from palette import ROLE_ORDER, apca, hex_to_oklch, load, mix_oklch, oklch_to_hex  # noqa: E402

BG_ROLES = ["crust", "mantle", "base", "surface0", "surface1", "surface2"]
FG_ROLES = ["overlay", "subtext", "text", "bright"]

ACCENT_LC = (58.0, 74.0)  # accent APCA band; rules allow 55..82 with spread <= 18.
                          # Asymmetric on purpose: lifting dim accents costs nothing,
                          # darkening yellow/green too far turns them olive.
COMMENT_LC = 47.0         # comments: rule minimum is 45
BRIGHT_DELTA_LC = 9.0     # bright ANSI variants sit this much above their accent


def set_lc(color: str, bg: str, target: float) -> str:
    """Change only OKLCH lightness so the color reaches APCA |Lc| target on bg."""
    L, C, H = hex_to_oklch(color)
    lo, hi = 0.0, 1.0
    for _ in range(40):
        mid = (lo + hi) / 2
        if apca(oklch_to_hex(mid, C, H), bg) < target:
            lo = mid
        else:
            hi = mid
    return oklch_to_hex(hi, C, H)


def blend(a: dict, b: dict, t_bg: float, t_fg: float, t_acc: float) -> dict:
    base = {r: mix_oklch(a["base"][r], b["base"][r], t_bg) for r in BG_ROLES}
    base |= {r: mix_oklch(a["base"][r], b["base"][r], t_fg) for r in FG_ROLES}
    bg = base["base"]

    if apca(base["overlay"], bg) < COMMENT_LC:
        base["overlay"] = set_lc(base["overlay"], bg, COMMENT_LC)

    accent = {r: mix_oklch(a["accent"][r], b["accent"][r], t_acc) for r in ROLE_ORDER["accent"]}
    lo, hi = ACCENT_LC
    for r, c in accent.items():
        lc = apca(c, bg)
        if lc < lo or lc > hi:
            accent[r] = set_lc(c, bg, min(max(lc, lo), hi))

    bright = {r: set_lc(c, bg, apca(c, bg) + BRIGHT_DELTA_LC) for r, c in accent.items()}
    return {"base": base, "accent": accent, "accent_bright": bright}


def to_toml(meta: dict, pal: dict) -> str:
    out = ["[meta]"]
    for k, v in meta.items():
        if isinstance(v, list):
            out.append(f"{k} = [{', '.join(repr(x).replace(chr(39), chr(34)) for x in v)}]")
        else:
            out.append(f'{k} = "{v}"')
    for group in ("base", "accent", "accent_bright"):
        out.append(f"\n[{group}]")
        width = max(len(r) for r in ROLE_ORDER[group])
        out += [f'{r.ljust(width)} = "{pal[group][r]}"' for r in ROLE_ORDER[group]]
    return "\n".join(out) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("src", type=Path)
    ap.add_argument("dst", type=Path)
    ap.add_argument("--bg", type=float, required=True)
    ap.add_argument("--fg", type=float, required=True)
    ap.add_argument("--accent", type=float, required=True)
    ap.add_argument("--name", default="Blend")
    ap.add_argument("--tagline", default="")
    ap.add_argument("--gradient", nargs=2, metavar=("START", "END"), help="accent roles for the border gradient")
    ap.add_argument("--cursor", help="role used for the terminal cursor")
    args = ap.parse_args()
    a, b = load(args.src), load(args.dst)
    pal = blend(a, b, args.bg, args.fg, args.accent)
    meta = {
        "name": args.name,
        "tagline": args.tagline,
        "blend": f"{args.src.stem} -> {args.dst.stem}: bg {args.bg}, fg {args.fg}, accent {args.accent}",
        "border_gradient": args.gradient or a["meta"]["border_gradient"],
        "cursor": args.cursor or a["meta"]["cursor"],
    }
    sys.stdout.write(to_toml(meta, pal))
    return 0


if __name__ == "__main__":
    sys.exit(main())
