#!/usr/bin/env python3
"""Render docs/launcher/concepts.html: six launcher concepts drawn in a palette.

Usage:
    tools/launcher_preview.py [--standalone] <palette.toml> > out.html

Space art (wallpaper, panel starfield, planet) comes from tools/spacegen.py, so the mocks show
the generator's real output. Each concept states its engine and how every element is built;
nothing is drawn that the named engine cannot render. Dev-only.
"""

from __future__ import annotations

import base64
import html
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import spacegen  # noqa: E402
from palette import apca, contrast, load  # noqa: E402
from preview import CSS as PREVIEW_CSS, JS as COPY_JS, css_vars  # noqa: E402

FONTS = ('<link rel="preconnect" href="https://fonts.googleapis.com">'
         '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>'
         '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600'
         '&family=JetBrains+Mono:ital,wght@0,400;0,700;1,400&family=Unbounded:wght@600&family=VT323&display=swap">')

# (name, description from the app's .desktop Comment, generic name)
APPS = [
    ("Firefox", "Browse the World Wide Web", "Web Browser"),
    ("Blender", "3D modeling, animation, rendering and post-production", "3D Modeler"),
    ("Steam", "Manage and play games on Steam", "Game Launcher"),
    ("Discord", "All-in-one voice and text chat", "Internet Messenger"),
    ("Code - OSS", "Code editing. Redefined.", "Text Editor"),
    ("Inkscape", "Create and edit Scalable Vector Graphics images", "Vector Graphics Editor"),
    ("Heroic Games Launcher", "Open source GOG and Epic Games launcher", "Game Launcher"),
    ("Timeshift", "System restore utility", "System Restore"),
]
ICON_ROLES = ["orange", "yellow", "blue", "purple", "cyan", "pink", "green", "red"]


def data_uri(svg: str) -> str:
    return "data:image/svg+xml;base64," + base64.b64encode(svg.encode()).decode()


def ico(name: str, i: int, size: int = 26) -> str:
    return (f'<span class="ico" style="--ic:var(--p-{ICON_ROLES[i % 8]});--sz:{size}px">'
            f'{html.escape(name[0])}</span>')


def hot(name: str) -> str:
    """Retro accelerator: first letter marked."""
    return f'<span class="hk">{html.escape(name[0])}</span>{html.escape(name[1:])}'


# ------------------------------------------------------------------ mocks

def desk(inner: str, art: dict, window: bool = True) -> str:
    win = """<div class="fakewin"><div class="fw-t">kitty</div><pre><span class="c-green">❯</span> rocminfo | grep gfx
  Name:  <span class="c-yellow">gfx1100</span>
<span class="c-green">❯</span> hyprctl monitors | grep desc
  description: <span class="c-cyan">ASUSTek ProArt</span>
  description: <span class="c-cyan">ASUSTek ProArt</span></pre></div>""" if window else ""
    return f'<div class="desk3">{win}{inner}</div>'


def two_line(apps, sel: int, size: int = 26, sep: bool = False) -> str:
    out = []
    for i, (n, d, _) in enumerate(apps):
        out.append(f'<li class="r2{" sel" if i == sel else ""}{" sep" if sep else ""}">{ico(n, i, size)}'
                   f'<span class="r2t"><b>{html.escape(n)}</b><small>{html.escape(d)}</small></span></li>')
    return "".join(out)


def m_halo(art):
    return desk(f"""
<div class="P halo"><div class="halo-in">
  <div class="srch"><span class="pr">✦</span><span class="ph">Search apps</span></div>
  <ul class="lst">{two_line(APPS[:6], 1)}</ul>
  <div class="pills"><span class="on">apps</span><span>run</span><span>windows</span></div>
</div></div>""", art)


def m_orbit(art):
    return desk(f"""
<div class="P orbit">
  <div class="orb-head"><div class="pill-in"><span class="mag">⌕</span><span class="q">bl</span><span class="caret"></span></div>
    <img class="orb-planet" src="{art['planet']}" alt=""></div>
  <div class="chips"><span class="on">All</span><span>Games</span><span>Graphics</span><span>Development</span></div>
  <ul class="lst">{two_line([APPS[1], APPS[5], APPS[0], APPS[2], APPS[4]], 0, 34, sep=True)}</ul>
</div>""", art)


