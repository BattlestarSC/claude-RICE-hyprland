#!/usr/bin/env python3
"""Render docs/bar/concepts.html: status bar concepts (Orbiter x Quasar) over the ASCII wallpaper.

Usage:
    tools/bar_preview.py [--standalone] <palette.toml> > out.html

All concepts show the same sample telemetry so they compare like for like. The wallpaper is
real output of `spacegen.py ascii`. Dev-only.
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
         '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600'
         '&family=IBM+Plex+Sans:wght@400;500;600&family=JetBrains+Mono:wght@400;700&family=Unbounded:wght@600&display=swap">')

# One machine, one moment: every concept renders this.
S = dict(
    ws=[1, 2, 3, 4, 5], ws_active=3, ws_busy={1, 2, 3, 5}, title="kitty — ~/claude-RICE-hyprland",
    date="THU 30 OCT", time="00:42",
    cpu=12, cpu_hist=[8, 9, 14, 30, 22, 12, 10, 9, 18, 41, 26, 15, 11, 12, 9, 12],
    cores=[18, 7, 12, 4, 31, 9, 6, 14, 22, 3, 8, 11, 5, 19, 7, 10],
    load=(0.82, 0.64, 0.51), load_hist=[0.4, 0.5, 0.45, 0.6, 0.9, 1.3, 1.1, 0.9, 0.8, 0.7, 0.75, 0.82],
    ram_used=9.4, ram_total=31.2, swap=0.0,
    gpu=4, vram_used=1.2, vram_total=16.0, gpu_temp=41,
    net_if="enp5s0", ip="192.168.1.42", down="2.4 MB/s", up="180 kB/s",
    down_hist=[1, 1, 2, 5, 9, 7, 3, 2, 2, 6, 8, 4, 2, 3, 2, 2], up_hist=[0, 0, 1, 1, 2, 1, 0, 0, 1, 1, 2, 1, 0, 1, 0, 0],
    disks=[("nvme0n1", "/", 412, 1800, "12 MB/s", "3 MB/s"),
           ("nvme1n1", "/home", 1100, 3600, "0 B/s", "1 MB/s"),
           ("nvme2n1", "/games", 1690, 1800, "48 MB/s", "0 B/s")],
    vol=63, muted=False,
    sinks=[("Speakers", "Schiit Modi+ (USB)", True), ("Headphones", "USB DAC", False), ("Monitor", "ProArt PA279 (DisplayPort)", False)],
    track="Track title", artist="Artist", pos="1:26", length="3:40", playing=True,
)


def data_uri(svg: str) -> str:
    return "data:image/svg+xml;base64," + base64.b64encode(svg.encode()).decode()


def e(s) -> str:
    return html.escape(str(s))


def meter(pct: float, width: int = 10) -> str:
    n = round(pct / 100 * width)
    return "[" + "|" * n + " " * (width - n) + "]"


def spark(values: list[float], top: float | None = None) -> str:
    """One sample per character, eight levels: a sparkline in plain text (U+2581..U+2588)."""
    top = top or max(values) or 1
    blocks = "▁▂▃▄▅▆▇█"
    return "".join(blocks[min(7, int(v / top * 7.999))] for v in values)


def pct(used, total) -> int:
    return round(used / total * 100)


def disk_role(p: int) -> str:
    return "red" if p >= 90 else "yellow" if p >= 75 else "green"


# ------------------------------------------------------------------ shared panel bodies

def panel_audio(cls: str) -> str:
    sinks = "".join(f'<li class="{"on" if on else ""}"><span class="rad">{"(•)" if on else "( )"}</span>'
                    f'<b>{e(n)}</b><small>{e(d)}</small></li>' for n, d, on in S["sinks"])
    return f"""
