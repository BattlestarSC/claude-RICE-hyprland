# Launcher and dmenu-style menus: rofi

## Decision context

The owner comes from i3 + dmenu and showed a rofi screenshot (the "Type to filter" placeholder
and `{name} [<i>({generic})</i>]` row format are rofi defaults [V: rofi `doc/default_theme.rasi`,
`doc/rofi.1.markdown`]). Proposed: rofi for app launching **and** as the `-dmenu` engine for all
scripted menus. Concepts: [docs/launcher/concepts.html](../launcher/concepts.html).

Round 2 (2026-10-29): the owner liked Rim (but wanted icons), a retro TUI-style menu (appears to
be Quickshell; quick settings and `--->` submenus inside the launcher list, hotkey letters, hard
offset shadow) and Aylur's "Globes" (Hyprland Hall of Fame #2, built with AGS: icons with
descriptions, quick-settings panel, planets on the wallpaper). Six concepts now: Halo, Orbit,
Mission Control (no retro), Terminal Vision, Flight Deck, Waypoint (strong → light retro).
Mission Control and a faithful Terminal Vision need Quickshell; the rest are rofi.

## Facts

Verified against `davatorium/rofi` master on 2026-10-29 unless noted.

- **Wayland:** rofi **2.0.0 (2025-09-01) merged lbonn's Wayland port into mainline**; the separate
  `rofi-wayland` fork is obsolete. Build is meson-only. No IMDKit (input method) support on Wayland.
  [S: rofi 2.0.0 release notes via newreleases.io; Nixpkgs merged `rofi-wayland` into `rofi`]
  Arch `extra` `rofi` version: [TODO-verify] (expect ≥ 2.0).
- **Layer surface:** on Wayland rofi creates a wlr-layer-shell surface with namespace **`rofi`**,
  layer `overlay` by default (`-wayland-layer`), **anchored to all four edges**: the surface covers
  the whole output and rofi draws its window inside it. [V: `source/wayland/display.c`]
  Consequences for Hyprland layer rules:
  - `blur = true` alone would blur the whole screen; pair it with `ignore_alpha` (just above 0)
    so fully transparent pixels outside the panel are not blurred. The wiki's layer-rule
    examples include exactly this for rofi. [V: wiki `layer-rules.md`]
  - `dim_around = true` dims the whole screen behind rofi (desired "focus" effect).
  - `animation = "popin 92%"` / `"slide top"` applies to the layer.
  - Layers get **no shadow** from Hyprland; there is no layer-rule shadow effect. [V: layer-rules.md effect list]
- **Theme language (rasi):** CSS-like.
  - Colors: `#RGB`, `#RGBA`, `#RRGGBB`, `#RRGGBBAA`, `rgba()`, named, `transparent`. [V: `rofi-theme.5`]
  - `background-image: linear-gradient(to right|left|top|bottom | <angle>, c1, c2, ...)` and
    `url("path", none|both|width|height)`. [V]
  - `border-color` is a single color (no gradient borders). [V: property type `color`]
  - Any child name not starting with `textbox`/`icon`/`button` is a **box widget** that can be
    styled, e.g. a 2px gradient bar: `rimbar { expand: false; padding: 1px; background-image: linear-gradient(...) }`.
    Whether an empty box with 1px padding renders exactly 2px tall: [TODO-verify render]. [V: "Advanced layout"]
  - `window { location; anchor; x-offset; y-offset; fullscreen; width }`. [V]
  - `textbox` `highlight` property styles matched characters. [BK]
- **Gradient frame + translucent body are mutually exclusive.** A gradient frame is done by
  painting the gradient on `window` and inset an opaque `mainbox` (padding = frame width). A
  translucent `mainbox` would reveal the gradient, not the blurred desktop. Hence the two concepts
  "Glass" (translucent, gradient bar only) and "Rim" (gradient frame, opaque body).
- **Script mode rows** can carry `icon`, `meta` (hidden search terms), `nonselectable` (section
  headers) and `info` (passed back as `ROFI_INFO`) via `\0key\x1fvalue` suffixes. [V: `doc/rofi-script.5.markdown`]
  This is how quick-settings rows, section headers and submenus inside the list are built.
