#!/usr/bin/env python3
"""Render docs/launcher/concepts.html: rofi launcher concepts drawn in a palette.

Usage:
    tools/launcher_preview.py [--standalone] <palette.toml> > out.html

Mockups only use effects that rofi 2.x + Hyprland layer rules can actually produce; each
concept lists how every visual element is built. Dev-only.
"""

from __future__ import annotations

import html
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from palette import apca, contrast, load  # noqa: E402
from preview import CSS as PREVIEW_CSS, FONTS, JS as COPY_JS, css_vars  # noqa: E402

# The app list from the owner's current launcher, plus Blender.
APPS = [
    ("Firefox", "Web Browser"), ("Blender", "3D Modeler"), ("Minecraft", ""),
    ("Heroic Games Launcher", ""), ("Discord", "Internet Messenger"), ("Code - OSS", "Text Editor"),
    ("Steam (Runtime)", ""), ("Inkscape", "Vector Graphics Editor"), ("Disks", ""),
    ("Disk Usage Analyzer", ""), ("Timeshift", "System Restore Utility"),
]
ICON_ROLES = ["orange", "yellow", "green", "cyan", "blue", "purple", "pink", "red"]


def hexa(hex_: str, alpha: float) -> str:
    return f"{hex_}{round(alpha * 255):02X}"


def icon(name: str, i: int) -> str:
    return f'<span class="ico" style="--ic:var(--p-{ICON_ROLES[i % len(ICON_ROLES)]})">{html.escape(name[0])}</span>'


def rows(apps: list[tuple[str, str]], selected: int, query: str = "") -> str:
    out = []
    for i, (name, generic) in enumerate(apps):
        label = html.escape(name)
        if query:
            idx = name.lower().find(query)
            if idx >= 0:
                label = (html.escape(name[:idx]) + f'<b class="hl">{html.escape(name[idx:idx + len(query)])}</b>'
                         + html.escape(name[idx + len(query):]))
        gen = f' <i class="gen">({html.escape(generic)})</i>' if generic else ""
        out.append(f'<li class="row{" sel" if i == selected else ""}">{icon(name, i)}<span>{label}{gen}</span></li>')
    return "".join(out)


def desktop(inner: str, extra_class: str = "") -> str:
    """A fake desktop behind the launcher, so translucency and blur have something to show."""
    return f"""
<div class="desk2 {extra_class}">
  <div class="fakewin fw1"><div class="fw-t">kitty</div><pre><span class="c-green">❯</span> blender --version
Blender 5.2.2
<span class="c-green">❯</span> rocminfo | grep gfx
  Name:  <span class="c-yellow">gfx1100</span>
<span class="c-green">❯</span> hyprctl monitors | grep desc
  description: <span class="c-cyan">ASUSTek ProArt PA279</span>
  description: <span class="c-cyan">ASUSTek ProArt PA279</span></pre></div>
  <div class="fakewin fw2"><div class="fw-t">nvim — binds.lua</div><pre><span class="t-com">-- launcher</span>
<span class="t-bi">hl</span>.<span class="t-fn">bind</span>(<span class="t-str">"SUPER + D"</span>,
  <span class="t-bi">hl</span>.dsp.<span class="t-fn">exec_cmd</span>(<span class="t-str">"rofi -show drun"</span>))</pre></div>
  {inner}
</div>"""


def concept_glass(d: dict) -> str:
    return desktop(f"""
  <div class="L glass">
    <div class="inp"><span class="pr">✦</span><span class="ph">Type to filter</span></div>
    <div class="rimbar"></div>
    <ul class="list">{rows(APPS[:8], 1)}</ul>
    <div class="modes"><span class="on">apps</span><span>run</span><span>windows</span></div>
  </div>""")


def concept_rim(d: dict) -> str:
    return desktop(f"""
  <div class="L rim"><div class="rim-in">
    <div class="inp"><span class="pr">✦</span><span class="q">s</span><span class="caret"></span></div>
    <ul class="list">{rows([a for a in APPS if "s" in a[0].lower()], 0, "s")}</ul>
    <div class="modes"><span class="on">apps</span><span>run</span><span>windows</span></div>
  </div></div>""")