<div class="pnl {cls}">
  <div class="ph"><span class="ptag">AUDIO</span><span class="dim">output · volume · media</span></div>
  <div class="row"><span class="k">VOL</span><span class="mtr c-red">{meter(S['vol'], 20)}</span><span class="v">{S['vol']}%</span></div>
  <div class="sub">OUTPUT DEVICE</div>
  <ul class="sinks">{sinks}</ul>
  <div class="sub">NOW PLAYING</div>
  <div class="media"><b>{e(S['track'])}</b> <span class="dim">— {e(S['artist'])}</span></div>
  <div class="row"><span class="k">{S['pos']}</span><span class="mtr c-purple">{meter(39, 20)}</span><span class="v">{S['length']}</span></div>
  <div class="ctl"><span>|◀</span><span class="on">{'❚❚' if S['playing'] else '▶'}</span><span>▶|</span></div>
</div>"""


def panel_system(cls: str) -> str:
    cores = "".join(f'<span class="core" style="--h:{c}%" title="cpu{i} {c}%"></span>' for i, c in enumerate(S["cores"]))
    disks = "".join(
        f'<div class="dk"><span class="k">{d}</span><span class="dim mp">{m}</span>'
        f'<span class="mtr c-{disk_role(pct(u, t))}">{meter(pct(u, t), 14)}</span>'
        f'<span class="v">{pct(u, t)}%</span><span class="dim io">r {r} · w {w}</span></div>'
        for d, m, u, t, r, w in S["disks"])
    la = " ".join(f"{x:.2f}" for x in S["load"])
    return f"""
<div class="pnl {cls}">
  <div class="ph"><span class="ptag">SYSTEM</span><span class="dim">16 threads · up 3:26</span></div>
  <div class="row"><span class="k">CPU</span><span class="mtr c-cyan">{meter(S['cpu'], 20)}</span><span class="v">{S['cpu']}%</span></div>
  <div class="cores">{cores}</div>
  <div class="row"><span class="k">LOAD</span><span class="c-orange spark">{spark(S['load_hist'], 2)}</span><span class="v">{la}</span></div>
  <div class="row"><span class="k">MEM</span><span class="mtr c-purple">{meter(pct(S['ram_used'], S['ram_total']), 20)}</span><span class="v">{S['ram_used']}/{S['ram_total']:.0f}G</span></div>
  <div class="row"><span class="k">GPU</span><span class="mtr c-blue">{meter(S['gpu'], 20)}</span><span class="v">{S['gpu']}% · {S['gpu_temp']}°C</span></div>
  <div class="row"><span class="k">VRAM</span><span class="mtr c-blue">{meter(pct(S['vram_used'], S['vram_total']), 20)}</span><span class="v">{S['vram_used']}/{S['vram_total']:.0f}G</span></div>
  <div class="sub">DISKS</div>
  {disks}
</div>"""


def panel_network(cls: str) -> str:
    return f"""
<div class="pnl {cls}">
  <div class="ph"><span class="ptag">NETWORK</span><span class="dim">NetworkManager · wired</span></div>
  <div class="row"><span class="k">IF</span><span>{S['net_if']}</span><span class="v c-green">connected</span></div>
  <div class="row"><span class="k">IPv4</span><span>{S['ip']}/24</span><span class="v dim">gw .1</span></div>
  <div class="row"><span class="k">DOWN</span><span class="c-green spark">{spark(S['down_hist'])}</span><span class="v">{S['down']}</span></div>
  <div class="row"><span class="k">UP</span><span class="c-yellow spark">{spark(S['up_hist'], 9)}</span><span class="v">{S['up']}</span></div>
  <div class="sub">DISKS (I/O)</div>
  {''.join(f'<div class="row"><span class="k">{d}</span><span class="dim">r {r}</span><span class="v dim">w {w}</span></div>' for d, _, _, _, r, w in S['disks'])}
