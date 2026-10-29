# Theming pipeline

## Goal

One palette file is the single source of truth. Every app's color config is **generated**
from it. Hand-editing a hex value in an app config is a bug.

## Proposed pipeline

```text
colors/<palette>.toml           (source of truth; roles, not app keys)
        │
        │  tools/render-theme   (dev time; writes committed outputs)
        ▼
themes/<palette>/
  ├── hypr/colors.lua           → Hyprland: return { base = "rgba(...)", ... }
  ├── hypr/colors.conf          → hyprlang $vars for hyprlock / hypridle / hyprtoolkit
  ├── kitty/theme.conf
  ├── zsh/theme.zsh             → syntax-highlight styles, FZF_DEFAULT_OPTS
  ├── waybar/colors.css         → @define-color ...
  ├── starship/palette.toml
  ├── gtk/colors.css            → GTK3/4 @define-color overrides (libadwaita-compatible names)
  └── ...                       (mako/swaync, btop, nvim, bat as they get added)
        │
        │  install.sh           (install time; no generation, only linking)
        ▼
~/.config/...                   (symlinks to the selected theme's files)
```

### Why render at dev time and commit the outputs

- Vanilla Arch has no python; the installer stays pure bash with zero build step.
- Generated files are reviewable in diffs; a palette change shows exactly what moved.
- CI re-renders and fails if committed outputs differ (`git diff --exit-code`).

Trade-off: the repo holds N palettes × M apps of generated files. Acceptable for text files
of a few hundred bytes. Alternative (render at install time with `envsubst`-style `sed`) is
viable but moves template bugs onto user machines.

### Switching themes at runtime

A `rice-theme <name>` script swaps the symlinks, then:

| App | How it picks up the change |
| --- | --- |
| Hyprland | auto-reload on file change (watch semantics through symlinks: [TODO-verify]); else `hyprctl reload` |
| kitty | `auto_reload_config` (default on) [V]; or `kitten @ set-colors --all` |
| waybar | `pkill -SIGUSR2 waybar` reloads config + CSS [BK] |
| zsh | new shells only; existing shells: `source ~/.config/zsh/theme.zsh` |
| GTK apps | restart app; `gsettings set org.gnome.desktop.interface color-scheme prefer-dark` once |
| hyprlock / hyprtoolkit apps | next launch |

## GTK, Qt, cursors, fonts

- **GTK:** set `prefer-dark` via `gsettings` (needs `gsettings-desktop-schemas`, pulled by most
  GTK apps) and `gtk-application-prefer-dark-theme=1` in `~/.config/gtk-3.0/settings.ini` and
  `gtk-4.0/settings.ini` [BK]. libadwaita apps ignore custom themes except via `gtk-4.0/gtk.css`
  color overrides; generate that file from the palette. `nwg-look` is the GUI the wiki recommends. [V wiki master-tutorial]
- **Qt:** `hyprqt6engine` (wiki-recommended) or `qt6ct` with `QT_QPA_PLATFORMTHEME`. [V wiki]
- **Cursor:** set via `hl.env("XCURSOR_THEME", ...)`, `XCURSOR_SIZE`, `HYPRCURSOR_*`, and
  `hyprctl setcursor <theme> <size>` at runtime; also `gsettings ... cursor-theme` for GTK. [V wiki env vars]
- **Fonts:** a Nerd Font for terminal/bar glyphs; `noto-fonts` as the sans fallback (the wiki
  warns that without a sans-serif font text renders as boxes). [V wiki must-have]

## Readability rules that constrain every app theme

1. Body text never on a surface lighter than `surface1`.
2. Accent-colored text only on `base`/`mantle`/`crust`; on `surface1` only for short tokens (≥ 4.5:1 rule).
3. Dark text (`crust`) on accent fills is allowed only for accents passing the 7:1 pill rule (cyan
   is checked; extend `tools/palette.py` before using others as fills).
4. No pure `#000000` / `#FFFFFF` anywhere.
5. Translucency only on chrome (bar, launcher, notifications), never on content windows by default.
