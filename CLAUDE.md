# CLAUDE.md

Guidance for Claude sessions working in this repository.

## Project

A complete Hyprland desktop ("rice") for **vanilla Arch Linux**, installed with:

```sh
git clone <repo> && cd <repo> && ./install.sh
```

Core stack: **Hyprland 0.57+ (Lua config) + kitty + zsh**, plus the supporting pieces a usable
desktop needs (lock, idle, wallpaper, bar, launcher, notifications, portals, polkit, audio).
Visual goal: a soft dark, space-themed palette with Monokai-style accents and measured contrast.

## Current state

Phase 1 started. Decided: palette Quasar (`colors/quasar.toml`), i3 default keymap, rofi with the
Orbit (apps) and Flight Deck (menus) themes, greetd + ReGreet login, Quickshell bar (Orbit Glass),
live ASCII Earth/Moon wallpaper on GPU shaders (animated / still / image, per-user
`~/.config/rice/settings.json`), 10-bit output, mild gaps + rounding, hyprlock + hypridle.
Present beyond docs: theme generator + templates, generated `themes/quasar/`, `config/rofi/`,
`config/quickshell/` (bar, services, sky), `config/hypr/conf/{binds,monitors,layers,look,session}.lua`,
`config/hypr/{hyprlock,hypridle}.conf`, `bin/rice-menu`, `bin/rice-sky-atlas`, tests.
**Not yet present:** `install.sh`, the Hyprland entry point, window rules, autostart, kitty, zsh,
greeter files, notifications, screensaver. Quickshell code is render-tested
with PySide6 and mocks but has **never run inside Quickshell**; treat `Bar.qml`, `Wallpaper.qml`,
`shell.qml` and `services/` as unverified. Decided and open questions are in
[docs/decisions.md](docs/decisions.md). Do not guess answers to open decisions in code; ask the
owner or implement behind an obvious, documented default.

Primary target machine (D8): AMD RX 6000 / Navi 21 (gfx1030), two 27" 4K ASUS ProArt panels through a Level1Techs dual-DP KVM that
**removes the outputs when switched away**, Blender with HIP/ROCm, SDDM login. Every
monitor-related change must consider hot-unplug; see [hardware.md](docs/knowledge-base/hardware.md).
Keybindings follow i3's defaults ([docs/keybindings.md](docs/keybindings.md)); do not repurpose an
i3 default key, and give every new bind a `description` (it feeds the in-session cheat sheet).

## Read before changing anything

| Task | Read first |
| --- | --- |
| Any Hyprland config | [docs/knowledge-base/hyprland.md](docs/knowledge-base/hyprland.md) |
| hyprlock / hypridle / hyprpaper / launcher | [docs/knowledge-base/hypr-ecosystem.md](docs/knowledge-base/hypr-ecosystem.md) |
| Installer, packages, session startup | [docs/knowledge-base/arch-install.md](docs/knowledge-base/arch-install.md) |
| Colors, any app theme | [docs/knowledge-base/theming.md](docs/knowledge-base/theming.md), [docs/colors/proposals.md](docs/colors/proposals.md) |
| kitty / zsh | [docs/knowledge-base/kitty.md](docs/knowledge-base/kitty.md), [docs/knowledge-base/zsh.md](docs/knowledge-base/zsh.md) |
| Monitors, GPU, ROCm, SDDM | [docs/knowledge-base/hardware.md](docs/knowledge-base/hardware.md) |
| rofi, launcher, scripted menus | [docs/knowledge-base/launcher.md](docs/knowledge-base/launcher.md) |
| Status bar, telemetry sources, Quickshell, ASCII sky wallpaper | [docs/knowledge-base/bar.md](docs/knowledge-base/bar.md) |
| Keybindings | [docs/keybindings.md](docs/keybindings.md) |

## Hard rules

1. **Hyprland config is Lua (`hyprland.lua`), never hyprlang.** 0.57 does not load `.conf`.
   Your training data and most of the internet show `bind = SUPER, Q, exec, kitty`,
   `$mainMod`, `windowrulev2`, `hyprctl dispatch workspace 3`. All of that is wrong here. Use
   `hl.bind(...)`, `hl.window_rule({...})`, `hyprctl dispatch 'hl.dsp.focus({ workspace = "3" })'`.
2. **The hypr\* companion tools (hyprlock, hypridle, hyprpaper, hyprtoolkit, hyprlauncher) are
   still hyprlang `.conf`.** Two formats coexist in `~/.config/hypr/`.
3. **Verify, then write.** For any option name, CLI flag, package name or file path not already
   marked [V] in the knowledge base, check a primary source first (see "Verifying facts" below).
   Add what you learn to the knowledge base with a verification label and date.
