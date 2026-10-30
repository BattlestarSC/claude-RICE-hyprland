#!/usr/bin/env python3
"""Check the rice's Thunderbird prefs and theme against comm-central. Dev-only.

    git clone --depth 1 --filter=blob:none --sparse https://github.com/mozilla/releases-comm-central /tmp/comm
    git -C /tmp/comm sparse-checkout set --no-cone /mail/themes/shared/mail/ /mail/themes/addons/dark/ \\
        /mail/app/profile/all-thunderbird.js /mailnews/mailnews.js
    python3 tests/browsers/check_thunderbird.py /tmp/comm

- themes/*/thunderbird/userChrome.css: every custom property it sets is defined or used in
  Thunderbird's mail/themes/shared/mail/*.css (a renamed internal shows up here).
- config/thunderbird/user.js: every pref is defined by Thunderbird (all-thunderbird.js,
  mailnews.js) or is a toolkit pref the Firefox user.js already uses (checked against Firefox);
  the theme id is the built-in Dark theme's (mail/themes/addons/dark/manifest.json).
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    comm = Path(argv[1])
    css = "\n".join(p.read_text() for p in (comm / "mail/themes/shared/mail").glob("*.css"))
    known_props = set(re.findall(r"(--[\w-]+)\s*:", css)) | set(re.findall(r"var\((--[\w-]+)", css))
    prefs_src = (comm / "mail/app/profile/all-thunderbird.js").read_text() + (comm / "mailnews/mailnews.js").read_text()
    tb_prefs = set(re.findall(r'pref\("([^"]+)"', prefs_src))
    ff_prefs = set(re.findall(r'user_pref\("([^"]+)"', (REPO / "config/browsers/user.js").read_text()))
    dark_id = json.loads((comm / "mail/themes/addons/dark/manifest.json").read_text())["browser_specific_settings"]["gecko"]["id"]

    errors = []
    for sheet in sorted(REPO.glob("themes/*/thunderbird/userChrome.css")):
        props = re.findall(r"^\s*(--[\w-]+)\s*:", sheet.read_text(), re.M)
        for prop in props:
            if prop not in known_props:
                errors.append(f"{sheet.relative_to(REPO)}: {prop} is not used by Thunderbird")
        print(f"{sheet.relative_to(REPO)}: {len(props)} variables")

    userjs = (REPO / "config/thunderbird/user.js").read_text()
    prefs = re.findall(r'user_pref\("([^"]+)",\s*(.+?)\);', userjs)
    for name, value in prefs:
        if name == "extensions.activeThemeID":
            if value.strip('"') != dark_id:
                errors.append(f"user.js: theme {value} is not the Dark theme ({dark_id})")
        elif name not in tb_prefs and name not in ff_prefs:
            errors.append(f"user.js: {name} is neither a Thunderbird pref nor one of the checked Firefox ones")
    print(f"config/thunderbird/user.js: {len(prefs)} prefs")
    for e in errors:
        print("FAIL", e)
    print("ok" if not errors else f"{len(errors)} problem(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
