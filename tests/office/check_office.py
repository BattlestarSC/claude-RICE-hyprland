#!/usr/bin/env python3
"""Check the rice's LibreOffice theme extension and TeXstudio config against their sources. Dev-only.

    git clone --depth 1 --branch libreoffice-26.8.2.2 --filter=blob:none --sparse \\
        https://github.com/LibreOffice/core /tmp/lo
    git -C /tmp/lo sparse-checkout set --no-cone /officecfg/registry/schema/org/openoffice/Office/
    git clone --depth 1 --filter=blob:none --sparse https://github.com/texstudio-org/texstudio /tmp/txs
    git -C /tmp/txs sparse-checkout set --no-cone /src/configmanager.cpp \\
        /src/qcodeedit/lib/qformatscheme.cpp /utilities/qxs/defaultFormatsDark.qxf
    python3 tests/office/check_office.py /tmp/lo /tmp/txs

LibreOffice (themes/*/libreoffice/extension):
- ColorScheme.xcu: every entry is a group of the ColorScheme template in UI.xcs, every template
  group is present, IsVisible only where the schema has it, colors are ints 0..0xFFFFFF or nil.
- Appearance.xcu: every prop exists in Common.xcs's Appearance group; enumerated values allowed.
- META-INF/manifest.xml lists files that exist.
TeXstudio (themes/*/texstudio/texstudio.ini, parsed with Python's configparser):
- [texmaker] keys are registered options in configmanager.cpp; the style name exists there.
- [formatsDark] ids exist in defaultFormatsDark.qxf; fields are ones QFormatScheme reads.
"""

from __future__ import annotations

import configparser
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
OOR = "{http://openoffice.org/2001/registry}"
XSI_NIL = "{http://www.w3.org/2001/XMLSchema-instance}nil"


def schema_groups(xcs: Path, template: str) -> dict[str, set[str]]:
    """Props of each group inside <group oor:name=template> in a component schema's templates."""
    root = ET.parse(xcs).getroot()
    for group in root.iter("group"):
        if group.get(f"{OOR}name") == template:
            return {g.get(f"{OOR}name"): {p.get(f"{OOR}name") for p in g.findall("prop")}
                    for g in group.findall("group")}
    raise SystemExit(f"{xcs}: template group {template} not found")


def check_libreoffice(lo: Path, errors: list[str]) -> None:
    office = lo / "officecfg/registry/schema/org/openoffice/Office"
    groups = schema_groups(office / "UI.xcs", "ColorScheme")
    common = ET.parse(office / "Common.xcs").getroot()
    appearance = next(g for g in common.iter("group") if g.get(f"{OOR}name") == "Appearance")
    app_props = {p.get(f"{OOR}name"): p for p in appearance.findall("prop")}

    for ext in sorted(REPO.glob("themes/*/libreoffice/extension")):
        name = ext.relative_to(REPO)
        scheme = ET.parse(ext / "registry/ColorScheme.xcu").getroot()
        schemes = scheme.find("node[@oor:name='ColorScheme']/node[@oor:name='ColorSchemes']",
                              {"oor": OOR[1:-1]})
        entries = list(schemes[0]) if schemes is not None and len(schemes) else []
        seen = set()
        for node in entries:
            entry = node.get(f"{OOR}name")
            seen.add(entry)
            if entry not in groups:
                errors.append(f"{name}: unknown color entry {entry}")
                continue
            for prop in node.findall("prop"):
                pname = prop.get(f"{OOR}name")
                if pname not in groups[entry]:
                    errors.append(f"{name}: {entry} has no property {pname}")
                value = prop.find("value")
                if pname == "Color" and value is not None and value.get(XSI_NIL) != "true":
                    if not (value.text or "").isdigit() or not 0 <= int(value.text) <= 0xFFFFFF:
                        errors.append(f"{name}: {entry} color {value.text!r}")
        for missing in sorted(set(groups) - seen):
            errors.append(f"{name}: scheme lacks entry {missing}")

        app = ET.parse(ext / "registry/Appearance.xcu").getroot()
        for prop in app.iter("prop"):
            pname, value = prop.get(f"{OOR}name"), prop.findtext("value")
            if pname not in app_props:
                errors.append(f"{name}: Appearance has no property {pname}")
                continue
            allowed = {e.get(f"{OOR}value") for e in app_props[pname].iter("enumeration")}
            if allowed and value not in allowed:
                errors.append(f"{name}: Appearance/{pname} = {value} not in {sorted(allowed)}")

        manifest = ET.parse(ext / "META-INF/manifest.xml").getroot()
        for entry in manifest:
            path = entry.get("{http://openoffice.org/2001/manifest}full-path")
            if not (ext / path).is_file():
                errors.append(f"{name}: manifest lists missing {path}")
        print(f"{name}: {len(seen)} of {len(groups)} color entries")


def check_texstudio(txs: Path, errors: list[str]) -> None:
    cfg_src = (txs / "src/configmanager.cpp").read_text()
    options = set(re.findall(r'registerOption\("([^"]+)"', cfg_src))
    fields = set(re.findall(r'field == "(\w+)"', (txs / "src/qcodeedit/lib/qformatscheme.cpp").read_text()))
    ids = set(re.findall(r'<format id="([^"]+)"', (txs / "utilities/qxs/defaultFormatsDark.qxf").read_text()))
    for ini in sorted(REPO.glob("themes/*/texstudio/texstudio.ini")):
        name = ini.relative_to(REPO)
        parser = configparser.ConfigParser(interpolation=None, comment_prefixes=(";",), delimiters=("=",))
        parser.optionxform = str
        parser.read(ini)
        for key, value in parser["texmaker"].items():
            option = key.replace("\\", "/").replace("%20", " ")
            if option not in options:
                errors.append(f"{name}: [texmaker] {option} is not a TeXstudio option")
            if option == "X11/Style" and f'"{value}"' not in cfg_src:
                errors.append(f"{name}: style {value!r} not in configmanager.cpp")
        n = 0
        for key, value in parser["formatsDark"].items():
            if key == "version":
                continue
            _, fid, field = key.split("\\")
            n += 1
            if fid not in ids:
                errors.append(f"{name}: unknown format id {fid}")
            if field not in fields:
                errors.append(f"{name}: unknown format field {field}")
            if field in ("foreground", "background", "linescolor") and not re.fullmatch(r"#[0-9A-Fa-f]{6}", value):
                errors.append(f"{name}: {fid}/{field} = {value!r}")
        print(f"{name}: {n} format values, {len(parser['texmaker'])} options")


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    errors: list[str] = []
    check_libreoffice(Path(argv[1]), errors)
    check_texstudio(Path(argv[2]), errors)
    for e in errors:
        print("FAIL", e)
    print("ok" if not errors else f"{len(errors)} problem(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