def m_mission(art):
    toggles = [("Wi-Fi", "Connected", True), ("Bluetooth", "Off", False), ("Do not disturb", "Off", False), ("Power", "Balanced", True)]
    tg = "".join(f'<div class="tg{" on" if on else ""}"><b>{a}</b><small>{b}</small></div>' for a, b, on in toggles)
    return desk(f"""
<div class="P mission">
  <div class="mc-l">
    <div class="pill-in"><span class="mag">⌕</span><span class="ph">Search</span></div>
    <ul class="lst">{two_line(APPS[:5], 0, 28)}</ul>
  </div>
  <div class="mc-r">
    <div class="mc-top"><span class="av"></span><span class="up">uptime 3:26</span><span class="btn">⏻</span></div>
    <div class="sl"><span>VOL</span><i style="--v:45%"></i></div>
    <div class="sl"><span>BRI</span><i style="--v:70%"></i></div>
    <div class="tgs">{tg}</div>
    <div class="media"><img src="{art['planet']}" alt=""><div><b>Now playing</b><small>Artist name</small><i style="--v:38%"></i></div></div>
  </div>
</div>""", art, window=False)


def m_vision(art):
    lis = "".join(f'<li class="{"sel" if i == 0 else ""}">{ico(n, i, 14)}<span class="vn">{hot(n)}</span><span class="vg">{html.escape(g)}</span></li>'
                  for i, (n, _, g) in enumerate(APPS[:6]))
    return desk(f"""
<div class="P vision"><div class="v-shadow"></div><div class="v-body">
  <div class="v-title">Launcher</div>
  <div class="v-box v-in">&gt; <span class="caret"></span></div>
  <div class="v-box"><ul class="v-l">{lis}
    <li class="v-sec">*** Quick settings ***</li>
    <li><span class="chk">[ ]</span><span class="vn">{hot("Do not disturb")}</span></li>
    <li><span class="chk"></span><span class="vn">{hot("Clipboard history")}</span><span class="vg">---&gt;</span></li>
    <li><span class="chk"></span><span class="vn">{hot("Session")}</span><span class="vg">---&gt;</span></li>
  </ul></div>
  <div class="v-btns"><span class="b on">&lt;<span class="hk">S</span>elect&gt;</span><span class="b">&lt; <span class="hk">E</span>xit &gt;</span></div>
</div></div>""", art)


def m_deck(art):
    lis = "".join(f'<li class="{"sel" if i == 1 else ""}">{ico(n, i, 16)}<span class="vn">{html.escape(n)}</span><span class="vg">{html.escape(g)}</span></li>'
                  for i, (n, _, g) in enumerate(APPS[:5]))
    return desk(f"""
<div class="P deck"><div class="d-shadow"></div><div class="d-frame"><div class="d-body">
  <div class="d-tabs"><span class="d-tag">◢ LAUNCH</span><span class="on">apps</span><span>run</span><span>windows</span><span>session ▸</span></div>
  <div class="d-in"><span class="pr">❯</span> <span class="q">b</span><span class="caret"></span></div>
  <ul class="d-l">{lis}
    <li class="d-sec">── quick ──────────────</li>
    <li><span class="sw on"></span><span class="vn">night light</span><span class="vg">hyprsunset</span></li>
    <li><span class="sw"></span><span class="vn">do not disturb</span><span class="vg">mako</span></li>
  </ul>
  <div class="d-foot"><span>↵ launch</span><span>⇥ mode</span><span>esc abort</span><span class="t">T+ 03:26:16</span></div>
</div></div></div>""", art)