</div>"""


# ------------------------------------------------------------------ bars

def ws_ascii(active_fmt="({})") -> str:
    out = []
    for w in S["ws"]:
        if w == S["ws_active"]:
            out.append(f'<span class="wsa">{active_fmt.format(w)}</span>')
        else:
            out.append(f'<span class="{"wsb" if w in S["ws_busy"] else "wse"}">{w}</span>')
    return " ".join(out)


def disks_inline(fmt: str) -> str:
    return " ".join(fmt.format(d=d[-3:-2] if False else d.replace("nvme", "n").replace("n1", ""), p=pct(u, t), r=disk_role(pct(u, t)))
                    for d, _, u, t, _, _ in S["disks"])


def bar_orbiter() -> str:
    disks = " ".join(f'<span class="dim">{d.replace("nvme", "nv").replace("n1", "")}</span> {pct(u, t)}%'
                     for d, _, u, t, _, _ in S["disks"])
    return f"""
<div class="sbar b-orbiter">
  <div class="bl"><span class="dim">▦</span> {ws_ascii()} <span class="dim">·</span> <span class="dim">{e(S['title'])}</span></div>
  <div class="bc">{S['date']} {S['time']}</div>
  <div class="br"><span><span class="dim">cpu</span> {meter(S['cpu'], 8)} {S['cpu']}%</span>
    <span><span class="dim">mem</span> {meter(pct(S['ram_used'], S['ram_total']), 8)} {pct(S['ram_used'], S['ram_total'])}%</span>
    <span><span class="dim">la</span> {S['load'][0]:.2f} {S['load'][1]:.2f} {S['load'][2]:.2f}</span>
    <span>{disks}</span>
    <span><span class="dim">net</span> ↓{S['down'].replace(' ', '')} ↑{S['up'].replace(' ', '')}</span>
    <span class="hot"><span class="dim">vol</span> {meter(S['vol'], 8)} {S['vol']}%</span>
    <span>▶ {e(S['track'])}</span></div>
</div>"""


def bar_telemetry() -> str:
    disks = " ".join(f'<span class="dim">{d.replace("nvme", "nv").replace("n1", "")}</span><span class="c-{disk_role(pct(u, t))}">{pct(u, t)}%</span>'
                     for d, _, u, t, _, _ in S["disks"])
    return f"""
<div class="sbar b-tele">
  <div class="bl"><span class="pill">◢ {S['ws_active']}</span> {ws_ascii('[{}]')} <span class="dim">{e(S['title'])}</span></div>
  <div class="bc"><span class="dim">{S['date']}</span> <b>{S['time']}</b></div>
  <div class="br">
    <span class="c-cyan hot">CPU {spark(S['cpu_hist'], 50)} {S['cpu']}%</span>
    <span class="c-purple">MEM {S['ram_used']}G</span>
    <span class="c-orange">LA {S['load'][0]:.2f} {S['load'][1]:.2f} {S['load'][2]:.2f}</span>
    <span>{disks}</span>
    <span class="c-green">NET ↓{S['down']}</span>
    <span class="c-red">VOL {S['vol']}%</span>
    <span class="dim">▶ {e(S['track'])}</span></div>
</div>"""


def bar_deck() -> str:
    def cell(tag, body, role="text", hot=False):
        return f'<div class="cell{" hot" if hot else ""}"><span class="ctag">{tag}</span><span class="c-{role}">{body}</span></div>'
    disks = "".join(cell(d.replace("nvme", "NV").replace("n1", ""), f"{meter(pct(u, t), 6)} {pct(u, t)}%", disk_role(pct(u, t)))
                    for d, _, u, t, _, _ in S["disks"])
    return f"""
