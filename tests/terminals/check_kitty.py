#!/usr/bin/env python3
"""Check every option in config/kitty/kitty.conf and the generated theme against kitty's own
option definitions. Dev-only.

    git clone --depth 1 --filter=blob:none --sparse https://github.com/kovidgoyal/kitty /tmp/kitty
    git -C /tmp/kitty sparse-checkout set kitty/options
    python3 tests/terminals/check_kitty.py /tmp/kitty/kitty/options/definition.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
FILES = [REPO / "config/kitty/kitty.conf", *sorted((REPO / "themes").glob("*/kitty/theme.conf"))]
DIRECTIVES = {"include", "globinclude", "envinclude", "geninclude", "map", "mouse_map"}


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    defined = set(re.findall(r"^\s*'(\w+)',?\s*$", Path(argv[1]).read_text(), re.M))
    defined |= set(re.findall(r"^opt\('\+?(\w+)'", Path(argv[1]).read_text(), re.M))
    errors = []
    for f in FILES:
        for n, line in enumerate(f.read_text().splitlines(), 1):
            s = line.strip()
            if not s or s.startswith("#"):
                continue
            key = s.split()[0]
            if key not in DIRECTIVES and key not in defined:
                errors.append(f"{f.relative_to(REPO)}:{n}: unknown kitty option '{key}'")
    for e in errors:
        print("FAIL", e)
    print("OK" if not errors else f"{len(errors)} unknown option(s)", f"({len(FILES)} files)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
