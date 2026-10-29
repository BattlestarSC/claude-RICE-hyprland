#!/usr/bin/env python3
"""Render docs/colors/preview.html from colors/proposals/*.toml.

Usage:
    tools/preview.py [--standalone] <palette.toml>... > out.html

--standalone wraps the page in <!doctype html>/<head>/<body> so it opens directly
in a browser; without it the output is a body fragment (the claude.ai artifact
publisher supplies the document skeleton). Dev-only; never used by the installer.
"""

from __future__ import annotations

import html
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from palette import ROLE_ORDER, contrast, load  # noqa: E402

# Order in which proposals are presented, and which one is recommended.
RECOMMENDED = "nebula"

LUA_SAMPLE = """\
-- ~/.config/hypr/theme/colors.lua is generated from the palette
local c = require("theme.colors")

hl.config({
    general = {
        gaps_in     = 6,
        border_size = 2,
        col = {
            active_border   = { colors = { c.cyan, c.purple }, angle = 45 },
            inactive_border = c.surface1,
        },
    },
    decoration = { rounding = 10, active_opacity = 1.0 },
})

for i = 1, 9 do
    hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = i }))
end"""

LUA_KEYWORDS = {"local", "function", "for", "do", "end", "if", "then", "else",
                "return", "in", "not", "and", "or", "while"}
LUA_CONSTANTS = {"true", "false", "nil"}
LUA_BUILTINS = {"require", "hl", "os", "string", "table", "pairs", "ipairs"}

TOKEN_RE = re.compile(r"""
    (?P<comment>--[^\n]*)
  | (?P<string>"[^"\n]*")
  | (?P<number>\b\d+(?:\.\d+)?\b)
  | (?P<ident>[A-Za-z_][A-Za-z0-9_]*)
  | (?P<op>\.\.|[=+\-*/<>])
  | (?P<other>.)
""", re.VERBOSE | re.DOTALL)


def highlight_lua(src: str) -> str:
    """Tiny Lua highlighter using the Monokai role mapping documented in proposals.md."""
    out: list[str] = []
    for m in TOKEN_RE.finditer(src):
        kind, text = m.lastgroup, m.group()
        esc = html.escape(text)
        if kind == "comment":
            out.append(f'<span class="t-com">{esc}</span>')
        elif kind == "string":
            out.append(f'<span class="t-str">{esc}</span>')
        elif kind == "number":
            out.append(f'<span class="t-num">{esc}</span>')
        elif kind == "op":
            out.append(f'<span class="t-op">{esc}</span>')
        elif kind == "ident":
            rest = src[m.end():]
            prev = src[:m.start()]
            if text in LUA_KEYWORDS:
                cls = "t-kw"
            elif text in LUA_CONSTANTS:
                cls = "t-num"
            elif text in LUA_BUILTINS or prev.endswith("hl."):
                cls = "t-bi"
            elif rest.startswith("("):
                cls = "t-fn"
            elif re.match(r"\s*=[^=]", rest):
                cls = "t-field"
            else:
                cls = ""
            out.append(f'<span class="{cls}">{esc}</span>' if cls else esc)
        else:
            out.append(esc)
    return "".join(out)


def ansi(data: dict) -> list[str]:
    """ANSI 0-15 mapping. Keep in sync with docs/colors/proposals.md."""
    b, a, ab = data["base"], data["accent"], data["accent_bright"]
    return [
        b["surface1"], a["red"], a["green"], a["yellow"], a["blue"], a["purple"], a["cyan"], b["subtext"],
        b["overlay"], ab["red"], ab["green"], ab["yellow"], ab["blue"], ab["purple"], ab["cyan"], b["bright"],
    ]


def resolve(data: dict, role: str) -> str:
    for group in ("accent", "base"):
        if role in data[group]:
            return data[group][role]
    raise KeyError(role)