def concept_horizon(d: dict) -> str:
    # The real menu prefixes Nerd Font glyphs; browsers lack the font, so the mock uses plain text.
    items = ["lock", "log out", "suspend", "reboot", "shut down"]
    lis = "".join(f'<li class="{"sel" if i == 0 else ""}">{html.escape(t)}</li>' for i, t in enumerate(items))
    return desktop(f"""
  <div class="L horizon">
    <span class="hz-p">power</span><span class="hz-e">❯ <span class="caret"></span></span>
    <ul class="hz-l">{lis}</ul>
  </div>""", "top")


CONCEPTS = [
    ("glass", "1 · Glass", "Frosted panel over a blurred desktop, hairline edge, nebula gradient accent bar.",
     concept_glass,
     [("Translucent body", "<code>window { background-color: base @ 78% }</code> (rasi accepts <code>#RRGGBBAA</code>)"),
      ("Blur behind it", "Hyprland <code>hl.layer_rule({ match = { namespace = \"^rofi$\" }, blur = true, ignore_alpha = 0.1 })</code>"),
      ("Hairline edge", "<code>border: 1px; border-color: bright @ 12%</code>"),
      ("Gradient accent bar", "a custom child box: <code>mainbox { children: [inputbar, rimbar, listview, mode-switcher] }</code>, "
       "<code>rimbar { padding: 1px; background-image: linear-gradient(to right, red, purple) }</code>"),
      ("Selected row", "<code>element selected</code>: translucent gradient fill + 3px left border in red"),
      ("Pop-in", "layer rule <code>animation = \"popin 92%\"</code>")],
     ["Most \"space\" when your wallpaper is a nebula: the blur shows it.",
      "Readability depends on what is behind the panel. The 78% body keeps text above contrast rules over any wallpaper; lower opacity is not safe."],
     "The gradient can only be a bar, not a full frame: in rofi a gradient frame sits behind the body, so a translucent body would show the gradient instead of the blurred desktop."),
    ("rim", "2 · Rim", "Opaque deep-space panel with a starfield, framed by a full red → purple → cyan gradient rim.",
     concept_rim,
     [("Gradient frame", "<code>window { padding: 2px; border-radius: 16px; background-image: linear-gradient(to right, red, purple, cyan) }</code>"),
      ("Opaque body inside it", "<code>mainbox { border-radius: 14px; background-color: mantle }</code>"),
      ("Starfield", "<code>mainbox { background-image: url(\"…/starfield.png\", width) }</code>: a PNG generated from the palette at install"),
      ("Match highlight", "<code>element-text { highlight: bold yellow }</code>"),
      ("Selected row", "gradient fill red → purple at 30% / 12%"),
      ("Dim the desktop (optional)", "layer rule <code>dim_around = true</code>")],
     ["Fully predictable contrast: nothing shows through.",
      "The gradient frame is the \"fancy border\" you asked for."],
     "No glow or drop shadow: neither rofi nor Hyprland layer rules draw shadows around layers. The rim and the dim are the substitutes."),
    ("horizon", "3 · Horizon line", "A full-width strip at the top edge, i3/dmenu muscle memory. For scripted menus: power, clipboard, screenshots.",
     concept_horizon,
     [("Top strip", "<code>window { location: north; anchor: north; width: 100% }</code>"),
      ("One line, horizontal", "<code>mainbox { orientation: horizontal }</code>, <code>listview { layout: horizontal }</code>"),
      ("Gradient underline", "same custom <code>rimbar</code> box as Glass, below the row"),
      ("Mono font", "<code>* { font: \"JetBrainsMono Nerd Font 11\" }</code>")],
     ["Exactly how <code>dmenu</code> felt in i3; zero visual noise.",
      "Every <code>rofi -dmenu</code> script uses this theme via <code>-theme horizon</code>."],
     "Not meant for app launching with icons; it is the companion theme for scripts."),
]