def m_waypoint(art):
    return desk(f"""
<div class="P halo waypoint"><div class="halo-in">
  <div class="srch"><span class="pr">✦</span><span class="ph">Search apps, settings, session</span></div>
  <ul class="lst">{two_line(APPS[:4], 0, 28)}
    <li class="w-sec">Quick settings</li>
    <li class="w-row"><span class="tsw on"></span><span><span class="ul">N</span>ight light</span><span class="st">on</span></li>
    <li class="w-row"><span class="tsw"></span><span><span class="ul">D</span>o not disturb</span><span class="st">off</span></li>
    <li class="w-row"><span class="ico-g">⧉</span><span><span class="ul">C</span>lipboard history</span><span class="st">▸</span></li>
    <li class="w-row"><span class="ico-g">⏻</span><span><span class="ul">S</span>ession</span><span class="st">▸</span></li>
  </ul>
  <div class="keys"><kbd>Enter</kbd> open <kbd>Tab</kbd> next mode <kbd>Alt</kbd>+<span class="ul">letter</span> jump <kbd>Esc</kbd> close</div>
</div></div>""", art)


# ------------------------------------------------------------------ concept metadata

ROFI = "rofi"
ROFI_SCRIPT = "rofi + script mode"
QS = "Quickshell"

CONCEPTS = [
    dict(slug="halo", n=1, name="Halo", retro=0, engine=ROFI, mock=m_halo,
         lede="Your Rim pick, now with icons and a description line per app, over a generated starfield.",
         takes=["Rim", "Globes: icons + descriptions", "generator"],
         built=[("Gradient frame", "<code>window</code> gradient + 2px padding, opaque <code>mainbox</code> inside"),
                ("Starfield", "<code>mainbox { background-image: url(\"starfield.png\", width) }</code> from <code>spacegen.py</code>"),
                ("Icon + two lines", "<code>show-icons: true</code>, <code>element-icon { size: 1.8em }</code>, "
                 "<code>drun-display-format</code> with <code>{name}</code> and <code>{comment}</code> on two lines (markup rows)"),
                ("Selected row", "gradient fill + 3px left border")],
         limit="No translucency: in rofi a gradient frame and a see-through body are mutually exclusive."),
    dict(slug="orbit", n=2, name="Orbit", retro=0, engine=ROFI, mock=m_orbit,
         lede="Globes-style: frosted panel, search pill, large icons, separators, a generated ringed planet in the header.",
         takes=["Globes", "Glass", "generator"],
         built=[("Frosted body", "translucent <code>window</code> + Hyprland layer rule <code>blur</code> with <code>ignore_alpha</code>"),
                ("Planet", "a custom <code>icon-planet { filename: \"…/planet.svg\"; size: 64 }</code> widget in the input row"),
                ("Category chips", "one rofi mode per category (<code>-drun-categories</code>), shown by <code>mode-switcher</code>"),
                ("Separators", "<code>element { border: 0 0 1px 0 }</code>")],
         limit="Chips switch modes rather than filtering live. Readability over a busy wallpaper relies on the 78% opaque body."),
    dict(slug="mission", n=3, name="Mission Control", retro=0, engine=QS, mock=m_mission,
         lede="Launcher and quick settings in one panel: sliders, toggles, media. The Globes side panel merged with the launcher.",
         takes=["Globes: quick settings", "Halo rows", "generator"],
         built=[("Everything", "QML: a layer-shell window, desktop-entry search, PipeWire and MPRIS services for volume and media"),
                ("Blur, animation", "Hyprland layer rules on the Quickshell namespace; QML animations inside the panel"),
                ("Shared code", "the same QML components would draw the bar, so launcher and bar match exactly")],
         limit="Not possible in rofi (no sliders, no live widgets). Choosing it commits the launcher to Quickshell, which is the bar decision (O3)."),
    dict(slug="vision", n=4, name="Terminal Vision", retro=3, engine=QS + " (exact) or rofi (approx.)", mock=m_vision,
         lede="Your retro TUI menu, recolored to Quasar: title in the frame, double frame, hard offset shadow, hotkey letters, quick settings and submenus in the list.",
         takes=["retro TUI", "small icons"],
         built=[("Title in the frame", "Quickshell: trivial. rofi: borders cannot carry text, so the title sits on a strip above the frame"),
                ("Double frame", "rofi: two nested boxes with 1px borders (rofi has only solid and dash border styles)"),
                ("Hard shadow", "rofi: nested boxes offset 8px [TODO-verify render]; Quickshell: a rectangle"),
                ("Hotkey letters", "Pango markup per row; real single-key accelerators need Quickshell or <code>kb-custom-*</code> binds"),
                ("Quick settings, submenus", "script-mode rows: <code>nonselectable</code> header; toggles re-open the menu; <code>---&gt;</code> opens a sub-menu")],
         limit="Faithful only in Quickshell. In rofi, typing filters the list, so hotkey letters are hints, not instant keys."),
    dict(slug="deck", n=5, name="Flight Deck", retro=2, engine=ROFI_SCRIPT, mock=m_deck,
         lede="Retro structure as a spaceship console: mono font, tab row, section rules, key-hint status line, purple hard shadow, starfield behind the list.",
         takes=["retro TUI", "Rim frame", "generator"],
         built=[("Gradient frame + starfield", "as Halo, with a 4px radius"),
                ("Tab row", "<code>mode-switcher</code> styled as tabs; <code>session ▸</code> is a script mode"),
                ("Quick toggles", "script-mode rows with switch glyphs; state read from <code>makoctl</code> / <code>hyprsunset</code> when the menu opens"),
                ("Status line", "custom <code>textbox-hints</code> widget with static key hints")],
         limit="The T+ uptime readout is static text in rofi (no live updates); the hard shadow carries the same [TODO-verify] as Terminal Vision."),
    dict(slug="waypoint", n=6, name="Waypoint", retro=1, engine=ROFI_SCRIPT, mock=m_waypoint,
         lede="The middle ground: Halo's card and icons, plus the retro menu's best ideas: quick settings and submenus in the list, underlined jump letters, key hints.",
         takes=["Halo", "retro: quick settings, submenus, hotkeys", "Globes rows"],
         built=[("Card, icons, rows", "as Halo"),
                ("One combined list", "<code>combi</code> mode: drun + a script mode that provides the quick-settings rows"),
                ("Section header", "<code>nonselectable</code> script row"),
                ("Jump letters", "markup underline + <code>kb-custom-N</code> bound to Alt+letter in the script"),
                ("Key hints", "custom <code>textbox-hints</code> widget")],
         limit="Toggle rows show the state at open time; they refresh by re-opening the menu."),
]