def kitty_block(data: dict) -> str:
    b = data["base"]
    cursor = resolve(data, data["meta"]["cursor"])
    lines = [
        f"# {data['meta']['name']} (proposal) - paste into kitty.conf to try it",
        f"foreground {b['text']}",
        f"background {b['base']}",
        f"selection_foreground {b['text']}",
        f"selection_background {b['surface1']}",
        f"cursor {cursor}",
        f"cursor_text_color {b['base']}",
        f"url_color {data['accent']['blue']}",
        f"active_border_color {resolve(data, data['meta']['border_gradient'][0])}",
        f"inactive_border_color {b['surface2']}",
        f"active_tab_foreground {b['crust']}",
        f"active_tab_background {resolve(data, data['meta']['border_gradient'][0])}",
        f"inactive_tab_foreground {b['subtext']}",
        f"inactive_tab_background {b['mantle']}",
        f"tab_bar_background {b['crust']}",
    ]
    lines += [f"color{i} {c}" for i, c in enumerate(ansi(data))]
    return "\n".join(lines)


def css_vars(data: dict) -> str:
    parts = [f"--p-{k}:{v}" for k, v in data["base"].items()]
    parts += [f"--p-{k}:{v}" for k, v in data["accent"].items()]
    parts += [f"--pb-{k}:{v}" for k, v in data["accent_bright"].items()]
    g0, g1 = (resolve(data, r) for r in data["meta"]["border_gradient"])
    parts += [f"--p-g0:{g0}", f"--p-g1:{g1}", f"--p-cursor:{resolve(data, data['meta']['cursor'])}"]
    return ";".join(parts)


def stats(data: dict) -> dict:
    b = data["base"]
    accents = {r: contrast(data["accent"][r], b["base"]) for r in ROLE_ORDER["accent"]}
    weakest = min(accents, key=accents.get)
    return {
        "text": contrast(b["text"], b["base"]),
        "comment": contrast(b["overlay"], b["base"]),
        "weakest": (weakest, accents[weakest]),
    }


def swatch(hex_: str, label: str, on: str) -> str:
    return (f'<div class="sw" style="--sw:{hex_}">'
            f'<span class="sw-chip"></span>'
            f'<span class="sw-name">{label}</span>'
            f'<code class="sw-hex">{hex_.upper()}</code>'
            f'<span class="sw-cr">{contrast(hex_, on):.1f}</span></div>')


def terminal(data: dict) -> str:
    blocks = "".join(f'<span class="ab" style="background:{c}" title="color{i} {c}"></span>'
                     for i, c in enumerate(ansi(data)))
    return f"""
<div class="win win-active">
  <div class="win-title">kitty — ~/claude-RICE-hyprland</div>
  <pre class="term"><span class="c-blue">~/claude-RICE-hyprland</span> <span class="c-purple">on  main</span> <span class="c-green">✓</span>
<span class="c-green">❯</span> ls
<span class="c-blue">colors</span>  <span class="c-blue">docs</span>  <span class="c-blue">tools</span>  CLAUDE.md  README.md  <span class="c-green">install.sh</span>
<span class="c-green">❯</span> git log --oneline -3
<span class="c-yellow">3f9c2e1</span> (<span class="c-cyan">HEAD -&gt; main</span>) colors: add palette proposals
<span class="c-yellow">a07d4b8</span> docs: knowledge base for Hyprland 0.57 Lua config
<span class="c-yellow">0c11e92</span> Initial commit
<span class="c-green">❯</span> sudo pacman -S kitty
<span class="c-red">error:</span> target not found: kity  <span class="c-orange">warning:</span> 2 packages held
<span class="c-green">❯</span> hyprctl ver<span class="c-sugg">sion | head -n1</span><span class="cur"> </span>
<span class="ansi">{blocks}</span></pre>
</div>"""


def editor(data: dict) -> str:
    return f"""
<div class="win win-inactive">
  <div class="win-title">nvim — hyprland.lua</div>
  <pre class="code"><span class="cl"></span>{highlight_lua(LUA_SAMPLE)}</pre>
</div>"""


