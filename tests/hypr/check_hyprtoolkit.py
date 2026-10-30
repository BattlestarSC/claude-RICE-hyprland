#!/usr/bin/env python3
"""Check themes/*/hypr/hyprtoolkit.conf against hyprtoolkit's config keys. Dev-only.

    git clone --depth 1 --branch v0.6.0 https://github.com/hyprwm/hyprtoolkit /tmp/hyprtoolkit
    python3 tests/hypr/check_hyprtoolkit.py /tmp/hyprtoolkit

Every key must be registered in src/palette/ConfigManager.cpp (addConfigValue); keys registered
as Hyprlang::INT take integers or rgba(RRGGBBAA) colors, STRING keys any text.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    src = (Path(argv[1]) / "src/palette/ConfigManager.cpp").read_text()
    keys = dict(re.findall(r'addConfigValue\("(\w+)", Hyprlang::(\w+)', src))
    errors = []
    for conf in sorted(REPO.glob("themes/*/hypr/hyprtoolkit.conf")):
        seen = 0
        for n, line in enumerate(conf.read_text().splitlines(), 1):
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            key, _, value = (s.strip() for s in line.partition("="))
            seen += 1
            if key not in keys:
                errors.append(f"{conf.relative_to(REPO)}:{n}: unknown key {key}")
            elif keys[key] == "INT" and not re.fullmatch(r"rgba\([0-9A-Fa-f]{8}\)|\d+", value):
                errors.append(f"{conf.relative_to(REPO)}:{n}: {key} needs a number or rgba(), got {value!r}")
        print(f"{conf.relative_to(REPO)}: {seen} of {len(keys)} keys set")
    for e in errors:
        print("FAIL", e)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