FEATURES = [("Icons", lambda c: True),
            ("Descriptions", lambda c: c["slug"] in {"halo", "orbit", "mission", "waypoint"}),
            ("Quick settings", lambda c: c["slug"] in {"mission", "vision", "deck", "waypoint"}),
            ("Submenus", lambda c: c["slug"] in {"vision", "deck", "waypoint"}),
            ("Generated art", lambda c: c["slug"] in {"halo", "orbit", "mission", "deck", "waypoint"}),
            ("Translucent", lambda c: c["slug"] in {"orbit", "mission"})]


def matrix() -> str:
    head = "".join(f'<th class="mk">{f}</th>' for f, _ in FEATURES)
    trs = []
    for c in CONCEPTS:
        cells = "".join(f'<td class="mk">{"●" if fn(c) else "·"}</td>' for _, fn in FEATURES)
        retro = ["none", "light", "medium", "strong"][c["retro"]]
        trs.append(f'<tr><td><a href="#{c["slug"]}">{c["n"]} · {c["name"]}</a></td><td class="dim">{retro}</td>{cells}'
                   f'<td>{c["engine"]}</td></tr>')
    return (f'<div class="tbl-wrap"><table class="sum"><thead><tr><th>Concept</th><th>Retro</th>{head}<th>Engine</th></tr>'
            f'</thead><tbody>{"".join(trs)}</tbody></table></div>')


def section(c: dict, art: dict) -> str:
    trs = "".join(f"<tr><td>{k}</td><td>{v}</td></tr>" for k, v in c["built"])
    takes = "".join(f"<span>{t}</span>" for t in c["takes"])
    return f"""
<section class="cz" id="{c['slug']}">
  <div class="cz-in">
    <header class="cz-h"><div><h2>{c['n']} · {c['name']}</h2><p class="tag">{c['lede']}</p></div>
      <div class="badges"><span class="eng">{c['engine']}</span><span class="takes">{takes}</span></div></header>
    {c['mock'](art)}
    <div class="cz-notes">
      <div class="tbl-wrap built"><table><thead><tr><th>Element</th><th>How it is built</th></tr></thead><tbody>{trs}</tbody></table></div>
      <div class="pc"><h3>Limit</h3><p>{c['limit']}</p></div>
    </div>
  </div>
</section>"""