def bar(data: dict) -> str:
    ws = "".join(f'<span class="ws{" ws-on" if i == 2 else ""}">{i}</span>' for i in range(1, 6))
    return f"""
<div class="bar">
  <div class="bar-l">{ws}</div>
  <div class="bar-c">kitty — ~/claude-RICE-hyprland</div>
  <div class="bar-r">
    <span class="c-cyan">CPU 12%</span><span class="c-purple">MEM 3.1G</span>
    <span class="c-green">VOL 45%</span><span class="c-yellow">BAT 82%</span>
    <span class="clock">23:41</span>
  </div>
</div>"""


def section(path: Path, data: dict) -> str:
    slug = path.stem
    b = data["base"]
    s = stats(data)
    rec = '<span class="rec">Recommended starting point</span>' if slug == RECOMMENDED else ""
    base_sw = "".join(swatch(b[r], r, b["base"]) for r in ROLE_ORDER["base"])
    acc_sw = "".join(swatch(data["accent"][r], r, b["base"]) for r in ROLE_ORDER["accent"])
    brt_sw = "".join(swatch(data["accent_bright"][r], r, b["base"]) for r in ROLE_ORDER["accent_bright"])
    kitty = html.escape(kitty_block(data))
    return f"""
<section class="prop" id="{slug}" style="{css_vars(data)}">
  <div class="prop-in">
    <header class="prop-head">
      <div>
        <h2>{html.escape(data['meta']['name'])}</h2>
        <p class="tag">{html.escape(data['meta']['tagline'])}</p>
      </div>
      {rec}
    </header>
    <div class="desk">
      {bar(data)}
      <div class="wins">{terminal(data)}{editor(data)}</div>
    </div>
    <div class="ramps">
      <div class="ramp"><h3>Base ramp</h3><div class="sws">{base_sw}</div></div>
      <div class="ramp"><h3>Accents</h3><div class="sws">{acc_sw}</div></div>
      <div class="ramp"><h3>Bright accents (ANSI 9–14)</h3><div class="sws">{brt_sw}</div></div>
    </div>
    <p class="cr-note">Numbers are WCAG contrast against <code>base</code> {b['base'].upper()}.
      Body text {s['text']:.1f}:1 · comments {s['comment']:.1f}:1 · weakest accent
      <code>{s['weakest'][0]}</code> {s['weakest'][1]:.1f}:1.</p>
    <details class="kitty">
      <summary>Try it in kitty now</summary>
      <div class="kitty-body">
        <p>Append to <code>~/.config/kitty/kitty.conf</code>, then press <kbd>Ctrl+Shift+F5</kbd> to reload.</p>
        <pre id="kitty-{slug}">{kitty}</pre>
        <button type="button" class="copy" id="copy-{slug}" data-target="kitty-{slug}">Copy kitty colors</button>
      </div>
    </details>
  </div>
</section>"""


def summary(rows: list[tuple[Path, dict]]) -> str:
    trs = []
    for path, data in rows:
        s = stats(data)
        mark = " ★" if path.stem == RECOMMENDED else ""
        chips = "".join(f'<span class="mini" style="background:{data["accent"][r]}"></span>'
                        for r in ROLE_ORDER["accent"])
        trs.append(
            f'<tr><td><a href="#{path.stem}">{html.escape(data["meta"]["name"])}</a>{mark}</td>'
            f'<td><span class="mini mini-bg" style="background:{data["base"]["base"]}"></span>'
            f'<code>{data["base"]["base"].upper()}</code></td>'
            f'<td><span class="chips">{chips}</span></td>'
            f'<td class="num">{s["text"]:.1f}</td><td class="num">{s["comment"]:.1f}</td>'
            f'<td class="num">{s["weakest"][1]:.1f} <span class="dim">{s["weakest"][0]}</span></td></tr>')
    return f"""
<div class="tbl-wrap"><table class="sum">
<thead><tr><th>Proposal</th><th>Background</th><th>Accents</th>
<th class="num">Text</th><th class="num">Comments</th><th class="num">Weakest accent</th></tr></thead>
<tbody>{''.join(trs)}</tbody></table></div>"""


