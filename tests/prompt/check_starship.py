#!/usr/bin/env python3
"""Check the generated starship.toml against starship's own config structs. Dev-only.

    git clone --depth 1 --branch v1.25.1 https://github.com/starship/starship /tmp/starship
    python3 tests/prompt/check_starship.py /tmp/starship

Checks: every option key is a field of the module's config struct (src/configs/<module>.rs);
every $module in the root format exists; every color in a style string is either a palette
entry or a standard ANSI color name.
"""

from __future__ import annotations

import re
import sys
import tomllib
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
CONFIGS = sorted(REPO.glob("themes/*/starship/starship.toml"))
NAMED = {"black", "red", "green", "yellow", "blue", "purple", "cyan", "white", "none"} | \
        {f"bright-{c}" for c in ("black", "red", "green", "yellow", "blue", "purple", "cyan", "white")}
STYLE_WORDS = {"bold", "italic", "underline", "dimmed", "inverted", "blink", "hidden", "strikethrough", "none"}


def fields(rs: Path) -> set[str]:
    return set(re.findall(r"^\s*pub (?:r#)?(\w+):", rs.read_text(), re.M))


def styles(value: str) -> list[str]:
    """Style strings inside a format: the (...) after a [...] text group."""
    return re.findall(r"\]\(([^)]*)\)", value)


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    cfg_dir = Path(argv[1]) / "src/configs"
    # Module name -> config file, from FullConfig in mod.rs (e.g. `golang: go::GoConfig`).
    modules = {name: cfg_dir / f"{file}.rs" for name, file in
               re.findall(r"^\s*(?:pub )?(\w+): (\w+)::\w+Config", (cfg_dir / "mod.rs").read_text(), re.M)}
    errors: list[str] = []
    for path in CONFIGS:
        conf = tomllib.loads(path.read_text())
        palette = set(conf.get("palettes", {}).get(conf.get("palette", ""), {}))
        root_fields = fields(cfg_dir / "starship_root.rs") | {"$schema"}

        def check_style(where: str, style: str) -> None:
            for word in style.split():
                color = word.split(":", 1)[1] if ":" in word else word
                if word in STYLE_WORDS or color in NAMED or color in palette or re.fullmatch(r"#[0-9a-fA-F]{6}", color):
                    continue
                errors.append(f"{path.name}: {where}: unknown color/style '{word}'")

        for key, value in conf.items():
            if isinstance(value, dict) and key != "palettes":
                rs = modules.get(key, cfg_dir / f"{key}.rs")
                if not rs.exists():
                    errors.append(f"{path.name}: unknown module [{key}]")
                    continue
                known = fields(rs)
                for opt, v in value.items():
                    if isinstance(v, dict):          # e.g. [os.symbols]
                        continue
                    if opt not in known:
                        errors.append(f"{path.name}: [{key}] unknown option '{opt}'")
                    if isinstance(v, str):
                        if opt.endswith("style"):
                            check_style(f"[{key}].{opt}", v)
                        for st in styles(v):
                            if "$" not in st:
                                check_style(f"[{key}].{opt}", st)
            elif key not in root_fields:
                errors.append(f"{path.name}: unknown root option '{key}'")
        for mod in re.findall(r"\$(\w+)", conf.get("format", "")):
            if mod not in modules and not (cfg_dir / f"{mod}.rs").exists():
                errors.append(f"{path.name}: format uses unknown module ${mod}")
        for st in styles(conf.get("format", "")):
            check_style("format", st)
    for e in errors:
        print("FAIL", e)
    print("OK" if not errors else f"{len(errors)} problem(s)", f"({len(CONFIGS)} config(s))")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
