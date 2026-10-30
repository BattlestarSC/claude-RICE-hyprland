#!/usr/bin/env python3
"""Check the generated Neovim colorscheme against Neovim's documented highlight groups. Dev-only.

    git clone --depth 1 --branch v0.12.3 --filter=blob:none --sparse https://github.com/neovim/neovim /tmp/nvim
    git -C /tmp/nvim sparse-checkout set runtime/doc
    python3 tests/nvim/check_colorscheme.py /tmp/nvim

Runs themes/*/nvim/colors/rice.lua under lua5.4 with a stub `vim` that records every group,
then requires: every tree-sitter capture in :h treesitter-highlight-groups, every
@lsp.type.* in :h lsp-semantic-highlight, the core UI and diagnostic groups; every link target
defined; every color a #RRGGBB string.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
STUB = r"""
local groups = {}
vim = { o = {}, g = {}, cmd = function() end,
        api = { nvim_set_hl = function(_, name, spec) groups[name] = spec end } }
dofile(arg[1])
local out = {}
for name, spec in pairs(groups) do
  local s = {}
  for k, v in pairs(spec) do s[#s + 1] = string.format('%q:%q', k, tostring(v)) end
  out[#out + 1] = string.format('%q:{%s}', name, table.concat(s, ','))
end
print('{' .. table.concat(out, ',') .. '}')
"""
CORE = ["Normal", "NormalFloat", "FloatBorder", "CursorLine", "LineNr", "CursorLineNr", "Visual",
        "Search", "IncSearch", "Pmenu", "PmenuSel", "StatusLine", "WinSeparator", "SignColumn",
        "MatchParen", "Comment", "String", "Function", "Keyword", "Type", "Constant",
        "DiagnosticError", "DiagnosticWarn", "DiagnosticInfo", "DiagnosticHint", "LspInlayHint"]


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    doc = Path(argv[1]) / "runtime/doc"
    captures = re.findall(r"^(@[a-z.]+)\s", (doc / "treesitter.txt").read_text(), re.M)
    lsp_types = re.findall(r"^(@lsp\.type\.\w+)\s", (doc / "lsp.txt").read_text(), re.M)
    errors: list[str] = []
    schemes = sorted(REPO.glob("themes/*/nvim/colors/rice.lua"))
    for scheme in schemes:
        res = subprocess.run(["lua5.4", "-", str(scheme)], input=STUB, text=True, capture_output=True)
        if res.returncode:
            errors.append(f"{scheme}: lua error: {res.stderr.strip()}")
            continue
        groups = json.loads(res.stdout.replace('\\\n', '\\n'))
        for g in captures + lsp_types + CORE:
            if g not in groups:
                errors.append(f"{scheme.relative_to(REPO)}: missing {g}")
        for name, spec in groups.items():
            if "link" in spec and spec["link"] not in groups:
                errors.append(f"{scheme.relative_to(REPO)}: {name} links to undefined {spec['link']}")
            for k in ("fg", "bg", "sp"):
                if k in spec and not re.fullmatch(r"#[0-9A-Fa-f]{6}", spec[k]):
                    errors.append(f"{scheme.relative_to(REPO)}: {name}.{k} = {spec[k]!r}")
        print(f"{scheme.relative_to(REPO)}: {len(groups)} groups; {len(captures)} captures and "
              f"{len(lsp_types)} semantic types required")
    for e in errors:
        print("FAIL", e)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