<div class="sbar b-deck">
  <div class="bl">{cell('WS', ws_ascii('[{}]'), 'text')}{cell('WIN', e(S['title'][:18]) + '…', 'subtext')}</div>
  <div class="bc">{cell('T', S['date'] + ' ' + S['time'], 'bright')}</div>
  <div class="br">{cell('CPU', f"{meter(S['cpu'], 6)} {S['cpu']}%", 'cyan')}{cell('MEM', f"{meter(pct(S['ram_used'], S['ram_total']), 6)} {pct(S['ram_used'], S['ram_total'])}%", 'purple')}
    {cell('LOAD', ' '.join(f'{x:.2f}' for x in S['load']), 'orange')}{disks}{cell('NET', '↓' + S['down'], 'green', True)}{cell('VOL', f"{S['vol']}%", 'red')}</div>
</div>"""


def ring(p: int, role: str, label: str) -> str:
    return (f'<span class="ring" style="--p:{p};--rc:var(--p-{role})"><i>{p}</i></span>'
            f'<span class="rl">{label}</span>')


def bar_glass() -> str:
    dots = "".join(f'<span class="dot{" on" if w == S["ws_active"] else " busy" if w in S["ws_busy"] else ""}"></span>' for w in S["ws"])
    disks = "".join(ring(pct(u, t), disk_role(pct(u, t)), d.replace("nvme", "nv").replace("n1", ""))
                    for d, _, u, t, _, _ in S["disks"])
    return f"""
<div class="sbar b-glass">
  <div class="bl"><span class="gp">{dots}</span><span class="gp">kitty</span></div>
  <div class="bc"><span class="gp">{S['time']} · Thu 30 Oct</span></div>
  <div class="br"><span class="gp">{ring(S['cpu'], 'cyan', 'cpu')}{ring(pct(S['ram_used'], S['ram_total']), 'purple', 'mem')}<span class="rl">load {S['load'][0]:.2f}</span></span>
    <span class="gp">{disks}</span>
    <span class="gp hot">↓ {S['down']}</span>
    <span class="gp">🔊 <span class="slider" style="--v:{S['vol']}%"></span></span></div>
</div>"""


def bar_twin_secondary() -> str:
    return f"""
<div class="sbar b-tele b-min">
  <div class="bl">{ws_ascii('[{}]').replace('>3<', '>7<')}</div>
  <div class="bc"><b>{S['time']}</b></div>
  <div class="br"><span class="dim">▶ {e(S['track'])} — {e(S['artist'])}</span> <span class="c-purple">{meter(39, 10)}</span></div>
</div>"""


# ------------------------------------------------------------------ concepts

CONCEPTS = [
    dict(slug="orbiter", n=1, name="Orbiter", ascii="full", bar=bar_orbiter, panel=lambda: panel_audio("p-orbiter"),
         lede="Closest to the Reddit rice: everything is monospace text, almost colorless. Bracket meters, (3) for the active "
              "workspace, and a control-panel dropdown made of the same characters.",
         notes=["Color only where state matters: volume when changed, disks above 75%.",
                "Most cohesive with the ASCII wallpaper; least glanceable at a distance."]),
    dict(slug="telemetry", n=2, name="Telemetry", ascii="text + color", bar=bar_telemetry, panel=lambda: panel_system("p-deck"),
         lede="Orbiter's text language plus Quasar's accents: one color per subsystem, block-character sparklines for history, "
              "and Flight Deck dropdowns (tag header, hard shadow) so the bar and the menus are one family.",
         notes=["Readable at a glance: CPU is always cyan, memory purple, disks traffic-light by fill.",
                "Sparklines are text (▁▂▃▅▇), so they scale with the font and stay crisp at 4K."]),
    dict(slug="deck", n=3, name="Flight Deck", ascii="framed text", bar=bar_deck, panel=lambda: panel_network("p-deck"),
         lede="Retro console: every module is a labeled cell with a tag, a hard shadow under the whole bar, mini meters. "
              "Matches the Flight Deck menus most literally.",
         notes=["Densest and most 'instrument panel'.",
                "Wide: on 2560 logical px it fits; on a laptop it needs modules hidden."]),
    dict(slug="glass", n=4, name="Orbit Glass", ascii="none (wallpaper only)", bar=bar_glass, panel=lambda: panel_audio("p-glass"),
         lede="The modern counterpart to the Orbit launcher: floating translucent pills, ring gauges, a volume slider, "
              "a frosted audio panel with the output-device list.",
         notes=["Pairs with Orbit; contrasts with the ASCII wallpaper on purpose.",
                "Ring gauges and sliders are only practical in Quickshell."]),
    dict(slug="twin", n=5, name="Twin HUD", ascii="text + color", bar=None, panel=None,
         lede="Dual-monitor aware: the left screen carries full telemetry, the right a quiet bar (workspaces, clock, media). "
              "Each screen gets its own bar instance, recreated when the KVM brings the monitor back.",
         notes=["Any concept can be split this way; shown here with Telemetry.",
                "Per-screen content follows the monitor's EDID description, so it survives cable swaps."]),
]


def monitor(bar_html: str, panel_html: str = "", cls: str = "") -> str:
    return f'<div class="mon {cls}">{bar_html}{panel_html}</div>'


def section(c: dict) -> str:
    if c["slug"] == "twin":
        mock = (f'<div class="twin"><span class="lbl">LEFT · DP-1 · primary · workspaces 1-5</span>{monitor(bar_telemetry())}'
                f'<span class="lbl">RIGHT · DP-2 · secondary · workspaces 6-10</span>{monitor(bar_twin_secondary(), cls="short")}</div>')
    else:
        mock = monitor(c["bar"](), c["panel"]())
    notes = "".join(f"<li>{n}</li>" for n in c["notes"])
    return f"""