CSS = """
:root{
  /* Layout: a quiet neutral frame; each proposal renders full-bleed in its own palette. */
  --frame-bg:#0F0F13; --frame-fg:#D9D8DF; --frame-dim:#8F8D9A; --frame-line:#25242D; --frame-accent:#B9A7F2;
  --f-display:"Unbounded","Arial Black",system-ui,sans-serif;
  --f-body:"IBM Plex Sans",system-ui,-apple-system,"Segoe UI",sans-serif;
  --f-mono:"JetBrains Mono",ui-monospace,"Cascadia Mono",Menlo,monospace;
  color-scheme:dark;
}
body{background:var(--frame-bg);color:var(--frame-fg);font-family:var(--f-body);font-size:15px;line-height:1.55}
.wrap{max-width:1180px;margin:0 auto;padding-block:40px 24px;
  padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px))}
h1{font-family:var(--f-display);font-weight:600;font-size:clamp(26px,4vw,40px);letter-spacing:-.01em;margin:0 0 8px;text-wrap:balance}
.lede{max-width:68ch;color:var(--frame-dim);margin:0 0 24px}
.lede strong{color:var(--frame-fg);font-weight:500}
a{color:var(--frame-accent)}
code,kbd{font-family:var(--f-mono);font-size:.88em}
.tbl-wrap{overflow-x:auto;border:1px solid var(--frame-line);border-radius:8px}
.sum{border-collapse:collapse;width:100%;min-width:640px;font-size:14px}
.sum th,.sum td{padding:10px 14px;text-align:left;border-bottom:1px solid var(--frame-line);white-space:nowrap}
.sum tbody tr:last-child td{border-bottom:0}
.sum th{font-weight:500;color:var(--frame-dim);font-size:12px;text-transform:uppercase;letter-spacing:.06em}
.sum .num{text-align:right;font-variant-numeric:tabular-nums}
.sum a{text-decoration:none;font-weight:500}
.dim{color:var(--frame-dim);font-size:12px}
.mini{display:inline-block;width:14px;height:14px;border-radius:3px;vertical-align:-2px;margin-right:3px}
.mini-bg{width:18px;outline:1px solid var(--frame-line);margin-right:8px}
.chips{display:inline-flex;gap:2px;vertical-align:middle}
.legend{color:var(--frame-dim);font-size:13px;margin:10px 0 0;max-width:80ch}

.prop{background:var(--p-base);color:var(--p-text);border-top:1px solid var(--p-surface2)}
.prop-in{max-width:1180px;margin:0 auto;padding-block:40px 44px;display:grid;gap:22px;
  padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px))}
.prop-head{display:flex;flex-wrap:wrap;gap:12px 24px;align-items:flex-end;justify-content:space-between}
.prop h2{font-family:var(--f-display);font-weight:600;font-size:clamp(24px,3.4vw,34px);margin:0;color:var(--p-bright);letter-spacing:-.01em}
.tag{margin:4px 0 0;color:var(--p-subtext);max-width:70ch}
.rec{font-size:12px;text-transform:uppercase;letter-spacing:.08em;padding:6px 10px;border-radius:999px;
  background:var(--p-g0);color:var(--p-crust);font-weight:600}

.desk{border-radius:12px;overflow:hidden;border:1px solid var(--p-surface0);
  background:
    radial-gradient(1px 1px at 12% 30%,var(--p-subtext),transparent 60%),
    radial-gradient(1px 1px at 68% 18%,var(--p-overlay),transparent 60%),
    radial-gradient(1.5px 1.5px at 84% 64%,var(--p-subtext),transparent 60%),
    radial-gradient(1px 1px at 33% 82%,var(--p-overlay),transparent 60%),
    radial-gradient(1px 1px at 52% 46%,var(--p-overlay),transparent 60%),
    radial-gradient(120% 90% at 85% 110%,color-mix(in srgb,var(--p-purple) 14%,transparent),transparent 60%),
    radial-gradient(90% 70% at 0% 0%,color-mix(in srgb,var(--p-cyan) 8%,transparent),transparent 60%),
    var(--p-crust)}
.bar{display:flex;align-items:center;gap:12px;justify-content:space-between;flex-wrap:wrap;
  padding:6px 10px;background:color-mix(in srgb,var(--p-mantle) 92%,transparent);
  border-bottom:1px solid var(--p-surface0);font-family:var(--f-mono);font-size:12.5px}
.bar-l{display:flex;gap:4px}
.ws{min-width:24px;text-align:center;padding:2px 6px;border-radius:6px;color:var(--p-overlay)}
.ws-on{background:linear-gradient(45deg,var(--p-g0),var(--p-g1));color:var(--p-crust);font-weight:700}
.bar-c{color:var(--p-subtext);overflow:hidden;text-overflow:ellipsis;white-space:nowrap;min-width:0;flex:1 1 160px;text-align:center}
.bar-r{display:flex;gap:14px;flex-wrap:wrap}
.clock{color:var(--p-text);font-weight:600}
.wins{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,420px),1fr));gap:12px;padding:14px}
.win{min-width:0;border-radius:10px;background:var(--p-base);overflow:hidden}
.win-active{border:2px solid transparent;
  background:linear-gradient(var(--p-base),var(--p-base)) padding-box,linear-gradient(45deg,var(--p-g0),var(--p-g1)) border-box;
  box-shadow:0 10px 30px -10px color-mix(in srgb,var(--p-crust) 80%,transparent)}
.win-inactive{border:2px solid var(--p-surface1)}
.win-title{font-family:var(--f-mono);font-size:11.5px;color:var(--p-overlay);padding:6px 12px;background:var(--p-mantle);border-bottom:1px solid var(--p-surface0)}
.term,.code{margin:0;padding:12px 14px;font-family:var(--f-mono);font-size:12.5px;line-height:1.6;overflow-x:auto;color:var(--p-text);background:var(--p-base)}
.c-red{color:var(--p-red)} .c-orange{color:var(--p-orange)} .c-yellow{color:var(--p-yellow)} .c-green{color:var(--p-green)}
.c-cyan{color:var(--p-cyan)} .c-blue{color:var(--p-blue)} .c-purple{color:var(--p-purple)} .c-pink{color:var(--p-pink)}
.c-sugg{color:var(--p-overlay)}
.cur{background:var(--p-cursor)}
.ansi{display:flex;gap:3px;margin-top:8px;flex-wrap:wrap}
.ab{width:18px;height:14px;border-radius:2px}
.t-kw,.t-op{color:var(--p-red)} .t-str{color:var(--p-yellow)} .t-num{color:var(--p-purple)}
.t-fn{color:var(--p-green)} .t-bi{color:var(--p-cyan)} .t-field{color:var(--p-orange)}
.t-com{color:var(--p-overlay);font-style:italic}

.ramps{display:grid;gap:18px}
.ramp h3{font-size:12px;font-weight:500;text-transform:uppercase;letter-spacing:.08em;color:var(--p-subtext);margin:0 0 8px}
.sws{display:grid;grid-template-columns:repeat(auto-fill,minmax(104px,1fr));gap:8px}
.sw{display:grid;grid-template-columns:auto 1fr;grid-template-rows:auto auto auto;column-gap:8px;align-items:center;
  padding:6px;border-radius:8px;background:var(--p-mantle);border:1px solid var(--p-surface0);min-width:0}
.sw-chip{grid-row:1 / span 3;width:28px;height:28px;border-radius:6px;background:var(--sw);outline:1px solid color-mix(in srgb,var(--p-text) 12%,transparent)}
.sw-name{font-size:12px;color:var(--p-text);overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.sw-hex{font-size:11px;color:var(--p-subtext)}
.sw-cr{font-family:var(--f-mono);font-size:10.5px;color:var(--p-overlay);font-variant-numeric:tabular-nums}
.sw-cr::after{content:":1"}
.cr-note{margin:0;font-size:13px;color:var(--p-subtext)}
.cr-note code{color:var(--p-text)}
.kitty{border:1px solid var(--p-surface1);border-radius:8px;background:var(--p-mantle)}
.kitty summary{cursor:pointer;padding:10px 14px;color:var(--p-text);font-weight:500}
.kitty summary:focus-visible,.copy:focus-visible,a:focus-visible{outline:2px solid var(--p-g0, var(--frame-accent));outline-offset:2px}
.kitty-body{padding:0 14px 14px;display:grid;gap:10px}
.kitty-body p{margin:0;font-size:13px;color:var(--p-subtext)}
.kitty pre{margin:0;padding:12px;border-radius:6px;background:var(--p-crust);color:var(--p-subtext);font-family:var(--f-mono);font-size:12px;overflow-x:auto;max-height:280px}
kbd{padding:1px 5px;border-radius:4px;border:1px solid var(--p-surface2);background:var(--p-surface0);color:var(--p-text)}
.copy{justify-self:start;font:500 13px var(--f-body);padding:7px 12px;border-radius:6px;cursor:pointer;
  border:1px solid var(--p-surface2);background:var(--p-surface0);color:var(--p-text)}
.copy:hover{background:var(--p-surface1)}
.foot{color:var(--frame-dim);font-size:13px}
@media (prefers-reduced-motion:reduce){*{scroll-behavior:auto!important}}
"""

