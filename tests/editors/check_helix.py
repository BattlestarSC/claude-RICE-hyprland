#!/usr/bin/env python3
"""Check the rice's Helix files against a Helix source checkout. Dev-only.

    git clone --depth 1 --branch 25.07.1 https://github.com/helix-editor/helix /tmp/helix
    python3 tests/editors/check_helix.py /tmp/helix

- config/helix/config.toml: every key is documented in book/src/editor.md (Helix rejects unknown
  editor keys and falls back to the default config).
- themes/*/helix/themes/rice.toml: every key is a scope from book/src/themes.md, every color is
  #RRGGBB or a palette / terminal color name, every modifier and underline style is valid.
- config/helix/languages.toml: every language and language server exists; the perl override
  equals the built-in perl file-types minus "pl".
"""

from __future__ import annotations

import re
import sys
import tomllib
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
TERMINAL = {"default", "black", "red", "green", "yellow", "blue", "magenta", "cyan", "gray",
            "light-red", "light-green", "light-yellow", "light-blue", "light-magenta",
            "light-cyan", "light-gray", "white"}
MODIFIERS = {"bold", "dim", "italic", "underlined", "slow_blink", "rapid_blink", "reversed",
             "hidden", "crossed_out"}
UNDERLINES = {"line", "curl", "dashed", "dotted", "double_line"}


def flatten(table: dict, prefix: str = "") -> dict[str, object]:
    out: dict[str, object] = {}
    for k, v in table.items():
        key = f"{prefix}{k}"
        if isinstance(v, dict):
            out.update(flatten(v, key + "."))
        else:
            out[key] = v
    return out


def editor_keys(book: Path) -> dict[str, set[str]]:
    sections: dict[str, set[str]] = {}
    current = None
    for line in (book / "editor.md").read_text().splitlines():
        m = re.match(r"### `\[(editor[\w.-]*)\]` Section", line)
        if m:
            current = sections.setdefault(m.group(1), set())
        elif current is not None and (m := re.match(r"\|\s*`([\w.-]+)`\s*\|", line)):
            current.add(m.group(1))
    return sections


def theme_scopes(book: Path) -> set[str]:
    text = (book / "themes.md").read_text()
    scopes: set[str] = set()
    stack: list[tuple[int, str]] = []
    for line in text.split("#### Syntax highlighting", 1)[1].splitlines():
        m = re.match(r"(\s*)- `([\w-]+)`", line)
        if m:
            depth = len(m.group(1))
            while stack and stack[-1][0] >= depth:
                stack.pop()
            stack.append((depth, m.group(2)))
            scopes.add(".".join(name for _, name in stack))
            continue
        if m := re.match(r"\s*- `(\d)`(?:, `\d`)*", line):   # markup.heading 1..6
            scopes.update(f"markup.heading.{n}" for n in "123456")
        if m := re.match(r"\|\s*`([\w.-]+)`\s*\|", line):
            scopes.add(m.group(1))
    return scopes


def check_config(book: Path, errors: list[str]) -> None:
    sections = editor_keys(book)
    cfg = tomllib.loads((REPO / "config/helix/config.toml").read_text())
    for top in cfg:
        if top not in {"theme", "editor", "keys"}:
            errors.append(f"config.toml: unknown top-level key {top}")
    for path in flatten(cfg.get("editor", {}), "editor."):
        parts = path.split(".")
        for cut in range(len(parts) - 1, 0, -1):
            section = ".".join(parts[:cut])
            if section in sections:
                rest = parts[cut:]
                if ".".join(rest) in sections[section] or rest[0] in sections[section]:
                    break
                errors.append(f"config.toml: {path} not documented in [{section}]")
                break
        else:
            errors.append(f"config.toml: {path} has no documented section")


def check_theme(book: Path, path: Path, errors: list[str]) -> None:
    scopes = theme_scopes(book)
    theme = tomllib.loads(path.read_text())
    palette = theme.pop("palette", {})
    name = path.relative_to(REPO)
    for color, value in palette.items():
        if not re.fullmatch(r"#[0-9A-Fa-f]{6}", value):
            errors.append(f"{name}: palette {color} = {value!r}")

    def color_ok(c: str) -> bool:
        return c in palette or c in TERMINAL or bool(re.fullmatch(r"#[0-9A-Fa-f]{6}", c))

    for key, value in theme.items():
        if key not in scopes:
            errors.append(f"{name}: {key!r} is not a documented scope")
        spec = {"fg": value} if isinstance(value, str) else value
        for field, v in spec.items():
            if field in ("fg", "bg") and not color_ok(v):
                errors.append(f"{name}: {key}.{field} = {v!r}")
            elif field == "modifiers" and not set(v) <= MODIFIERS:
                errors.append(f"{name}: {key} modifiers {v}")
            elif field == "underline":
                if v.get("style", "line") not in UNDERLINES or not color_ok(v.get("color", "default")):
                    errors.append(f"{name}: {key} underline {v}")
            elif field not in ("fg", "bg", "modifiers", "underline"):
                errors.append(f"{name}: {key} has unknown field {field}")
    print(f"{name}: {len(theme)} keys, {len(palette)} palette colors")


def check_languages(helix: Path, errors: list[str]) -> None:
    builtin = tomllib.loads((helix / "languages.toml").read_text())
    langs = {lang["name"]: lang for lang in builtin["language"]}
    ours = tomllib.loads((REPO / "config/helix/languages.toml").read_text())
    servers = set(builtin["language-server"]) | set(ours.get("language-server", {}))
    for lang in ours.get("language", []):
        if lang["name"] not in langs:
            errors.append(f"languages.toml: unknown language {lang['name']}")
            continue
        for srv in lang.get("language-servers", []):
            srv_name = srv if isinstance(srv, str) else srv["name"]
            if srv_name not in servers:
                errors.append(f"languages.toml: {lang['name']}: unknown server {srv_name}")
        if lang["name"] == "perl":
            want = [t for t in langs["perl"]["file-types"] if t != "pl"]
            if lang["file-types"] != want:
                errors.append(f"languages.toml: perl file-types should be {want}")
    if "pl" not in langs["prolog"]["file-types"]:
        errors.append("built-in prolog no longer lists pl; revisit the perl override")


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    helix = Path(argv[1])
    book = helix / "book/src"
    errors: list[str] = []
    check_config(book, errors)
    for theme in sorted(REPO.glob("themes/*/helix/themes/rice.toml")):
        check_theme(book, theme, errors)
    check_languages(helix, errors)
    for e in errors:
        print("FAIL", e)
    print("ok" if not errors else f"{len(errors)} problem(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