CSS = """
.cz{background:var(--p-base);color:var(--p-text);border-top:1px solid var(--p-surface2)}
.cz-in{max-width:1180px;margin:0 auto;padding-block:36px 40px;display:grid;gap:18px;
  padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px))}
.cz h2{font-family:var(--f-display);font-weight:600;font-size:clamp(22px,3vw,30px);margin:0;color:var(--p-bright)}
.cz-h{display:flex;flex-wrap:wrap;gap:12px 24px;justify-content:space-between;align-items:flex-end}
.badges{display:flex;flex-direction:column;gap:6px;align-items:flex-end}
.eng{font:600 12px var(--f-mono);padding:4px 10px;border-radius:999px;background:var(--p-surface1);color:var(--p-yellow)}
.takes{display:flex;flex-wrap:wrap;gap:4px;justify-content:flex-end}
.takes span{font-size:11.5px;padding:2px 8px;border-radius:999px;border:1px solid var(--p-surface2);color:var(--p-subtext)}
.sum .mk{text-align:center;color:var(--frame-accent)}
.desk3{position:relative;min-height:560px;border-radius:12px;overflow:hidden;border:1px solid var(--p-surface0);
  background:var(--wall) center / cover,var(--p-crust)}
.fakewin{position:absolute;left:3%;top:7%;width:44%;border-radius:10px;border:2px solid var(--p-surface1);background:var(--p-base);overflow:hidden}
.fakewin pre{margin:0;padding:10px 12px;font:12.5px/1.6 var(--f-mono);color:var(--p-text);white-space:pre;overflow:hidden}
.fw-t{font:11px var(--f-mono);color:var(--p-overlay);padding:5px 10px;background:var(--p-mantle)}
.P{position:absolute;left:50%;top:50%;transform:translate(-50%,-50%);width:min(94%,600px);font:14px/1.4 var(--f-mono);color:var(--p-text)}
.ico{flex:none;display:grid;place-items:center;width:var(--sz);height:var(--sz);border-radius:calc(var(--sz) * .26);
  font:700 calc(var(--sz) * .5) var(--f-body);color:var(--p-crust);
  background:linear-gradient(145deg,color-mix(in srgb,var(--ic) 80%,white),var(--ic) 55%,color-mix(in srgb,var(--ic) 70%,black))}
.lst{list-style:none;margin:0;padding:6px 8px}
.r2{display:flex;align-items:center;gap:12px;padding:7px 10px;border-radius:8px;border-left:3px solid transparent;min-width:0}
.r2t{display:grid;min-width:0}
.r2t b{font-weight:600;color:var(--p-text);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.r2t small{color:var(--p-overlay);font-size:12px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.r2.sel{border-left-color:var(--p-red);background:linear-gradient(to right,color-mix(in srgb,var(--p-red) 28%,transparent),color-mix(in srgb,var(--p-purple) 12%,transparent))}
.r2.sel b{color:var(--p-bright)} .r2.sel small{color:var(--p-subtext)}
.r2.sep{border-radius:0;border-bottom:1px solid var(--p-surface1)}
.r2.sep.sel{border-radius:8px}
.srch{display:flex;gap:12px;align-items:center;padding:14px 18px;border-bottom:1px solid var(--p-surface1);font-size:15px}
.pr{color:var(--p-red)} .ph{color:var(--p-overlay)} .q{color:var(--p-bright)}
.caret{display:inline-block;width:8px;height:1.1em;background:var(--p-cursor);vertical-align:-3px}
.pills{display:flex;gap:6px;padding:6px 18px 14px;font-size:12px}
.pills span,.chips span{padding:3px 10px;border-radius:999px;color:var(--p-subtext);border:1px solid var(--p-surface2)}
.pills .on,.chips .on{color:var(--p-crust);background:var(--p-red);border-color:var(--p-red);font-weight:700}

.halo{border-radius:16px;padding:2px;background:linear-gradient(to right,var(--p-red),var(--p-purple),var(--p-cyan))}
.halo-in{border-radius:14px;background:var(--stars) center / cover,var(--p-mantle)}

.orbit{border-radius:18px;border:1px solid color-mix(in srgb,var(--p-bright) 12%,transparent);
  background:color-mix(in srgb,var(--p-base) 78%,transparent);backdrop-filter:blur(20px);-webkit-backdrop-filter:blur(20px);font-family:var(--f-body)}
.orb-head{display:flex;align-items:center;gap:10px;padding:14px 16px 6px}
.pill-in{flex:1;display:flex;gap:10px;align-items:center;padding:9px 14px;border-radius:999px;background:color-mix(in srgb,var(--p-crust) 70%,transparent);font-family:var(--f-mono)}
.mag{color:var(--p-subtext);font-size:17px}
.orb-planet{width:64px;height:64px;flex:none}
.chips{display:flex;flex-wrap:wrap;gap:6px;padding:4px 16px 8px;font-size:12px}

.mission{display:grid;grid-template-columns:1.25fr 1fr;gap:12px;width:min(94%,820px);font-family:var(--f-body)}
.mission>div{border-radius:16px;border:1px solid color-mix(in srgb,var(--p-bright) 12%,transparent);
  background:color-mix(in srgb,var(--p-base) 80%,transparent);backdrop-filter:blur(20px);-webkit-backdrop-filter:blur(20px);padding:12px;min-width:0}
.mc-l .pill-in{margin:2px 2px 6px}
.mc-r{display:grid;gap:10px;align-content:start}
.mc-top{display:flex;align-items:center;gap:8px}
.av{width:34px;height:34px;border-radius:10px;background:linear-gradient(135deg,var(--p-purple),var(--p-red))}
.up{flex:1;font-size:13px;color:var(--p-subtext)}
.btn{display:grid;place-items:center;width:30px;height:30px;border-radius:8px;background:var(--p-surface1);color:var(--p-red)}
.sl{display:flex;align-items:center;gap:8px;font:600 11px var(--f-mono);color:var(--p-subtext)}
.sl i{flex:1;height:8px;border-radius:99px;background:linear-gradient(to right,var(--p-purple) var(--v),var(--p-surface1) var(--v))}
.tgs{display:grid;grid-template-columns:1fr 1fr;gap:6px}
.tg{display:grid;padding:7px 10px;border-radius:10px;background:var(--p-surface0);font-size:12px}
.tg small{color:var(--p-overlay)}
.tg.on{background:color-mix(in srgb,var(--p-purple) 32%,var(--p-surface0))} .tg.on small{color:var(--p-subtext)}
.media{display:flex;gap:10px;align-items:center;padding:8px;border-radius:10px;background:var(--p-surface0);font-size:12px}
.media img{width:52px;height:52px;border-radius:8px;background:var(--p-crust)}
.media div{display:grid;flex:1;gap:3px} .media small{color:var(--p-overlay)}
.media i{height:4px;border-radius:9px;background:linear-gradient(to right,var(--p-text) var(--v),var(--p-surface2) var(--v))}

.vision{font:22px/1 "VT323",var(--f-mono);width:min(94%,560px)}
.v-shadow{position:absolute;inset:0;transform:translate(10px,10px);background:var(--p-crust)}
.v-body{position:relative;background:var(--p-mantle);border:2px solid var(--p-subtext);outline:1px solid var(--p-subtext);outline-offset:-6px;padding:18px 16px 12px}
.v-title{position:absolute;top:-12px;left:50%;transform:translateX(-50%);background:var(--p-mantle);color:var(--p-yellow);padding:0 8px}
.v-box{border:1px solid var(--p-surface2);margin-top:8px;padding:6px 10px}
.v-in{color:var(--p-cyan)}
.v-l{list-style:none;margin:0;padding:0}
.v-l li{display:flex;align-items:center;gap:8px;padding:1px 6px;min-width:0}
.v-l li.sel{background:var(--p-purple);color:var(--p-crust)}
.v-l li.sel .hk{color:var(--p-crust);text-decoration:underline}
.vn{flex:1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.vg{color:var(--p-overlay);white-space:nowrap}
.v-l li.sel .vg{color:var(--p-mantle)}
.v-sec{justify-content:center;color:var(--p-subtext);margin-top:6px}
.chk{flex:none;width:3ch;white-space:nowrap;color:var(--p-subtext)}
.hk{color:var(--p-red)}
.v-btns{display:flex;justify-content:center;gap:24px;margin-top:10px}
.b.on{background:var(--p-purple);color:var(--p-crust)} .b.on .hk{color:var(--p-crust);text-decoration:underline}
.vision .ico{border-radius:2px;font-size:10px}

.deck{width:min(94%,600px);font-size:13.5px}
.d-shadow{position:absolute;inset:0;transform:translate(9px,9px);background:color-mix(in srgb,var(--p-purple) 35%,var(--p-crust));border-radius:4px}
.d-frame{position:relative;padding:2px;border-radius:4px;background:linear-gradient(to right,var(--p-red),var(--p-purple))}
.d-body{border-radius:3px;background:var(--stars) center / cover,var(--p-mantle)}
.d-tabs{display:flex;flex-wrap:wrap;gap:2px;padding:8px 10px 0;border-bottom:1px solid var(--p-surface2)}
.d-tabs span{padding:3px 10px;color:var(--p-subtext);border:1px solid transparent;border-bottom:0}
.d-tabs .on{color:var(--p-bright);border-color:var(--p-surface2);background:var(--p-base)}
.d-tabs .d-tag{color:var(--p-crust);background:var(--p-red);font-weight:700;margin-right:6px}
.d-in{padding:10px 14px;color:var(--p-subtext)}
.d-l{list-style:none;margin:0;padding:0 8px 6px}
.d-l li{display:flex;align-items:center;gap:10px;padding:4px 8px;min-width:0}
.d-l li.sel{background:color-mix(in srgb,var(--p-purple) 30%,transparent);box-shadow:inset 3px 0 0 var(--p-red);color:var(--p-bright)}
.d-sec{color:var(--p-overlay);padding-top:8px!important}
.sw{width:22px;height:12px;border-radius:9px;background:var(--p-surface2);position:relative;flex:none}
.sw::after{content:"";position:absolute;top:2px;left:2px;width:8px;height:8px;border-radius:50%;background:var(--p-subtext)}
.sw.on{background:var(--p-green)} .sw.on::after{left:12px;background:var(--p-crust)}
.d-foot{display:flex;flex-wrap:wrap;gap:16px;padding:7px 14px;border-top:1px solid var(--p-surface2);font-size:12px;color:var(--p-overlay)}
.d-foot .t{margin-left:auto;color:var(--p-cyan)}

.waypoint .w-sec{list-style:none;padding:12px 10px 4px;font:600 11px var(--f-body);letter-spacing:.1em;text-transform:uppercase;color:var(--p-overlay)}
.w-row{display:flex;align-items:center;gap:12px;padding:6px 10px;border-left:3px solid transparent}
.w-row>span:nth-child(2){flex:1}
.st{color:var(--p-overlay)}
.ul{text-decoration:underline;text-decoration-color:var(--p-red);text-underline-offset:3px;text-decoration-thickness:2px}
.tsw{width:28px;height:16px;border-radius:9px;background:var(--p-surface2);position:relative;flex:none}
.tsw::after{content:"";position:absolute;top:3px;left:3px;width:10px;height:10px;border-radius:50%;background:var(--p-subtext)}
.tsw.on{background:linear-gradient(to right,var(--p-red),var(--p-purple))} .tsw.on::after{left:15px;background:var(--p-bright)}
.ico-g{width:28px;text-align:center;color:var(--p-cyan);font-size:16px}
.keys{display:flex;flex-wrap:wrap;gap:6px 8px;align-items:center;padding:8px 18px 14px;font-size:12px;color:var(--p-overlay);border-top:1px solid var(--p-surface1)}

.cz-notes{display:grid;grid-template-columns:minmax(0,1.7fr) minmax(0,1fr);gap:18px;align-items:start}
@media (max-width:860px){.cz-notes{grid-template-columns:1fr}.fakewin{display:none}.mission{grid-template-columns:1fr}.mc-r{display:none}}
.built table{border-collapse:collapse;width:100%;font-size:13.5px}
.built th,.built td{padding:8px 12px;text-align:left;border-bottom:1px solid var(--p-surface1);vertical-align:top}
.built th{font-weight:500;color:var(--p-subtext);font-size:12px;text-transform:uppercase;letter-spacing:.06em}
.built td:first-child{white-space:nowrap;color:var(--p-text)}
.built td{color:var(--p-subtext)}
.built code,.pc code{color:var(--p-text)}
.built{border-color:var(--p-surface1)}
.pc h3{font-size:12px;font-weight:500;text-transform:uppercase;letter-spacing:.08em;color:var(--p-subtext);margin:0 0 6px}
.pc p{margin:0;color:var(--p-subtext);font-size:14px}
.note{max-width:78ch;color:var(--frame-dim);font-size:14px}
.note strong{color:var(--frame-fg);font-weight:500}
.gen{display:flex;flex-wrap:wrap;gap:14px;align-items:center;margin-top:14px}
.gen img{border-radius:8px;border:1px solid var(--frame-line);max-width:100%;height:auto}
"""


