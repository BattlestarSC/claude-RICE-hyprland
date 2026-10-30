#!/usr/bin/env python3
"""Check the generated imv and Zathura configs against their sources. Dev-only.

    git clone --depth 1 https://github.com/pwmt/zathura /tmp/zathura
    git clone --depth 1 https://github.com/eXeC64/imv /tmp/imv      # mirror; 4.3.0 (Arch has 5.x)
    python3 tests/apps/check_viewers.py /tmp/zathura /tmp/imv

- themes/*/zathura/zathurarc: every line is `set NAME VALUE` with a name registered by
  girara_setting_add in zathura/ (zathura and its bundled girara-gtk), or `include FILE`; color
  values parse as #RRGGBB or rgba(r, g, b, a); boolean options get true/false.
- themes/*/imv/config: every key under [options] is one imv's config handler accepts
  (`strcmp(name, "...")` in src/imv.c); colors are 6 hex digits, alphas 2.
"""

from __future__ import annotations

import re
import shlex
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
COLOR = re.compile(r"^(#[0-9A-Fa-f]{6}|rgba\(\d{1,3}, \d{1,3}, \d{1,3}, (0|1|0?\.\d+)\))$")


def zathura_settings(src: Path) -> dict[str, str]:
    text = "\n".join(p.read_text(errors="replace") for p in src.rglob("*.c"))
    out = {}
    for m in re.finditer(r'girara_setting_add\(\s*\w+,\s*"([\w-]+)",\s*[^,]+,\s*(\w+)', text):
        out[m.group(1)] = m.group(2)
    return out


def check_zathura(src: Path, errors: list[str]) -> None:
    settings = zathura_settings(src)
    if len(settings) < 50:
        errors.append(f"only {len(settings)} zathura settings found; wrong checkout?")
    for rc in sorted(REPO.glob("themes/*/zathura/zathurarc")):
        n = 0
        for i, line in enumerate(rc.read_text().splitlines(), 1):
            if not line or line.startswith("#"):
                continue
            argv = shlex.split(line)
            where = f"{rc.relative_to(REPO)}:{i}"
            if argv[0] == "include" and len(argv) == 2:
                continue
            if argv[0] != "set" or len(argv) != 3:
                errors.append(f"{where}: not 'set NAME VALUE': {line}")
                continue
            name, value = argv[1], argv[2]
            kind = settings.get(name)
            n += 1
            if kind is None:
                errors.append(f"{where}: unknown option {name}")
            elif kind == "BOOLEAN" and value not in ("true", "false"):
                errors.append(f"{where}: {name} is boolean, got {value}")
            elif kind == "STRING" and name.endswith(("-bg", "-fg", "-color", "color")) and not COLOR.match(value):
                errors.append(f"{where}: {name}: not a color: {value}")
        print(f"{rc.relative_to(REPO)}: {n} options")


def check_imv(src: Path, errors: list[str]) -> None:
    text = (src / "src/imv.c").read_text()
    names = set(re.findall(r'strcmp\(name, "(\w+)"\)', text))
    if "background" not in names:
        errors.append("imv option names not found; wrong checkout?")
    for cfg in sorted(REPO.glob("themes/*/imv/config")):
        section, n = None, 0
        for i, line in enumerate(cfg.read_text().splitlines(), 1):
            if not line or line.startswith("#"):
                continue
            where = f"{cfg.relative_to(REPO)}:{i}"
            if line.startswith("["):
                section = line.strip("[]")
                continue
            key, _, value = (s.strip() for s in line.partition("="))
            if section != "options":
                errors.append(f"{where}: only [options] is expected, got [{section}]")
                continue
            n += 1
            if key not in names:
                errors.append(f"{where}: unknown option {key}")
            elif key.endswith("color") or key == "background":
                if not re.fullmatch(r"[0-9A-Fa-f]{6}", value):
                    errors.append(f"{where}: {key}: want 6 hex digits, got {value}")
            elif key.endswith("alpha") and not re.fullmatch(r"[0-9A-Fa-f]{2}", value):
                errors.append(f"{where}: {key}: want 2 hex digits, got {value}")
        print(f"{cfg.relative_to(REPO)}: {n} options")


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    errors: list[str] = []
    check_zathura(Path(argv[1]), errors)
    check_imv(Path(argv[2]), errors)
    for e in errors:
        print("FAIL", e)
    print("ok" if not errors else f"{len(errors)} problem(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