- **Pango markup** in rows (`-markup-rows`) and in `drun-display-format`: bold names, a dim second
  line, coloured or underlined hotkey letters. [V: `doc/rofi.1.markdown`]
- **Decorative image widget:** `icon-<name> { filename: "/path/or/icon-name"; size: N }`; `squared`
  and `tint` properties exist. Used for the generated planet in Orbit. [V: `rofi-theme.5` "Icon"]
- **Border styles** are only `solid` and `dash`; a double-line frame needs two nested boxes. [V]
- **Hotkey letters:** typing filters the list, so a marked letter is a hint. Real one-key
  accelerators need `kb-custom-1..19` bindings that a script maps (exit codes 10–28) [BK], or Quickshell.
- **Hard offset shadow** (retro look): no shadow property; approximate with nested boxes, one offset
  by padding. Renders as intended: [TODO-verify]. For windows, Hyprland can draw retro hard shadows
  itself: `decoration.shadow = { sharp = true, offset = {8, 8} }`. [V: option names in `config-options.md`]
- **Monitor selection:** rofi should open on the focused output. Wayland behavior of `-m` with
  Hyprland: [TODO-verify]. Matters on the dual-monitor setup.
- **Window switcher mode** on Hyprland (needs foreign-toplevel protocol): [TODO-verify]; fallback
  is a script over `hyprctl -j clients` (`-j` = JSON output [V: wiki using-hyprctl.md]).

## Verified by rendering (2026-10-30)

`tests/rofi-render.sh` renders the real themes with rofi 1.7.5 (X11, Xvfb) and screenshots them.
The rasi language is the same in 2.x; what X11 cannot show is Hyprland's blur and the
translucent corners (no compositor in the test, so they render black). Findings:

- **A missing `@import` file is fatal**: rofi shows the error in place of the menu. The installer
  must create `~/.config/rofi/local.rasi` (empty) so the user-override import always resolves.
- **`configuration {}` blocks inside a theme are honored and persist across `-theme`**: Orbit's
  `eh: 2` leaked into Flight Deck menus until `deck.rasi` reset `eh: 1`.
- Two-line rows work: `eh: 2` + `drun-display-format` with `\n` and Pango markup.
- `~` expands in an `icon-*` widget's `filename`.
- **Hard offset shadow via nested boxes works** (Flight Deck). Resolves the earlier [TODO-verify].
- `linear-gradient(to right, #RRGGBBAA, ...)` with alpha works for the selected-row fill.
- Showing `{comment}` requires `comment` in `drun-match-fields`, so descriptions are searched too.
  With fuzzy matching that produced noisy hits; `matching: "normal"` (substring, like dmenu) fixed it.

## Config layout

```text
~/.config/rofi/
├── config.rasi          # behavior: modes, terminal, icon theme, matching; @theme "orbit"
├── colors.rasi          # generated from the palette
├── orbit.rasi           # app launcher theme (generated)
├── deck.rasi            # Flight Deck theme for every scripted menu (generated)
└── local.rasi           # user overrides; created empty by the installer, never overwritten
~/.local/share/<rice>/art/                 # spacegen.py output rasterized by rsvg-convert at install:
                                           #   starfield.png (panel), planet.png, wallpaper-3840x2160.png
~/.local/bin/rice-menu                      # scripted menus: session, clipboard, windows, keys, screenshot, monitors
```

## Alternatives considered

| Tool | Why not the default |
| --- | --- |
| hyprlauncher | native and themed by `hyprtoolkit.conf`, but theming is colors/rounding/fonts only; no gradients or images; no dmenu compatibility verified |
| fuzzel | fast, has dmenu mode, but ini theming is flat colors + one border; can't do the space look |
| wofi | effectively unmaintained [BK] |
| walker / anyrun | GTK-based, flexible, but AUR-dependent [BK] and not dmenu-script compatible out of the box |
| Quickshell (QML) | could draw anything (live quick settings, real accelerators, animated starfield). Required by concepts 3 and a faithful 4; picking one of those merges the launcher and bar decisions. rofi stays as the `-dmenu` engine for scripts either way. Arch `extra` has `quickshell` 0.3.1 [S]. |