<section class="cz" id="{c['slug']}">
  <div class="cz-in">
    <header class="cz-h"><div><h2>{c['n']} · {c['name']}</h2><p class="tag">{c['lede']}</p></div>
      <div class="badges"><span class="eng">ASCII: {c['ascii']}</span></div></header>
    {mock}
    <ul class="notes">{notes}</ul>
  </div>
</section>"""


ENGINES = [
    ("Engine", "Quickshell (QML)", "waybar"),
    ("Arch package", "<code>quickshell</code> in <code>extra</code> (0.3.1)", "<code>waybar</code> in <code>extra</code> (0.15)"),
    ("CPU, RAM, load, network, per-disk usage in the bar", "yes (read <code>/proc</code>, <code>df</code>; any layout)", "yes (built-in modules; one <code>disk</code> instance per drive)"),
    ("Sparklines / history", "yes, any style", "<code>cpu-graph</code>, <code>custom-graph</code> (new in 0.15)"),
    ("Dropdown panels (system, network, audio)", "yes: real panels with live data", "no: tooltips, or static XML menus"),
    ("Output-device selection", "native: <code>Pipewire.preferredDefaultAudioSink</code> is writable", "via a rofi script on click (Flight Deck menu)"),
    ("Volume slider, media controls", "native (PipeWire, MPRIS services)", "scroll on module; <code>mpris</code> module; no slider in a popup"),
    ("Per-monitor bars, KVM re-plug", "per-screen instances via <code>Variants</code> over <code>Quickshell.screens</code>", "per-output bars; hot-plug has a history of glitches [unverified for 0.15]"),
    ("Hyprland 0.57 Lua IPC", "yes (<code>Hyprland.usingLua</code>)", "workspaces module; uses its own IPC"),
    ("Also covers", "notifications, OSDs, lock screen (session-lock), greeter (greetd), polkit, tray", "the bar only"),
    ("Cost", "we write and maintain QML; Qt updates can break it if not rebuilt", "config + CSS; little code"),
]


def engines() -> str:
    head = "".join(f"<th>{h}</th>" for h in ENGINES[0])
    rows = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in ENGINES[1:])
    return f'<div class="tbl-wrap"><table class="sum eng-t"><thead><tr>{head}</tr></thead><tbody>{rows}</tbody></table></div>'


CSS = """
.cz{background:var(--p-base);color:var(--p-text);border-top:1px solid var(--p-surface2)}
.cz-in{max-width:1240px;margin:0 auto;padding-block:36px 40px;display:grid;gap:16px;
  padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px))}