def section(slug: str, title: str, lede: str, mock, built, pros, limit, d: dict) -> str:
    trs = "".join(f"<tr><td>{k}</td><td>{v}</td></tr>" for k, v in built)
    li = "".join(f"<li>{p}</li>" for p in pros)
    return f"""
<section class="cz" id="{slug}">
  <div class="cz-in">
    <header><h2>{title}</h2><p class="tag">{lede}</p></header>
    {mock(d)}
    <div class="cz-notes">
      <div class="tbl-wrap built"><table><thead><tr><th>Element</th><th>How it is built</th></tr></thead><tbody>{trs}</tbody></table></div>
      <div class="pc"><h3>Why pick it</h3><ul>{li}</ul><h3>Limit</h3><p>{limit}</p></div>
    </div>
  </div>
</section>"""


MENUS = [
    ("Apps", "Super + D", "<code>rofi -show drun</code>", "rofi, papirus-icon-theme"),
    ("Run a command", "Super + Shift + D", "<code>rofi -show run</code>", "rofi"),
    ("Switch window", "Super + Tab", "<code>hyprctl -j clients</code> → <code>rofi -dmenu</code> → focus. rofi's own window mode on Hyprland: [TODO-verify]", "jq"),
    ("Power / session", "Super + Shift + E", "lock (<code>loginctl lock-session</code>), log out / reboot / shut down via <code>hyprshutdown</code>, suspend", "hyprshutdown"),
    ("Clipboard history", "Super + V", "<code>cliphist list | rofi -dmenu | cliphist decode | wl-copy</code>", "cliphist, wl-clipboard"),
    ("Screenshot", "Print", "region / window / monitor → clipboard, file, or annotate", "grim, slurp, satty [TODO-verify]"),
    ("Emoji & glyphs", "Super + period", "rofi-emoji plugin if packaged, else a bundled list → <code>wl-copy</code>", "[TODO-verify]"),
    ("Calculator", "Super + equal", "rofi-calc plugin if packaged, else <code>qalc</code> in a dmenu loop", "libqalculate [TODO-verify]"),
    ("Monitors (KVM)", "Super + Shift + M", "send workspaces home, reload monitor layout, toggle 10-bit", "hyprctl"),
    ("Keybind cheat sheet", "Super + F1", "<code>hyprctl -j binds</code> → readable list in rofi", "jq"),
]


def menus() -> str:
    trs = "".join(f"<tr><td>{a}</td><td><kbd>{b}</kbd></td><td>{c}</td><td class='dim'>{d}</td></tr>" for a, b, c, d in MENUS)
    return f"""
<div class="wrap">
  <h2 class="h2f">Menus built on it</h2>
  <p class="lede">One engine (rofi) for everything; i3-style default keys. Each scripted menu is a small bash script that pipes into
  <code>rofi -dmenu</code>, so anything you wrote for dmenu in i3 keeps working.</p>
  <div class="tbl-wrap"><table class="sum"><thead><tr><th>Menu</th><th>Key</th><th>How</th><th>Packages</th></tr></thead><tbody>{trs}</tbody></table></div>
</div>"""


