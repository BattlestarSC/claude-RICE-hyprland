# claude-RICE-hyprland

A complete, soft-dark, space-themed Hyprland desktop for **vanilla Arch Linux**, built around
**Hyprland + kitty + zsh**. One command to install, one palette file to theme everything.

> [!WARNING]
> **Alpha, not yet run on real hardware.** The installer and every config exist and are checked
> by tests (dry runs, API stubs, real renders of the terminal apps), but no one has booted into
> the result yet. Expect first-boot fixes, especially in the Quickshell bar and wallpaper and on
> the login screen. Try it on a spare install or a VM with 3D acceleration first.

## Status

| Phase | Scope | State |
| --- | --- | --- |
| 0. Foundation | knowledge base, `CLAUDE.md`, README, palette + contrast tooling, launcher concepts | **done** |
| 1. Core | `install.sh` (preflight, packages, backup, deploy), Hyprland Lua config, kitty, zsh, theme generator | **written, untested on hardware**: installer (dry-run and file layer tested), Hyprland entry point, env, input, window rules, autostart, keybindings, monitors, look; kitty + foot; zsh + starship |
| 2. Desktop | bar, launcher, notifications, hyprlock, hypridle, wallpaper, screenshots, clipboard, login | **written**: greetd + ReGreet login; Quickshell bar (Orbit Glass, power button, notifications), ASCII sky and screensaver written and render-tested off-hardware, not yet run in a real Quickshell; hyprlock + hypridle; Thunar/Dolphin theming; browser privacy configs; Code - OSS; Neovim, vis, Helix with LSPs |
| 3. Polish | GTK/Qt theming, cursor, theme switcher, uninstaller, CI in an Arch container | **started**: GTK/KDE theming, cursor (default chosen), CI with Arch package checks; theme switcher and uninstaller planned |

## Installation

On a fresh Arch install, logged in as your normal user (a TTY is fine):

```sh
sudo pacman -S --needed git
git clone https://github.com/BattlestarSC/claude-RICE-hyprland.git
cd claude-RICE-hyprland
./install.sh
```

That is all; reboot when it finishes. `./install.sh --yes` takes every default without asking;
`./install.sh --dry-run` shows everything it would do and changes nothing.