.cz h2,.h2f{font-family:var(--f-display);font-weight:600;font-size:clamp(22px,3vw,30px);margin:0;color:var(--p-bright)}
.h2f{color:var(--frame-fg);margin:24px 0 8px}
.cz-h{display:flex;flex-wrap:wrap;gap:12px 24px;justify-content:space-between;align-items:flex-end}
.eng{font:600 12px var(--f-mono);padding:4px 10px;border-radius:999px;background:var(--p-surface1);color:var(--p-yellow)}
.notes{margin:0;padding-left:18px;color:var(--p-subtext);font-size:14px}
.cap{margin:0;color:var(--p-overlay);font-size:13px}
.mon.short{aspect-ratio:16/3}
.mon{position:relative;aspect-ratio:16/9;max-width:100%;border-radius:10px;overflow:hidden;border:1px solid var(--p-surface1);
  background:var(--ascii) center / cover,var(--p-crust);container-type:inline-size}
.twin{display:grid;gap:10px}
.twin .lbl{font:600 12px var(--f-mono);color:var(--p-subtext);letter-spacing:.08em}
.sbar{position:absolute;left:0;right:0;top:0;display:flex;align-items:center;gap:1.2cqw;justify-content:space-between;
  padding:.5cqw 1cqw;font:500 max(8px,.8cqw)/1.3 "IBM Plex Mono",var(--f-mono);color:var(--p-text);white-space:nowrap}
.sbar .bl,.sbar .br{display:flex;align-items:center;gap:1.1cqw;min-width:0}
.sbar .bl{flex:1 1 auto;overflow:hidden}
.sbar .bc,.sbar .br{flex:none}
.dim{color:var(--p-overlay)} .wse{color:var(--p-surface2)} .wsb{color:var(--p-subtext)} .wsa{color:var(--p-bright);font-weight:600}
.spark{letter-spacing:0;white-space:pre}
.b-orbiter{background:linear-gradient(var(--p-crust),color-mix(in srgb,var(--p-crust) 0%,transparent))}
.b-orbiter .hot{color:var(--p-bright)}
.b-tele{background:color-mix(in srgb,var(--p-crust) 88%,transparent);border-bottom:1px solid transparent;
  border-image:linear-gradient(to right,var(--p-red),var(--p-purple)) 1}
.b-tele .pill{color:var(--p-crust);background:var(--p-red);padding:0 .5cqw;font-weight:700}
.b-tele .wsa{color:var(--p-red)}
.b-min{font-size:max(8px,.8cqw)}
.b-deck{background:var(--p-mantle);box-shadow:0 .5cqw 0 color-mix(in srgb,var(--p-purple) 35%,var(--p-crust));padding:.35cqw .6cqw;
  border-bottom:2px solid var(--p-red)}
.b-deck .bl,.b-deck .br{gap:.4cqw}
.cell{display:flex;align-items:center;gap:.4cqw;padding:.1cqw .5cqw;border:1px solid var(--p-surface2);background:var(--p-base)}
.cell.hot{border-color:var(--p-green)}
.ctag{font-size:.8em;color:var(--p-crust);background:var(--p-surface2);padding:0 .3cqw}
.cell.hot .ctag{background:var(--p-green)}
.b-glass{top:.6cqw;left:.6cqw;right:.6cqw;padding:0;font-family:"IBM Plex Sans",var(--f-body)}
.gp{display:flex;align-items:center;gap:.6cqw;padding:.35cqw .9cqw;border-radius:999px;
  background:color-mix(in srgb,var(--p-base) 72%,transparent);backdrop-filter:blur(10px);-webkit-backdrop-filter:blur(10px);
  border:1px solid color-mix(in srgb,var(--p-bright) 10%,transparent)}
