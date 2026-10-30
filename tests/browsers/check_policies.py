#!/usr/bin/env python3
"""Validate browser policy and pref files against their primary sources. Dev-only.

    git clone --depth 1 https://github.com/mozilla/policy-templates /tmp/policy-templates
    curl -o /tmp/policies.yaml https://raw.githubusercontent.com/chromium/chromium/main/components/policy/resources/templates/policies.yaml
    python3 tests/browsers/check_policies.py /tmp/policy-templates /tmp/policies.yaml

Checks: every Firefox policy name exists in policy-templates' docs; every key under Firefox's
"Preferences" policy is in the documented allowlist; extension install URLs use the documented
AMO form; every Chromium policy name exists in policies.yaml; user.js / overrides lines parse.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
FIREFOX = REPO / "config/browsers/firefox-policies.json"
CHROMIUM = REPO / "themes/quasar/chromium/policies.json"
PREF_FILES = [REPO / "config/browsers/user.js", REPO / "config/browsers/librewolf.overrides.cfg"]
PREF_LINE = re.compile(r'^(user_pref|defaultPref|pref|lockPref)\("[\w.\-:]+", (true|false|-?\d+|"[^"]*")\);(\s*//.*)?$')


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    docs = (Path(argv[1]) / "docs/index.md").read_text()
    chromium_names = set(re.findall(r"^\s+\d+: (\w+)$", Path(argv[2]).read_text(), re.M))
    errors: list[str] = []

    ff = json.loads(FIREFOX.read_text())["policies"]
    documented = set(re.findall(r"^### (\w+)$", docs, re.M))
    errors += [f"firefox: unknown policy {k}" for k in ff if k not in documented]

    block = re.search(r"Preferences that start with the following prefixes are supported:\n```\n(.*?)```", docs, re.S)
    allowed = [line.split()[0].rstrip("*").rstrip(",") for line in block.group(1).splitlines() if line.strip()]
    for pref in ff.get("Preferences", {}):
        if not any(pref == a or (a.endswith(".") and pref.startswith(a)) for a in allowed):
            errors.append(f"firefox: Preferences policy cannot set {pref}")
    for ext_id, cfg in ff.get("ExtensionSettings", {}).items():
        url = cfg.get("install_url", "")
        if url and url != f"https://addons.mozilla.org/firefox/downloads/latest/{ext_id}/latest.xpi":
            errors.append(f"firefox: {ext_id}: install_url is not the documented AMO form")

    cr = json.loads(CHROMIUM.read_text())
    errors += [f"chromium: unknown policy {k}" for k in cr if k not in chromium_names]

    for f in PREF_FILES:
        for n, line in enumerate(f.read_text().splitlines(), 1):
            s = line.strip()
            if s and not s.startswith("//") and not PREF_LINE.match(s):
                errors.append(f"{f.relative_to(REPO)}:{n}: not a pref line: {s}")

    for e in errors:
        print("FAIL", e)
    if errors:
        return 1
    print(f"OK: firefox {len(ff)} policies ({len(ff.get('Preferences', {}))} prefs), chromium {len(cr)} policies, "
          f"{len(PREF_FILES)} pref files")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
