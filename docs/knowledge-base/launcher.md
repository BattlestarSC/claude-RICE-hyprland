# Launcher and dmenu-style menus: rofi

## Decision context

The owner comes from i3 + dmenu and showed a rofi screenshot (the "Type to filter" placeholder
and `{name} [<i>({generic})</i>]` row format are rofi defaults [V: rofi `doc/default_theme.rasi`,
`doc/rofi.1.markdown`]). Proposed: rofi for app launching **and** as the `-dmenu` engine for all
scripted menus. Concepts: [docs/launcher/concepts.html](../launcher/concepts.html).

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
- **Monitor selection:** rofi should open on the focused output. Wayland behavior of `-m` with
  Hyprland: [TODO-verify]. Matters on the dual-monitor setup.
- **Window switcher mode** on Hyprland (needs foreign-toplevel protocol): [TODO-verify]; fallback
  is a script over `hyprctl -j clients` (`-j` = JSON output [V: wiki using-hyprctl.md]).

## Config layout (planned)

```text
~/.config/rofi/
├── config.rasi          # behavior: modes, terminal, icon theme, drun format; @theme "apps"
├── colors.rasi          # generated from the palette
├── apps.rasi            # chosen app-launcher concept (glass or rim), @import "colors.rasi"
├── horizon.rasi         # dmenu strip for scripts, @import "colors.rasi"
└── local.rasi           # user overrides, @import-ed last if present
~/.local/share/<rice>/rofi/starfield.png   # generated (Rim concept only)
~/.local/bin/rice-menu-*                    # scripted menus: power, clipboard, screenshot, monitors, keys
```

## Alternatives considered

| Tool | Why not the default |
| --- | --- |
| hyprlauncher | native and themed by `hyprtoolkit.conf`, but theming is colors/rounding/fonts only; no gradients or images; no dmenu compatibility verified |
| fuzzel | fast, has dmenu mode, but ini theming is flat colors + one border; can't do the space look |
| wofi | effectively unmaintained [BK] |
| walker / anyrun | GTK-based, flexible, but AUR-dependent [BK] and not dmenu-script compatible out of the box |
| Quickshell (QML) | could draw anything (animated starfield, shaders). Revisit if the bar moves to Quickshell; rofi stays as the `-dmenu` engine for scripts either way. Arch `extra` has `quickshell` 0.3.1 [S]. |