.gp.hot{color:var(--p-green)}
.dot{width:.6cqw;height:.6cqw;border-radius:50%;background:var(--p-surface2)}
.dot.busy{background:var(--p-subtext)} .dot.on{width:1.6cqw;border-radius:99px;background:linear-gradient(to right,var(--p-red),var(--p-purple))}
.ring{--sz:1.7cqw;position:relative;display:grid;place-items:center;width:var(--sz);height:var(--sz);border-radius:50%;
  background:conic-gradient(var(--rc) calc(var(--p) * 1%),var(--p-surface1) 0)}
.ring::before{content:"";position:absolute;inset:.22cqw;border-radius:50%;background:var(--p-base)}
.ring i{position:relative;font:600 .62cqw var(--f-mono);font-style:normal}
.rl{font-size:.85em;color:var(--p-subtext);margin-right:.3cqw}
.slider{display:inline-block;width:5cqw;height:.45cqw;border-radius:9px;background:linear-gradient(to right,var(--p-red) var(--v),var(--p-surface1) var(--v))}

.pnl{position:absolute;top:3.4cqw;right:1.4cqw;width:34cqw;font:max(9px,1cqw)/1.45 "IBM Plex Mono",var(--f-mono);color:var(--p-text);
  padding:1cqw 1.2cqw;display:grid;gap:.35cqw}
.ph{display:flex;gap:.8cqw;align-items:center;padding-bottom:.4cqw;border-bottom:1px solid var(--p-surface2)}
.ptag{color:var(--p-crust);background:var(--p-red);padding:0 .5cqw;font-weight:700}
.row,.dk{display:grid;grid-template-columns:5.2em 1fr auto;gap:.8cqw;align-items:center;white-space:nowrap}
.dk{grid-template-columns:5.2em 4.2em auto auto 1fr}
.dk .io{text-align:right}
.k{color:var(--p-subtext)} .v{text-align:right;font-variant-numeric:tabular-nums}
.mtr{letter-spacing:-.04em;white-space:pre}
.sub{margin-top:.4cqw;color:var(--p-overlay);font-size:.85em;letter-spacing:.1em}
.cores{display:flex;gap:.25cqw;align-items:flex-end;height:2.2cqw;padding-left:6.1em}
.core{flex:1;height:max(2px,var(--h));background:var(--p-cyan);opacity:.85}
.sinks{list-style:none;margin:0;padding:0;display:grid;gap:.2cqw}
.sinks li{display:grid;grid-template-columns:2.6em auto 1fr;gap:.6cqw;padding:.15cqw .4cqw;border-left:3px solid transparent}
.sinks li small{color:var(--p-overlay);font-size:.9em;overflow:hidden;text-overflow:ellipsis}
.sinks li.on{border-left-color:var(--p-red);background:color-mix(in srgb,var(--p-red) 18%,transparent)}
.rad{color:var(--p-red)}
.ctl{display:flex;gap:1cqw;justify-content:center;color:var(--p-subtext)} .ctl .on{color:var(--p-bright)}
.p-orbiter{background:color-mix(in srgb,var(--p-crust) 92%,transparent);border:1px solid var(--p-surface1)}
.p-orbiter .ptag{background:none;color:var(--p-bright);padding:0}
.p-orbiter .mtr,.p-orbiter .rad{color:var(--p-subtext)} .p-orbiter .sinks li.on{background:none;border-left-color:var(--p-subtext)}
.p-deck{background:var(--p-mantle);border:2px solid transparent;
  background-clip:padding-box;box-shadow:.7cqw .7cqw 0 color-mix(in srgb,var(--p-purple) 35%,var(--p-crust));
  outline:2px solid var(--p-red);outline-offset:-2px}
