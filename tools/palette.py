#!/usr/bin/env python3
"""Palette tooling: validate contrast and print reports for colors/**/*.toml.

Usage:
    tools/palette.py check  <palette.toml>...   # exit 1 if any rule fails
    tools/palette.py report <palette.toml>...   # markdown contrast table
    tools/palette.py json   <palette.toml>...   # dump resolved palettes as JSON

Dev-only tool. The installer must never depend on it (vanilla Arch has no python).
Contrast is WCAG 2.x relative-luminance contrast. Rules live in RULES below and are
documented in docs/colors/proposals.md; change both together.
"""

from __future__ import annotations

import json
import sys
import tomllib
from pathlib import Path

ROLE_ORDER = {
    "base": ["crust", "mantle", "base", "surface0", "surface1", "surface2",
             "overlay", "subtext", "text", "bright"],
    "accent": ["red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink"],
    "accent_bright": ["red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink"],
}

# (foreground, background, minimum ratio, maximum ratio or None, why)
RULES: list[tuple[str, str, float, float | None, str]] = [
    ("base.text", "base.base", 11.0, 15.5, "body text: readable, but capped to avoid halation"),
    ("base.subtext", "base.base", 7.0, None, "secondary text meets WCAG AAA"),
    ("base.overlay", "base.base", 4.5, None, "comments / zsh autosuggestions (ANSI 8) meet AA"),
    ("base.text", "base.surface1", 9.0, None, "text on selection / cursorline"),
    ("base.surface2", "base.base", 1.4, None, "inactive borders still visible"),
    *[(f"accent.{a}", "base.base", 6.0, None, "syntax accent on editor bg")
      for a in ROLE_ORDER["accent"]],
    *[(f"accent.{a}", "base.surface1", 4.5, None, "syntax accent inside a selection")
      for a in ROLE_ORDER["accent"]],
    *[(f"accent_bright.{a}", "base.base", 7.0, None, "bright ANSI variant")
      for a in ROLE_ORDER["accent_bright"]],
    ("base.crust", "accent.cyan", 7.0, None, "dark text on a cyan pill (bar module)"),
]


def hex_to_rgb(value: str) -> tuple[float, float, float]:
    v = value.lstrip("#")
    if len(v) != 6:
        raise ValueError(f"expected #RRGGBB, got {value!r}")
    return tuple(int(v[i:i + 2], 16) / 255 for i in (0, 2, 4))  # type: ignore[return-value]


def luminance(value: str) -> float:
    def lin(c: float) -> float:
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (lin(c) for c in hex_to_rgb(value))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a: str, b: str) -> float:
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


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


def check(paths: list[Path]) -> int:
    failed = 0
    for path in paths:
        data = load(path)
        for fg, bg, lo, hi, why in RULES:
            ratio = contrast(lookup(data, fg), lookup(data, bg))
            ok = ratio >= lo and (hi is None or ratio <= hi)
            if not ok:
                failed += 1
                bound = f">= {lo}" + (f" and <= {hi}" if hi else "")
                print(f"FAIL {path.name}: {fg} on {bg} = {ratio:.2f} (want {bound}; {why})")
    if not failed:
        print(f"OK: {len(paths)} palette(s), {len(RULES)} rules each")
    return 1 if failed else 0


def report(paths: list[Path]) -> int:
    for path in paths:
        data = load(path)
        bg = data["base"]["base"]
        sel = data["base"]["surface1"]
        print(f"### {data['meta']['name']}\n")
        print("| role | hex | on base | on surface1 |")
        print("| --- | --- | ---: | ---: |")
        for group in ("base", "accent", "accent_bright"):
            for role in ROLE_ORDER[group]:
                h = data[group][role]
                print(f"| {group}.{role} | `{h}` | {contrast(h, bg):.2f} | {contrast(h, sel):.2f} |")
        print()
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
