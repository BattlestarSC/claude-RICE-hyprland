#!/usr/bin/env python3
"""Check the rice's htop, btop and fastfetch files against their sources. Dev-only.

    git clone --depth 1 --branch 3.5.3  https://github.com/htop-dev/htop /tmp/htop
    git clone --depth 1 --branch v1.4.8 https://github.com/aristocratos/btop /tmp/btop
    git clone --depth 1 --branch 2.70.0 https://github.com/fastfetch-cli/fastfetch /tmp/fastfetch
    python3 tests/cli/check_cli.py /tmp/htop /tmp/btop /tmp/fastfetch

- config/htop/htoprc: every key is one htop's Settings_read() accepts.
- themes/*/btop/themes/rice.theme: every key is in btop's Default_theme, every value #RRGGBB.
- config/btop/btop.conf: every key is a btop option (descriptions table); booleans True/False.
- themes/*/fastfetch/config.jsonc: valid against fastfetch's doc/json_schema.json (needs the
  `jsonschema` Python package).
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def check_htop(htop: Path, errors: list[str]) -> None:
    src = (htop / "Settings.c").read_text()
    keys = set(re.findall(r'String_eq\(option\[0\], "([a-z_]+)"\)', src))
    for n, line in enumerate((REPO / "config/htop/htoprc").read_text().splitlines(), 1):
        if not line or line.startswith("#"):
            continue
        key, _, value = line.partition("=")
        if key not in keys:
            errors.append(f"htoprc:{n}: unknown key {key}")
        if not value:
            errors.append(f"htoprc:{n}: empty value")
    print(f"htoprc: {len(keys)} keys known")


def check_btop(btop: Path, errors: list[str]) -> None:
    theme_src = (btop / "src/btop_theme.cpp").read_text()
    block = theme_src[theme_src.index("Default_theme"):]
    block = block[:block.index("};")]
    theme_keys = set(re.findall(r'\{\s*"([a-z_]+)"', block))
    for theme in sorted(REPO.glob("themes/*/btop/themes/rice.theme")):
        seen = set()
        for n, line in enumerate(theme.read_text().splitlines(), 1):
            m = re.fullmatch(r'theme\[([a-z_]+)\]="(.*)"', line)
            if not m:
                if line and not line.startswith("#"):
                    errors.append(f"{theme.relative_to(REPO)}:{n}: not a theme line")
                continue
            key, value = m.groups()
            seen.add(key)
            if key not in theme_keys:
                errors.append(f"{theme.relative_to(REPO)}:{n}: unknown key {key}")
            if not re.fullmatch(r"#[0-9A-Fa-f]{6}", value):
                errors.append(f"{theme.relative_to(REPO)}:{n}: {key} = {value!r}")
        missing = theme_keys - seen
        if missing:
            errors.append(f"{theme.relative_to(REPO)}: keys not set: {sorted(missing)}")
        print(f"{theme.relative_to(REPO)}: {len(seen)} of {len(theme_keys)} keys")

    cfg_src = (btop / "src/btop_config.cpp").read_text()
    desc = cfg_src[cfg_src.index("descriptions"):]
    desc = desc[:desc.index("\n\t};")]
    options = set(re.findall(r'^\t\t\{"([a-z_0-9]+)",', desc, re.M))
    bools_src = cfg_src[cfg_src.index("bools"):]
    bools = set(re.findall(r'\{"([a-z_0-9]+)", (?:true|false)\}', bools_src[:bools_src.index("};")]))
    for n, line in enumerate((REPO / "config/btop/btop.conf").read_text().splitlines(), 1):
        if not line or line.startswith("#"):
            continue
        key, _, value = (s.strip() for s in line.partition("="))
        if key not in options:
            errors.append(f"btop.conf:{n}: unknown option {key}")
        if key in bools and value not in ("True", "False"):
            errors.append(f"btop.conf:{n}: {key} must be True or False")
    print(f"btop.conf: {len(options)} options known")


def check_fastfetch(fastfetch: Path, errors: list[str]) -> None:
    import jsonschema

    schema = json.loads((fastfetch / "doc/json_schema.json").read_text())
    validator = jsonschema.Draft7Validator(schema)
    for cfg in sorted(REPO.glob("themes/*/fastfetch/config.jsonc")):
        data = json.loads(re.sub(r"(?m)^\s*//.*$", "", cfg.read_text()))
        for e in validator.iter_errors(data):
            errors.append(f"{cfg.relative_to(REPO)}: {list(e.path)}: {e.message[:160]}")
        print(f"{cfg.relative_to(REPO)}: {len(data['modules'])} modules")


def main(argv: list[str]) -> int:
    if len(argv) != 4:
        print(__doc__, file=sys.stderr)
        return 2
    errors: list[str] = []
    check_htop(Path(argv[1]), errors)
    check_btop(Path(argv[2]), errors)
    check_fastfetch(Path(argv[3]), errors)
    for e in errors:
        print("FAIL", e)
    print("ok" if not errors else f"{len(errors)} problem(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
