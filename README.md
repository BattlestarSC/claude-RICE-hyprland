# claude-RICE-hyprland

A complete, soft-dark, space-themed Hyprland desktop for **vanilla Arch Linux**, built around
**Hyprland + kitty + zsh**. One command to install, one palette file to theme everything.

> [!WARNING]
> **Pre-alpha. The installer does not exist yet.** This repository currently contains the
> design foundation: knowledge base, color scheme proposals and palette tooling. Do not expect
> `./install.sh` to work until the Status section says so.

## Status

| Phase | Scope | State |
| --- | --- | --- |
| 0. Foundation | knowledge base, `CLAUDE.md`, README, palette proposals + contrast tooling | **done** |
| 1. Core | `install.sh` (preflight, packages, backup, deploy), Hyprland Lua config, kitty, zsh, theme generator | next; blocked on [open decisions](docs/decisions.md#open) |
| 2. Desktop | bar, launcher, notifications, hyprlock, hypridle, hyprpaper, screenshots, clipboard | planned |
| 3. Polish | GTK/Qt theming, cursor, theme switcher, uninstaller, CI in an Arch container | planned |

## Planned usage

```sh
sudo pacman -S --needed git
git clone https://github.com/BattlestarSC/claude-RICE-hyprland.git
cd claude-RICE-hyprland
./install.sh
```

What the installer will do, in order:

1. **Preflight:** confirm Arch, non-root user, working `sudo`, network, no pacman lock;
   detect GPU vendor and VM; refuse Hyprland < 0.57.
2. **Show the plan:** full package list and every file it will place. One confirmation.
3. **Install packages** from official repositories only, in a single `pacman -Syu --needed` transaction.
4. **Back up** any existing config it would replace to `~/.local/state/<rice>/backups/<timestamp>/`.
5. **Deploy** dotfiles and the selected theme.
6. **Optional, each prompted:** set zsh as login shell, auto-start Hyprland on TTY1, display manager, NVIDIA notes.
7. Log everything to `~/.local/state/<rice>/install-<timestamp>.log`.

Re-running is safe. Your own tweaks go in override files (`~/.config/hypr/local.lua`,
`~/.config/zsh/local.zsh`) that the installer never touches.

## Requirements

- Arch Linux (vanilla install), x86_64, systemd.
- A regular user with `sudo`.
- A GPU with working DRM/KMS. AMD and Intel work out of the box. **NVIDIA** needs extra setup
  (the installer will detect and point you to it). **VMs** need 3D acceleration enabled, or
  Hyprland will not start.
- Hyprland **0.57 or newer**. This rice uses the Lua config format, which is the only format
  0.57 supports. Configs written for older Hyprland (`hyprland.conf`) do not work here and vice versa.

## Components (planned)

| Role | Choice | Notes |
| --- | --- | --- |
| Compositor | Hyprland ≥ 0.57 | Lua config, split into modules |
| Terminal | kitty | auto-reloads config; colors in a generated `theme.conf` |
| Shell | zsh + starship | no framework; autosuggestions, syntax highlighting, fzf, zoxide |
| Lock / idle | hyprlock, hypridle | |
| Wallpaper | hyprpaper | |
| Bar | waybar (proposed) | [O3](docs/decisions.md#o3-status-bar) |
| Launcher | hyprlauncher and/or fuzzel (proposed) | [O4](docs/decisions.md#o4-launcher) |
| Notifications | mako (proposed) | [O5](docs/decisions.md#o5-notifications) |
| Portals | xdg-desktop-portal-hyprland + -gtk | screen sharing, file picker |
| Polkit | hyprpolkitagent | |
| Audio | PipeWire + WirePlumber | |

## Color scheme

Four proposals, all Monokai-derived, all on a blue-violet "space" base, all validated against
the same contrast rules (body text 11–15.5:1, comments ≥ 4.5:1, every accent ≥ 6:1).

| Proposal | Character |
| --- | --- |
| **Nebula** (recommended) | Monokai Pro accents on violet-tinted deep space. Balanced. |
| Deep Field | Cool navy, highest contrast, strongest space mood. |
| Event Horizon | Desaturated, lowest glare, for dim rooms. |
| Pulsar | Original Monokai saturation on near-black. Punchiest. |

- Rationale, roles, ANSI and syntax mappings: [docs/colors/proposals.md](docs/colors/proposals.md)
- Visual comparison with mockups: open [docs/colors/preview.html](docs/colors/preview.html) in a browser.
- Try one in your current kitty now: the preview page has a copy-ready `kitty.conf` block per palette.

## Repository layout

```text
CLAUDE.md                 guidance for AI-assisted development (rules, conventions, commands)
colors/proposals/*.toml   palette sources (one per proposal)
docs/
├── colors/               proposals.md, preview.html (generated)
├── decisions.md          decided architecture + open questions
└── knowledge-base/       verified notes on Hyprland 0.57 Lua, hypr tools, Arch, kitty, zsh, theming
tools/
├── palette.py            contrast validator / report (dev only)
└── preview.py            renders docs/colors/preview.html from the palettes (dev only)
```

The target layout for later phases is in [CLAUDE.md](CLAUDE.md#repository-layout-target-create-directories-as-phases-need-them).

## Documentation

| Doc | For |
| --- | --- |
| [docs/knowledge-base/](docs/knowledge-base/README.md) | how things work and what was verified where |
| [docs/knowledge-base/hyprland.md](docs/knowledge-base/hyprland.md) | Hyprland 0.57 Lua config, pitfalls, hyprctl changes |
| [docs/decisions.md](docs/decisions.md) | why things are the way they are; what is still open |
| [docs/colors/proposals.md](docs/colors/proposals.md) | palette design and selection |

## Development

Dev tools need Python 3.11+ (for `tomllib`). The installer itself will need only bash and git.

```sh
python3 tools/palette.py check colors/proposals/*.toml
python3 tools/preview.py --standalone colors/proposals/*.toml > docs/colors/preview.html
```

## License

Not chosen yet ([O10](docs/decisions.md#o10-license)). Until a license is added, all rights are reserved.
