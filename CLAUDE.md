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

Phase 0 (foundation). Present: knowledge base, palette proposals and tooling, README, this file.
**Not yet present:** `install.sh`, dotfiles, generated themes. Open questions blocking Phase 1
are in [docs/decisions.md](docs/decisions.md) (`O1`–`O10`). Do not guess answers to open
decisions in code; ask the owner or implement behind an obvious, documented default.

## Read before changing anything

| Task | Read first |
| --- | --- |
| Any Hyprland config | [docs/knowledge-base/hyprland.md](docs/knowledge-base/hyprland.md) |
| hyprlock / hypridle / hyprpaper / launcher | [docs/knowledge-base/hypr-ecosystem.md](docs/knowledge-base/hypr-ecosystem.md) |
| Installer, packages, session startup | [docs/knowledge-base/arch-install.md](docs/knowledge-base/arch-install.md) |
| Colors, any app theme | [docs/knowledge-base/theming.md](docs/knowledge-base/theming.md), [docs/colors/proposals.md](docs/colors/proposals.md) |
| kitty / zsh | [docs/knowledge-base/kitty.md](docs/knowledge-base/kitty.md), [docs/knowledge-base/zsh.md](docs/knowledge-base/zsh.md) |

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
config/                     files deployed under ~/.config (hypr/, kitty/, zsh/, waybar/, ...)
home/                       files deployed directly under ~ (.zshenv, .zprofile, .zshrc)
colors/                     palettes; proposals/ now, the chosen palette as colors/<name>.toml later
templates/                  per-app theme templates consumed by the generator
themes/<palette>/           generated app themes (committed; never hand-edit)
tools/                      dev-only tooling (python): palette.py, preview.py, render-theme
tests/                      container-based tests
docs/                       knowledge-base/, colors/, decisions.md
```

## Commands

```sh
python3 tools/palette.py check  colors/proposals/*.toml     # contrast rules; must pass
python3 tools/palette.py report colors/proposals/*.toml     # per-role contrast table
python3 tools/preview.py --standalone colors/proposals/*.toml > docs/colors/preview.html
```

Planned (add here when they exist): `shellcheck -x install.sh lib/*.sh`, Lua syntax check with a
Lua 5.5 `luac -p`, `Hyprland --verify-config -c <file>`, package resolution in `archlinux:latest`.

Regenerate `docs/colors/preview.html` whenever a file in `colors/proposals/` changes, in the same commit.

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
