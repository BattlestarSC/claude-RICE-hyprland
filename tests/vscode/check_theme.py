#!/usr/bin/env python3
"""Check the generated Code - OSS theme and settings against VS Code's own sources. Dev-only.

    git clone --depth 1 --filter=blob:none --sparse https://github.com/microsoft/vscode /tmp/vscode
    git -C /tmp/vscode sparse-checkout set src/vs extensions/git extensions/npm
    python3 tests/vscode/check_theme.py /tmp/vscode

Color keys must be registered with registerColor('<key>', ...) somewhere under src/ (or be one of
the terminal ANSI keys, or an extension's contributes.colors); every setting key in
config/code-oss/settings*.json must appear as a quoted literal in src/ or in a built-in
extension's contributes.configuration.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
THEMES = sorted(REPO.glob("themes/*/code-oss/extension/themes/*.json"))
SETTINGS = [REPO / "config/code-oss/settings.json", REPO / "config/code-oss/settings-defaults.json"]


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    vs = Path(argv[1])
    sources = [p.read_text(errors="replace") for p in (vs / "src").rglob("*.ts")]
    blob = "\n".join(sources)
    registered = set(re.findall(r"registerColor\(\s*'([\w.]+)'", blob))
    registered |= set(re.findall(r"^\s*'(terminal\.ansi\w+)':", blob, re.M))
    ext_settings: set[str] = set()
    for pkg in (vs / "extensions").glob("*/package.json"):
        contributes = json.loads(pkg.read_text()).get("contributes", {})
        registered |= {c["id"] for c in contributes.get("colors", [])}
        conf = contributes.get("configuration", [])
        for section in conf if isinstance(conf, list) else [conf]:
            ext_settings |= set(section.get("properties", {}))

    errors = []
    for theme in THEMES:
        for key in json.loads(theme.read_text())["colors"]:
            if key not in registered:
                errors.append(f"{theme.relative_to(REPO)}: unknown color '{key}'")
    for settings in SETTINGS:
        for key in json.loads(settings.read_text()):
            if key not in ext_settings and f"'{key}'" not in blob and f'"{key}"' not in blob:
                errors.append(f"{settings.relative_to(REPO)}: setting '{key}' not found in VS Code sources")
    for e in errors:
        print("FAIL", e)
    print("OK" if not errors else f"{len(errors)} problem(s)",
          f"({len(registered)} registered colors, {len(THEMES)} theme(s))")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