4. **No hand-written colors in app configs.** Every color comes from the palette via the theme
   generator. A literal hex in `config/` is a bug (exceptions: none yet).
5. **Installer safety:** never run as root; never partial-upgrade (`pacman -Sy pkg`); never
   overwrite a user file without backing it up; never edit `/etc` without an explicit prompt;
   official repos only on the default path. Full list in
   [arch-install.md](docs/knowledge-base/arch-install.md#installer-rules-derived-constraints).
6. **Keybind and event callbacks must not block** (they run on the compositor thread). External
   work goes through `hl.dsp.exec_cmd`.
7. **Keep docs in sync in the same commit:** README keybind table, component list, and the
   knowledge base when behavior changes.

## Repository layout (target; create directories as phases need them)

```text
install.sh / uninstall.sh   entry points (bash)
lib/                        bash modules sourced by install.sh (log, preflight, packages, deploy, backup)
packages/                   package lists, one name per line, comments allowed
config/                     files deployed under ~/.config (hypr/, kitty/, zsh/, quickshell/, rofi/, ...)
assets/                     binary inputs (assets/earth/land-1024x512.png from tools/earthmask.py)
home/                       files deployed directly under ~ (.zshenv, .zprofile, .zshrc)
colors/                     palettes; proposals/ now, the chosen palette as colors/<name>.toml later
templates/                  per-app theme templates ({{ role | filter }}), rendered by tools/render_theme.py
themes/<palette>/           generated app themes (committed; never hand-edit)
bin/                        user commands deployed to ~/.local/bin (rice-menu, rice-sky-atlas)
tools/                      dev-only tooling (python): palette.py, preview.py, render-theme
tests/                      rofi-render.sh (themes under Xvfb), lua/ (hl API stub + bind tests),
                            quickshell/ (bar render with mocks), sky/ (ASCII sky frames + timing)
docs/                       knowledge-base/, colors/, decisions.md
```

## Commands

```sh
python3 tools/render_theme.py colors/quasar.toml           # templates/ -> themes/quasar/
python3 tools/render_theme.py colors/quasar.toml --check   # fails if committed themes are stale
lua5.4 tests/lua/run.lua config/hypr/conf/*.lua            # dispatchers, modifiers, duplicate keys, hl.config option names
python3 tests/lua/gen_options.py <hyprland-wiki checkout> > tests/lua/options.lua   # refresh valid option names
shellcheck -x bin/rice-menu bin/rice-sky-atlas tests/rofi-render.sh
# Quickshell (needs PySide6 + PySide6-Addons, an X server or Xvfb, IBM Plex + Symbols Nerd Font):
python3 tests/quickshell/render.py /tmp/bar.png --background frame.png   # real bar QML + mocks; fails on any QML warning
python3 tests/sky/render.py /tmp/sky --size 3840x2160 --dpr 1.5 --frames 24  # --size is PHYSICAL px
python3 tools/earthmask.py ne_50m_land.geojson 1024 512 > assets/earth/land-1024x512.png   # input: see its docstring
tests/rofi-render.sh /tmp/rofi-shots                       # needs Xvfb, rofi, rsvg-convert, hsetroot, imagemagick, Papirus
python3 tools/palette.py check  colors/quasar.toml colors/proposals/round2/*.toml   # 42 WCAG + APCA rules; must pass
python3 tools/palette.py report colors/proposals/round2/*.toml   # per-role WCAG / APCA table
python3 tools/blend.py colors/proposals/round1/pulsar.toml colors/proposals/round1/event-horizon.toml \
    --bg 0.3 --fg 0.55 --accent 0.4 --name Quasar --gradient red purple --cursor yellow   # regenerates quasar.toml
python3 tools/preview.py --standalone colors/proposals/round2/*.toml colors/proposals/round1/*.toml > docs/colors/preview.html
python3 tools/launcher_preview.py --standalone colors/proposals/round2/quasar.toml > docs/launcher/concepts.html
python3 tools/spacegen.py colors/quasar.toml ascii 3840 2160 --cell 12x24 > wallpaper.svg   # also: wallpaper, starfield, planet
python3 tools/bar_preview.py --standalone colors/quasar.toml > docs/bar/concepts.html
```

Round-1 palettes fail the APCA rules by design (they predate them); only round 2 and later must pass.
`tools/preview.py` embeds a JavaScript port of `palette.py`/`blend.py` for the blend dial. If you change
the color math or blend constants, change both and confirm the dial's default output still equals
`quasar.toml` (same hex values).

Planned (add here when they exist): `shellcheck -x install.sh lib/*.sh`, `Hyprland --verify-config -c <file>`,
package resolution in `archlinux:latest`. When the target Hyprland version changes, refresh the
dispatcher list in `tests/lua/hl_stub.lua` from `src/config/lua/bindings/LuaBindingsDispatchers.cpp`.

Regenerate `docs/colors/preview.html` and `docs/launcher/concepts.html` whenever a palette or a
generator changes, in the same commit.

## Conventions

- **Bash:** `#!/usr/bin/env bash`, `set -Eeuo pipefail`, functions `snake_case`, quote everything,
  `[[ ]]` not `[ ]`, no `eval`, `local` in functions, shellcheck-clean with no blanket disables.
- **Lua (Hyprland):** 4-space indent, one concern per file under `config/hypr/conf/`, entry
  `hyprland.lua` only `require`s. Optional files loaded with `pcall(require, ...)`.
  `local.lua` is the user's and is never written by the installer.
- **hyprlang:** colors come from `source = ~/.config/hypr/theme/colors.conf` variables.
- **User override hooks** exist for every major config (`local.lua`, `local.zsh`, kitty
  `include local.conf` if present). The installer never touches them.
- **Commits:** `area: imperative summary` (e.g. `hypr: add workspace binds`, `installer: back up existing configs`).
  Areas: `hypr`, `kitty`, `zsh`, `bar`, `theme`, `colors`, `installer`, `docs`, `tools`, `ci`.

## Verifying facts (environment notes)

From the cloud build environment, `wiki.hypr.land`, `hypr.land`, `archlinux.org`,
`wiki.archlinux.org` and `gitlab.archlinux.org` were unreachable (2026-10-29). GitHub works via git:

```sh
git clone --depth 1 https://github.com/hyprwm/hyprland-wiki            # wiki source: content/**/*.md
git clone --depth 1 --branch v0.57.0 --filter=blob:none --sparse https://github.com/hyprwm/Hyprland
curl -sS https://raw.githubusercontent.com/hyprwm/Hyprland/v0.57.0/src/main.cpp
```

Arch package names and file paths cannot be verified there; mark them [TODO-verify] and check
in an `archlinux:latest` container or on hardware.

## Things that are easy to get wrong

- `hl.dsp.*` inside a function does nothing unless wrapped in `hl.dispatch(...)`.
- Inline conditions in `hl.bind` arguments are evaluated once at load, not per keypress.
- `require` of a missing module kills the calling file; use `pcall`.
- Static window rules match the **initial** class/title only.
- hyprlock with no config exits with an error and leaves the session **unlocked**.
- `pacman --noconfirm` picks default providers silently; name providers explicitly.
- `lspci` is not in `base`; detect GPUs via `/sys/bus/pci/devices/*/{class,vendor}`.
- Monitors: match by `desc:` (includes serial), never by port alone. Hyprland's automatic
  "return workspaces home" after a KVM switch is keyed by connector name and in memory only.
- rofi's Wayland surface covers the whole output (namespace `rofi`): a blur layer rule without
  `ignore_alpha` blurs the entire screen.
- rofi cannot combine a gradient frame with a translucent body; see launcher.md.
- rofi: a missing `@import` file is fatal (shown in place of the menu); `configuration {}` set in
  one theme persists into others loaded with `-theme`.
- Quickshell QML: a property named `top`/`left`/... collides with Item's FINAL anchor lines;
  `implicitHeight` on a `Row`/`Column` is read-only; Quickshell-only types must stay out of
  `BarContent` and the panels or `tests/quickshell/render.py` cannot load them.
- QML colors with alpha are `#AARRGGBB` (template filter `qcolor`), not `#RRGGBBAA`.
- Sky shaders take angles pre-wrapped to [0, 2π) from JS doubles; never pass raw time into a float uniform.
- Mocks in `tests/quickshell/mocks/` must keep the same interface as `config/quickshell/services/`.
- hyprlock: a *missing* config leaves the session unlocked, but config *errors* are only logged.
  Check new keys against `src/config/ConfigManager.cpp` (`addConfigValue`/`addSpecialConfigValue`).
- hypridle/hyprlock `source` `~/.config/hypr/theme/colors.conf`; deploy it first.
- The wallpaper must stay cheap: anything that changes AsciiSky properties every frame on a
  frozen monitor defeats the freeze (Wallpaper.qml copies angles only while `animating`).
- The greeter runs as user `greeter`: anything it needs (monitor config, CSS, wallpaper) must be
  copied under `/etc/greetd/`, not referenced from `~`.