What it does, in order ([details](docs/knowledge-base/arch-install.md#the-installer)):

1. **Checks** Arch, a non-root user with working `sudo`, network, no pacman lock, free space;
   detects the GPU, the network manager and the current display manager.
2. **Asks** a few questions (Enter takes the default): language toolchains (yes), office
   (full TeX Live, TeXstudio, LibreOffice; yes), Blender with
   HIP on AMD (yes), the AUR backup browser (no), wallpaper mode and layout, login screen (yes),
   zsh as login shell (yes). Then shows the plan and asks once.
3. **Installs** every package from the official repositories in one `pacman -Syu --needed`
   (which also updates the system); the AUR browser only if you said yes.
4. **Copies** the configuration into your home. Any file it replaces is first backed up to
   `~/.local/state/rice/backups/<time>/` (with a manifest). Files already current are left alone.
5. **Builds** the wallpaper shaders and images, sets GTK/KDE preferences and default apps
   (Thunar, LibreWolf, Neovim), applies the browser and Code - OSS settings, installs the
   language servers that are not in Arch's repositories.
6. **Makes it the default environment** (sudo): the greetd + ReGreet login screen replaces your
   display manager, zsh becomes your login shell, Bluetooth (and NetworkManager if nothing
   manages the network) is enabled, Firefox privacy policies are installed.
7. Logs everything to `~/.local/state/rice/install-<time>.log`.

At the first login the two monitors' IDs are recorded automatically; if left and right come out
swapped, open Super+Shift+M → swap. Re-running the installer is safe. Your own tweaks go in
override files the installer never overwrites: `~/.config/hypr/local.lua`,
`~/.config/zsh/local.zsh`, `~/.config/rofi/local.rasi`, `~/.config/foot/local.ini`, kitty's
`local.conf`, `~/.config/rice/settings.json`, `~/.config/nvim/lua/local.lua`, `~/.config/vis/local.lua`.

## Requirements

- Arch Linux (vanilla install), x86_64, systemd.
- A regular user with `sudo`.
- A GPU with working DRM/KMS. Developed and tested on **AMD**; Intel should work. **NVIDIA**
  needs extra setup (the installer will detect and point you to it). **VMs** need 3D
  acceleration enabled, or Hyprland will not start.
- Multi-monitor setups behind a KVM are a first-class case: monitors are matched by EDID
  description and workspaces return to their monitor after a switch
  ([details](docs/knowledge-base/hardware.md#kvm-hot-unplug-what-hyprland-057-does)).
- Hyprland **0.57 or newer**. This rice uses the Lua config format, which is the only format
  0.57 supports. Configs written for older Hyprland (`hyprland.conf`) do not work here and vice versa.

## Components

| Role | Choice | Notes |
| --- | --- | --- |
| Compositor | Hyprland ≥ 0.57 | Lua config, split into modules; mild gaps (6/3 px), 2 px gradient border, 6 px rounding |
| Terminal | **kitty** (primary), **foot** (secondary) | JetBrains Mono with ligatures + Nerd Font icons; both themed from the palette |
| Editor | **Code - OSS** (`code`, open-source VS Code) | telemetry, experiments and AI features off; palette theme | 
| Terminal editors | **Neovim** (primary), **vis** (secondary), **Helix** | tree-sitter/lexer highlighting and LSP for Elixir, Haskell, SWI-Prolog, Scala, OCaml, Fortran; palette themes; servers outside Arch's repos via opt-in `rice-lsp-setup` |
| Office | **TeX Live** (full), **TeXstudio** (dark, palette syntax colors), **LibreOffice** (generated Quasar theme, white pages) | LaTeX also in Neovim/Helix/vis via texlab; [office.md](docs/knowledge-base/office.md) |
| CLI tools | **btop** (palette theme, vim keys), **htop** (terminal colors), **fastfetch** (palette config) | [cli-tools.md](docs/knowledge-base/cli-tools.md) |
| Cursor | **Capitaine** light (official repos); alternatives listed | [theming.md](docs/knowledge-base/theming.md#cursor-themes) |
| Shell | zsh + **starship** two-line rainbow prompt | full git status, exit code with signal name, meaning and pipeline status; fish-style Tab menu, autosuggestions, syntax highlighting, Up/Down history search, fzf, zoxide |
| Lock / idle | hyprlock (themed, PAM, crash-safe session lock), hypridle | lock at 10 min, monitors off at 11 min, no auto-suspend |
| Wallpaper | **live ASCII Earth + Moon** (Quickshell, two GPU shader passes, 4 fps, both monitors in sync; animates only on empty workspaces) · or the same scene as a still · or your own image (installer question) | [D15](docs/decisions.md#d15-wallpaper-live-ascii-earth-and-moon-gpu-shaders-in-quickshell-owner-2026-10-30) |
| Login | greetd + ReGreet, inside Hyprland | same monitor config as the desktop; no X server |
| Bar | Quickshell, **Orbit Glass**: CPU/memory/load, GPU, per-drive disks, network, Bluetooth, volume + output picker, media | [render](docs/bar/renders/orbit-glass.png), [D14](docs/decisions.md#d14-bar-quickshell-orbit-glass-design-owners-call-2026-10-30) |
| Launcher + menus | rofi 2.x: **Orbit** (apps, `$mod+d`) and **Flight Deck** (all scripted menus) | [concepts](docs/launcher/concepts.html) |
| Keybindings | i3 defaults (`$mod` = Super, `j k l ;`) | [docs/keybindings.md](docs/keybindings.md) |
| Static art | generated from the palette (`tools/spacegen.py`), incl. an Orbiter-style ASCII scene | lock and login screens |
| Notifications | Quickshell's own server: Orbit Glass popups, history panel, do-not-disturb | [D20](docs/decisions.md#d20-notifications-quickshells-own-server-owner-2026-10-30) |
| Screensaver | ASCII sky overlay at 5 min idle, whole scene drifts (anti burn-in), any input ends it | [D21](docs/decisions.md#d21-screensaver-ascii-overlay-burn-in-protection-on-ips-owner-2026-10-30) |
| File managers | **Thunar** (default), **Dolphin** (secondary), both in the palette | [D22](docs/decisions.md#d22-file-managers-thunar-primary-dolphin-secondary-owner-2026-10-30) |
| Browsers | **LibreWolf** (default), **Firefox** (telemetry off, NoScript + uBlock Origin), optional ungoogled-chromium | [docs/knowledge-base/browsers.md](docs/knowledge-base/browsers.md) |
| Blender GPU | ROCm / HIP (`hip-runtime-amd`, `hiprt`) | opt-in |
| Portals | xdg-desktop-portal-hyprland + -gtk | screen sharing, file picker |
| Polkit | hyprpolkitagent | |
| Audio | PipeWire + WirePlumber | |
| Bluetooth | BlueZ, controlled from the bar | power, scan, connect, device battery |

## Launcher and menus

Real renders of the generated rofi themes (`tests/rofi-render.sh`: rofi under Xvfb, so the
translucent corners show black and there is no blur; on Hyprland the panel is frosted glass).

| Orbit: apps (`$mod+d`) | Flight Deck: scripted menus (`$mod+Shift+e`) |
| --- | --- |
| ![Orbit launcher](docs/launcher/renders/orbit.png) | ![Flight Deck session menu](docs/launcher/renders/deck-session.png) |

## Bar

Orbit Glass, rendered from the real QML with sample data (`tests/quickshell/render.py`; no blur
off-compositor). Dropdowns: System, Network, Bluetooth, Audio.

![Orbit Glass bar with its four panels](docs/bar/renders/orbit-glass.png)

## Color scheme

Soft dark, space-tinted, Monokai-derived. Chosen palette: **Quasar**, a blend of round 1's
Pulsar (dark, saturated) and Event Horizon (soft), checked with two contrast models:

- WCAG 2 ratios (accessibility baseline): body text 13.5:1, comments 6.4:1, every accent ≥ 8:1.
- APCA (perceptual, catches dark-mode glare): body text Lc 88 (glare starts above ~92), accents
  held within Lc 58–74 so no token glares or recedes.

- Rationale, rules, roles, ANSI and syntax mappings: [docs/colors/proposals.md](docs/colors/proposals.md)
- Visual comparison with a **live blend dial**: open [docs/colors/preview.html](docs/colors/preview.html) in a browser.
- Try a palette in your current kitty now: each palette on the preview page has a copy-ready `kitty.conf` block.

## Repository layout

```text
CLAUDE.md                 guidance for AI-assisted development (rules, conventions, commands)
install.sh                the installer (clone and run); lib/ holds its modules
lib/                      log, preflight, packages, deploy (copy + backup), files (deploy map), desktop, system
packages/                 package lists per group; ?name = optional (see packages/README.md)
bin/rice-menu             scripted menus (session, clipboard, windows, keys, screenshot)
bin/rice-sky-atlas        renders the ASCII sky's glyph atlas at a monitor's exact cell size
bin/rice-browser-setup    applies browser prefs and palette to every Firefox/LibreWolf profile
bin/rice-code-setup       installs the Code - OSS theme, merges the privacy settings
bin/rice-lsp-setup        per user: language servers not in Arch's repos (ElixirLS, Metals, ocamllsp, fortls), vis-lspc
bin/rice-libreoffice-setup installs the generated LibreOffice theme extension
bin/rice-monitors         records the two panels' EDID descriptions (first login), swap, copy to the login screen
colors/
├── quasar.toml           the palette: single source of truth for every app theme
└── proposals/            design history (round 1 palettes, round 2 Quasar)
config/                   dotfiles as deployed under ~/.config (hypr, quickshell, rofi, kitty, foot, zsh, editors,
                          btop, htop, gtk, xfce4, browsers, code-oss) and /etc/greetd (greetd/)
assets/earth/             Earth land mask for the ASCII sky (from Natural Earth, public domain)
assets/sky/               the still ASCII sky (lock screen, login screen), from tools/spacegen.py
templates/ → themes/quasar/   per-app color templates and their generated output
docs/
├── colors/               proposals.md, preview.html (generated, includes the blend dial)
├── launcher/             concepts.html (generated rofi launcher concepts)
├── decisions.md          decided architecture + open questions
└── knowledge-base/       verified notes: Hyprland 0.57 Lua, hypr tools, Arch, hardware/KVM, rofi, kitty, zsh, editors, theming
tools/                    dev only (Python 3.11+); the installer never uses these
├── palette.py            color math, WCAG + APCA contrast rules, reports
├── blend.py              OKLCH blend of two palettes, normalized to the rules
├── preview.py            renders docs/colors/preview.html
├── launcher_preview.py   renders docs/launcher/concepts.html
├── spacegen.py           palette-colored space art (SVG): wallpaper, starfields, planets
├── earthmask.py          Natural Earth GeoJSON → equirectangular land mask PNG
└── render_theme.py       templates/ → themes/<palette>/ (with --check for drift)
tests/                    rofi-render.sh (real rofi screenshots), lua/ (Hyprland API stub, bind tests),
                          quickshell/ (bar render, mock services), sky/ (ASCII sky frames + timing),
                          browsers/ (policy names checked against Mozilla's and Chromium's sources),
                          terminals/ (kitty keys), vscode/ (theme colors and settings vs VS Code),
                          prompt/ (starship options vs its source), zsh/ (loads the config in real zsh),
                          nvim/ (colorscheme vs Neovim's highlight groups), editors/ (Helix config, theme, languages),
                          cli/ (htop, btop, fastfetch vs their sources), office/ (LibreOffice theme vs
                          its registry schema, TeXstudio keys), installer/ (file layer, dry run, package names)
.github/workflows/ci.yml  shellcheck, theme drift, palette, Hyprland stub, installer; package names in archlinux:latest
```

The target layout for later phases is in [CLAUDE.md](CLAUDE.md#repository-layout-target-create-directories-as-phases-need-them).

## Documentation

| Doc | For |
| --- | --- |
| [docs/knowledge-base/](docs/knowledge-base/README.md) | how things work and what was verified where |
| [docs/knowledge-base/hyprland.md](docs/knowledge-base/hyprland.md) | Hyprland 0.57 Lua config, pitfalls, hyprctl changes |
| [docs/decisions.md](docs/decisions.md) | why things are the way they are; what is still open |
| [docs/keybindings.md](docs/keybindings.md) | the i3 keymap on Hyprland, bind by bind |
| [docs/colors/proposals.md](docs/colors/proposals.md) | palette design and selection |
| [docs/knowledge-base/hardware.md](docs/knowledge-base/hardware.md) | dual 4K via KVM, AMD + ROCm, greetd login |
| [docs/knowledge-base/launcher.md](docs/knowledge-base/launcher.md) | rofi on Wayland: capabilities and limits |
| [docs/knowledge-base/bar.md](docs/knowledge-base/bar.md) | Quickshell bar, notifications, ASCII sky and screensaver: structure, data sources, tests |
| [docs/knowledge-base/browsers.md](docs/knowledge-base/browsers.md) | browser privacy settings and theming, and where each browser reads them |
| [docs/knowledge-base/editor.md](docs/knowledge-base/editor.md) | Code - OSS: telemetry/AI settings and the generated theme |
| [docs/knowledge-base/editors.md](docs/knowledge-base/editors.md) | Neovim, Helix, vis: highlighting and language servers per language |
| [docs/knowledge-base/office.md](docs/knowledge-base/office.md) | TeX Live, TeXstudio, LibreOffice: packages and theming |
| [docs/knowledge-base/cli-tools.md](docs/knowledge-base/cli-tools.md) | htop, btop, fastfetch: config and colors |
| [docs/knowledge-base/arch-install.md](docs/knowledge-base/arch-install.md) | the installer: steps, deploy map, backups, packages |

## Development

Dev tools need Python 3.11+ (for `tomllib`). The installer itself will need only bash and git.

```sh
python3 tools/render_theme.py colors/quasar.toml --check
lua5.4 tests/lua/run.lua config/hypr/hyprland.lua
tests/installer/run.sh
shellcheck -x install.sh lib/*.sh
python3 tools/palette.py check colors/quasar.toml
python3 tools/preview.py --standalone colors/proposals/round2/*.toml colors/proposals/round1/*.toml > docs/colors/preview.html
python3 tools/launcher_preview.py --standalone colors/proposals/round2/quasar.toml > docs/launcher/concepts.html
```

## License

Personal project; no license.