CSS = """
.cz{background:var(--p-base);color:var(--p-text);border-top:1px solid var(--p-surface2)}
.cz-in{max-width:1180px;margin:0 auto;padding-block:36px 40px;display:grid;gap:20px;
  padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px))}
.cz h2,.h2f{font-family:var(--f-display);font-weight:600;font-size:clamp(22px,3vw,30px);margin:0;color:var(--p-bright,var(--frame-fg))}
.h2f{margin-bottom:6px}
.desk2{position:relative;min-height:540px;border-radius:12px;overflow:hidden;border:1px solid var(--p-surface0);
  background:
    radial-gradient(1px 1px at 12% 30%,var(--p-subtext),transparent 60%),
    radial-gradient(1px 1px at 68% 18%,var(--p-overlay),transparent 60%),
    radial-gradient(1.5px 1.5px at 84% 64%,var(--p-subtext),transparent 60%),
    radial-gradient(1px 1px at 33% 82%,var(--p-overlay),transparent 60%),
    radial-gradient(70% 60% at 80% 85%,color-mix(in srgb,var(--p-purple) 22%,transparent),transparent 70%),
    radial-gradient(60% 50% at 10% 10%,color-mix(in srgb,var(--p-red) 14%,transparent),transparent 70%),
    var(--p-crust)}
.fakewin{position:absolute;border-radius:10px;border:2px solid var(--p-surface1);background:var(--p-base);overflow:hidden}
.fakewin pre{margin:0;padding:10px 12px;font:12.5px/1.6 var(--f-mono);color:var(--p-text);white-space:pre}
.fw-t{font:11px var(--f-mono);color:var(--p-overlay);padding:5px 10px;background:var(--p-mantle)}
.fw1{left:3%;top:6%;width:52%;height:58%}
.fw2{right:3%;bottom:6%;width:46%;height:42%}
.L{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);width:min(92%,560px);font:14px/1.4 var(--f-mono);color:var(--p-text)}
.inp{display:flex;align-items:center;gap:12px;padding:14px 16px;font-size:15px}
.pr{color:var(--p-red);font-size:16px}
.ph{color:var(--p-overlay)}
.q{color:var(--p-bright)}
.caret{display:inline-block;width:8px;height:1.1em;background:var(--p-cursor);vertical-align:-3px}
.list{list-style:none;margin:0;padding:6px 8px}
.row{display:flex;align-items:center;gap:12px;padding:7px 10px;border-radius:8px;border-left:3px solid transparent;white-space:nowrap;overflow:hidden}
.row span:last-child{overflow:hidden;text-overflow:ellipsis}
.row.sel{border-left-color:var(--p-red);color:var(--p-bright);
  background:linear-gradient(to right,color-mix(in srgb,var(--p-red) 28%,transparent),color-mix(in srgb,var(--p-purple) 12%,transparent))}
.gen{color:var(--p-overlay);font-size:.9em}
.hl{color:var(--p-yellow);font-weight:700}
.ico{flex:none;display:grid;place-items:center;width:22px;height:22px;border-radius:6px;font:700 12px var(--f-body);
  color:var(--p-crust);background:var(--ic)}
.modes{display:flex;gap:6px;padding:8px 16px 14px;font-size:12px}
.modes span{padding:3px 10px;border-radius:999px;color:var(--p-subtext);border:1px solid var(--p-surface2)}
.modes .on{color:var(--p-crust);background:var(--p-red);border-color:var(--p-red);font-weight:700}

.glass{border-radius:14px;border:1px solid color-mix(in srgb,var(--p-bright) 12%,transparent);
  background:color-mix(in srgb,var(--p-base) 78%,transparent);backdrop-filter:blur(18px) saturate(1.1);-webkit-backdrop-filter:blur(18px) saturate(1.1)}
.rimbar{height:2px;margin:0 16px;background:linear-gradient(to right,var(--p-red),var(--p-purple))}

.rim{border-radius:16px;padding:2px;background:linear-gradient(to right,var(--p-red),var(--p-purple),var(--p-cyan))}
.rim-in{border-radius:14px;background:
  radial-gradient(1px 1px at 18% 22%,var(--p-subtext),transparent 60%),
  radial-gradient(1px 1px at 72% 12%,var(--p-overlay),transparent 60%),
  radial-gradient(1.5px 1.5px at 88% 58%,var(--p-subtext),transparent 60%),
  radial-gradient(1px 1px at 40% 78%,var(--p-overlay),transparent 60%),
  radial-gradient(1px 1px at 8% 64%,var(--p-overlay),transparent 60%),
  radial-gradient(1px 1px at 58% 40%,var(--p-overlay),transparent 60%),
  radial-gradient(90% 70% at 100% 100%,color-mix(in srgb,var(--p-purple) 16%,transparent),transparent 70%),
  var(--p-mantle)}
.rim .inp{border-bottom:1px solid var(--p-surface1)}

.top .L.horizon{top:0;left:0;transform:none;width:100%;display:flex;align-items:center;gap:14px;padding:8px 14px;
  background:var(--p-crust);border-bottom:2px solid transparent;
  border-image:linear-gradient(to right,var(--p-red),var(--p-purple)) 1;flex-wrap:wrap}
.top .fw1{top:16%}
.hz-p{color:var(--p-crust);background:var(--p-red);padding:2px 10px;border-radius:4px;font-weight:700}
.hz-e{color:var(--p-subtext);min-width:4ch}
.hz-l{list-style:none;margin:0;padding:0;display:flex;gap:6px;flex-wrap:wrap}
.hz-l li{padding:2px 10px;border-radius:4px;color:var(--p-subtext)}
.hz-l li.sel{color:var(--p-bright);background:color-mix(in srgb,var(--p-red) 26%,transparent);box-shadow:inset 0 -2px 0 var(--p-red)}

.cz-notes{display:grid;grid-template-columns:minmax(0,1.6fr) minmax(0,1fr);gap:18px;align-items:start}
@media (max-width:820px){.cz-notes{grid-template-columns:1fr}.fw2{display:none}.fw1{width:90%}}
.built table{border-collapse:collapse;width:100%;font-size:13.5px}
.built th,.built td{padding:8px 12px;text-align:left;border-bottom:1px solid var(--p-surface1);vertical-align:top}
.built th{font-weight:500;color:var(--p-subtext);font-size:12px;text-transform:uppercase;letter-spacing:.06em}
.built td:first-child{white-space:nowrap;color:var(--p-text)}
.built td{color:var(--p-subtext)}
.built code,.pc code{color:var(--p-text)}
.built{border-color:var(--p-surface1)}
.pc h3{font-size:12px;font-weight:500;text-transform:uppercase;letter-spacing:.08em;color:var(--p-subtext);margin:0 0 6px}
.pc ul{margin:0 0 14px;padding-left:18px;color:var(--p-text);font-size:14px}
.pc p{margin:0;color:var(--p-subtext);font-size:14px}
.note{max-width:75ch;color:var(--frame-dim);font-size:14px}
"""