.p-glass{background:color-mix(in srgb,var(--p-base) 76%,transparent);backdrop-filter:blur(16px);-webkit-backdrop-filter:blur(16px);
  border:1px solid color-mix(in srgb,var(--p-bright) 12%,transparent);border-radius:1.2cqw;font-family:"IBM Plex Sans",var(--f-body)}
.p-glass .ptag{border-radius:99px;padding:0 .8cqw}
.c-red{color:var(--p-red)} .c-orange{color:var(--p-orange)} .c-yellow{color:var(--p-yellow)} .c-green{color:var(--p-green)}
.c-cyan{color:var(--p-cyan)} .c-blue{color:var(--p-blue)} .c-purple{color:var(--p-purple)} .c-pink{color:var(--p-pink)}
.c-text{color:var(--p-text)} .c-subtext{color:var(--p-subtext)} .c-bright{color:var(--p-bright)}
.eng-t td{white-space:normal;vertical-align:top;min-width:180px}
.eng-t td:first-child{color:var(--frame-dim)}
.recs{max-width:80ch;color:var(--frame-fg);font-size:15px}
.recs li{margin:4px 0}
.note{max-width:80ch;color:var(--frame-dim);font-size:14px}
"""


def render(path: Path, standalone: bool) -> str:
    d = load(path)
    b = d["base"]
    wall = data_uri(spacegen.ascii_svg(d, 1600, 900, 7, 14, 7))
    secs = "".join(section(c) for c in CONCEPTS)
    body = f"""<title>Status Bar Concepts</title>
<meta name="claude:viewport-fit-sides" content="cover">
{FONTS}
<style>{PREVIEW_CSS}{CSS}</style>
<div class="wrap">
  <h1>Status Bar Concepts</h1>
  <p class="lede">Orbiter's ASCII telemetry merged with Quasar. Five concepts, ordered from most to least ASCII, all showing the
  same machine: CPU, memory, load averages, each NVMe drive, network, audio with output selection and media, plus the RX 6000 GPU.
  The wallpaper behind every mock is <code>spacegen.py ascii</code>: an Orbiter-style scene rendered as characters, in this palette.</p>
  <h2 class="h2f">Recommendation</h2>
  <ul class="recs">
    <li><strong>Engine: Quickshell.</strong> Your list needs dropdown panels with live data and an output-device picker; waybar has
    neither (only tooltips and static menus). Quickshell also covers what comes next in this rice: notifications, volume OSD,
    a lock screen that uses the same ASCII grid as the wallpaper (Orbiter's trick), and per-screen bars that come back cleanly
    after a KVM switch.</li>
    <li><strong>Design: 2 · Telemetry, split per screen as in 5 · Twin HUD.</strong> It keeps Orbiter's text look while staying
    readable at a glance, and its dropdowns share the Flight Deck look with your rofi menus.</li>
    <li>The cost: the bar is code we write and maintain (QML), not a config file. Arch rebuilds <code>quickshell</code> with Qt,
    which addresses the crash-after-Qt-update reports from AUR builds.</li>
  </ul>
  {engines()}
  <p class="note">Contrast on the bar background: body text {contrast(b['text'], b['crust']):.1f}:1 / Lc {apca(b['text'], b['crust']):.0f};
  dim labels (<code>overlay</code>) {contrast(b['overlay'], b['crust']):.1f}:1 / Lc {apca(b['overlay'], b['crust']):.0f}.</p>
</div>
{secs}
<div class="wrap"><p class="foot">Generated by <code>tools/bar_preview.py</code> from <code>{html.escape(str(path))}</code>.
Sample values are illustrative. Bar text is drawn about 1.5× larger relative to the screen than a real 2560 px bar, so it stays readable here. Concept 4 uses IBM Plex Sans; the rest use IBM Plex Mono, Orbiter's font (Arch: <code>ttf-ibm-plex</code>).</p></div>
<script>{COPY_JS}</script>
"""
    wrapped = f'<div style="{css_vars(d)};--ascii:url({wall})">{body}</div>'
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