def render(path: Path, standalone: bool) -> str:
    d = load(path)
    b, a = d["base"], d["accent"]
    art = {
        "wall": data_uri(spacegen.wallpaper(d, 1920, 1080, 7)),
        "stars": data_uri(spacegen.starfield(d, 640, 520, 11, False)),
        "planet": data_uri(spacegen.planet(d, 160, "orange", True, 3)),
    }
    secs = "".join(section(c, art) for c in CONCEPTS)
    body = f"""<title>Launcher Concepts</title>
<meta name="claude:viewport-fit-sides" content="cover">
{FONTS}
<style>{PREVIEW_CSS}{CSS}</style>
<div class="wrap">
  <h1>Launcher Concepts</h1>
  <p class="lede">Six directions in the <strong>{html.escape(d['meta']['name'])}</strong> palette, combining your Rim pick, the retro
  TUI menu and Aylur's "Globes" (Hyprland Hall of Fame). Concepts 1–3 have no retro influence; 4–6 go from strong to light.
  All have icons. The wallpaper behind each mock, the panel starfields and the planet are real output of
  <code>tools/spacegen.py</code> in this palette.</p>
  {matrix()}
  <p class="note"><strong>The engine is the real decision.</strong> rofi covers 1, 2, 5, 6 and an approximate 4. Concept 3 and a
  faithful 4 need <strong>Quickshell</strong> (the retro menu you showed appears to be Quickshell; it is in that screenshot's
  process list). Choosing Quickshell for the launcher means the bar is built in the same QML codebase, so those two decisions
  merge. <code>rofi -dmenu</code> stays the engine for scripted menus either way. Contrast in all mocks: body text
  {contrast(b['text'], b['mantle']):.1f}:1 / Lc {apca(b['text'], b['mantle']):.0f} on <code>mantle</code>; dark text on the red pill
  {contrast(b['crust'], a['red']):.1f}:1.</p>
  <div class="gen"><img src="{art['planet']}" width="96" height="96" alt="Generated planet">
    <img src="{art['stars']}" width="160" height="130" alt="Generated panel starfield" style="background:var(--p-mantle)">
    <img src="{art['wall']}" width="231" height="130" alt="Generated wallpaper">
    <span class="dim">Generator output: planet, panel starfield, wallpaper (seeded, so reproducible).</span></div>
</div>
{secs}
<div class="wrap"><p class="foot">Generated by <code>tools/launcher_preview.py</code> from <code>{html.escape(str(path))}</code>.
Icons are placeholders for your icon theme (Papirus-Dark proposed); descriptions come from each app's <code>.desktop</code> Comment.
Terminal Vision's mock uses the VT323 web font to stand in for a bitmap console font such as Terminus.</p></div>
<script>{COPY_JS}</script>
"""
    # Art is embedded once as custom properties instead of once per mock.
    wrapped = f'<div style="{css_vars(d)};--wall:url({art["wall"]});--stars:url({art["stars"]})">{body}</div>'
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