def render(path: Path, standalone: bool) -> str:
    d = load(path)
    b, a = d["base"], d["accent"]
    # Facts quoted in the lede, computed rather than hand-typed.
    glass_text = contrast(b["text"], b["base"])
    pill = contrast(b["crust"], a["red"])
    secs = "".join(section(*c, d) for c in CONCEPTS)
    body = f"""<title>Launcher Concepts</title>
<meta name="claude:viewport-fit-sides" content="cover">
{FONTS}
<style>{PREVIEW_CSS}{CSS}</style>
<div class="wrap">
  <h1>Launcher Concepts</h1>
  <p class="lede">Your screenshot is <strong>rofi</strong>: "Type to filter" and the italic "(Web Browser)" generic names are its
  defaults. Rofi 2.0 (September 2025) merged the Wayland port, so the same tool and the same <code>rofi -dmenu</code>
  scripts you used under i3 run natively on Hyprland. Three directions below, drawn in the <strong>{html.escape(d['meta']['name'])}</strong>
  palette. Each one uses only effects rofi and Hyprland can render; the table under each mock says how.</p>
  <p class="note">Glass and Rim are for apps; Horizon line is the companion theme for scripted menus. A typical pick is
  one of the first two plus Horizon. Contrast check: body text {glass_text:.1f}:1 / Lc {apca(b['text'], b['base']):.0f} on the panel;
  dark text on the red mode pill {pill:.1f}:1.</p>
</div>
{secs}
{menus()}
<div class="wrap"><p class="foot">Generated by <code>tools/launcher_preview.py</code> from <code>{html.escape(str(path))}</code>.
Icons are placeholders for your icon theme (Papirus-Dark proposed); prompt and menu glyphs will come from the Nerd Font.</p></div>
<script>{COPY_JS}</script>
"""
    wrapped = f'<div style="{css_vars(d)}">{body}</div>'
    if not standalone:
        return wrapped
    return ('<!doctype html>\n<html lang="en"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">'
            '<style>body{margin:0}</style>\n'
            f'</head><body>\n{wrapped}</body></html>\n')


def main(argv: list[str]) -> int:
    args = argv[1:]
    standalone = "--standalone" in args
    paths = [Path(x) for x in args if x != "--standalone"]
    if len(paths) != 1:
        print(__doc__, file=sys.stderr)
        return 2
    sys.stdout.write(render(paths[0], standalone))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