JS = """
document.querySelectorAll('.copy').forEach(btn => {
  btn.addEventListener('click', () => {
    const pre = document.getElementById(btn.dataset.target);
    const done = msg => { const o = btn.textContent; btn.textContent = msg; setTimeout(() => btn.textContent = o, 1600); };
    const select = () => { const r = document.createRange(); r.selectNodeContents(pre);
      const s = getSelection(); s.removeAllRanges(); s.addRange(r); done('Selected; press Ctrl+C'); };
    try {
      navigator.clipboard.writeText(pre.textContent).then(() => done('Copied'), select);
    } catch (e) { select(); }
  });
});
"""

FONTS = ('<link rel="preconnect" href="https://fonts.googleapis.com">'
         '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>'
         '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600'
         '&family=JetBrains+Mono:ital,wght@0,400;0,700;1,400&family=Unbounded:wght@600&display=swap">')


def render(paths: list[Path], standalone: bool) -> str:
    rows = [(p, load(p)) for p in paths]
    rows.sort(key=lambda r: (r[0].stem != RECOMMENDED, r[0].stem))
    body = f"""<title>Rice Palette Proposals</title>
<meta name="claude:viewport-fit-sides" content="cover">
{FONTS}
<style>{CSS}</style>
<div class="wrap">
  <h1>Rice Palette Proposals</h1>
  <p class="lede">Four candidate color schemes for the Hyprland + Kitty + Zsh rice. All share Monokai's
  role mapping (keywords red, functions green, strings yellow, numbers purple, builtins cyan,
  parameters orange) on a dark, blue-violet "space" base. <strong>They differ in base hue, accent
  saturation, and contrast.</strong> Every palette passes the same contrast rules
  (<code>tools/palette.py check</code>); the mockups below use the real hex values.</p>
  {summary(rows)}
  <p class="legend">Contrast is the WCAG ratio against each palette's own background. Body text is capped
  near 15:1 on purpose: pure white on black (21:1) causes halation on dark themes. Comments sit at
  4.5:1 or above, where classic Monokai's comment color is about 3:1.</p>
</div>
{''.join(section(p, d) for p, d in rows)}
<div class="wrap"><p class="foot">Generated by <code>tools/preview.py</code> from
<code>colors/proposals/*.toml</code>. Edit the TOML, re-run, and the page follows.</p></div>
<script>{JS}</script>
"""
    if not standalone:
        return body
    return ('<!doctype html>\n<html lang="en"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">'
            '<style>body{margin:0}</style>\n'
            f'</head><body>\n{body}</body></html>\n')


def main(argv: list[str]) -> int:
    args = argv[1:]
    standalone = "--standalone" in args
    paths = [Path(a) for a in args if a != "--standalone"]
    if not paths:
        print(__doc__, file=sys.stderr)
        return 2
    sys.stdout.write(render(paths, standalone))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
