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
  ├── hypr/colors.conf          → hyprlang $vars for hyprlock / hypridle
  ├── hypr/hyprtoolkit.conf     → hyprtoolkit apps (polkit dialog, launcher); hypr-ecosystem.md
  ├── kitty/theme.conf, foot/theme.ini ([colors-dark])
  ├── code-oss/extension/      → Code - OSS theme extension (editor.md)
  ├── zsh/theme.zsh             → syntax-highlight, autosuggest, substring-search, completion menu, FZF_DEFAULT_OPTS, man page colors
  ├── waybar/colors.css         → @define-color ...
  ├── starship/starship.toml    → the whole prompt config with an inline [palettes.rice]
  ├── art/*.svg                 → tools/spacegen.py: wallpaper, panel starfield, planets, ASCII scene (seeded)
  ├── gtk/colors.css            → GTK3/4 @define-color overrides (libadwaita-compatible names)
  ├── quickshell/common/Theme.qml  → QML singleton: palette (`qcolor`), glass tints, fonts, sizes
  ├── quickshell/sky/*.frag     → GLSL 440 for the ASCII sky; palette baked in as `vec3` constants
  ├── gtk-3.0/gtk.css, gtk-4.0/gtk.css, kde/scheme.colors   → see "GTK and file managers"
  ├── firefox/userChrome.css, userContent.css                → browsers.md
  ├── thunderbird/userChrome.css → Thunderbird token overrides (browsers.md#thunderbird)
  ├── qt6ct/colors/rice.conf    → Qt 6 palette (#qt-apps-qt6ct)
  ├── imv/config, zathura/zathurarc → image and PDF viewers (apps.md)
  ├── chromium/policies.json   → managed policies incl. BrowserThemeColor
  ├── btop/themes/rice.theme, fastfetch/config.jsonc        → cli-tools.md
  ├── nvim/, helix/, vis/       → editors.md
  ├── greetd/regreet.css        → login screen (hardware.md)
  ├── libreoffice/extension/, texstudio/texstudio.ini       → office.md
  └── ...
        │
        │  install.sh           (install time; no generation, only copying: D29)
        ▼
~/.config/..., /etc/greetd/     (copies; replaced files backed up; arch-install.md#deploy-map)
```

Generated art is SVG (sharp at 4K, a few KB to ~50 KB). Consumers that need raster images (rofi
`url()` through gdk-pixbuf, hyprpaper) get PNGs from `rsvg-convert` (package `librsvg`) at install
time. Whether gdk-pixbuf in rofi loads SVG directly: [TODO-verify]; rasterizing avoids the question.

Template filters (`tools/render_theme.py`): `hex` `#rrggbb`, `hexa:A` `#rrggbbaa`, `rgba:A`
`rgba(r,g,b,a)`, `bare` `rrggbb`, `vec3` `vec3(r, g, b)` (floats 0–1, for GLSL), `qcolor:A`
`#AARRGGBB` (Qt's alpha-first order; `#rrggbbaa` would be misread by QML), `int` 0xRRGGBB as a decimal integer (LibreOffice registry), `sgr` `r;g;b` (ANSI
truecolor parameters), `rgbcsv` `r,g,b`
(KDE schemes), `cssrgba:A` `rgba(r, g, b, a)` (GTK3 has no 8-digit hex).

Shaders are the one generated output that needs a build step on the target: Qt Quick loads `.qsb`
files, so the installer compiles `themes/<palette>/quickshell/sky/*.frag` with `qsb` from
`qt6-shadertools` (`/usr/lib/qt6/bin/qsb` [TODO-verify path]) using the flags in
`tests/sky/render.py`. Committing `.qsb` binaries instead would avoid the package but put opaque
blobs in diffs.

### Why render at dev time and commit the outputs

- Vanilla Arch has no python; the installer stays pure bash with zero build step.
- Generated files are reviewable in diffs; a palette change shows exactly what moved.
- CI re-renders and fails if committed outputs differ (`git diff --exit-code`).

Trade-off: the repo holds N palettes × M apps of generated files. Acceptable for text files
of a few hundred bytes. Alternative (render at install time with `envsubst`-style `sed`) is
viable but moves template bugs onto user machines.

### Switching themes at runtime

A future `rice-theme <name>` script would copy the other palette's files over these (same backup rules), then:

| App | How it picks up the change |
| --- | --- |
| Hyprland | auto-reload on file change; else `hyprctl reload` |
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
  This rice uses qt6ct (official repos): see [Qt apps (qt6ct)](#qt-apps-qt6ct).
  hyprqt6engine is **AUR-only** [S: search 2026-10-30], so it is not on the default path (D2);
  its `theme:color_scheme` takes an absolute path (no `~` expansion [V: source d0ce29c]) to a
  qt6ct scheme or a KDE `.colors` file, which would theme every Qt app with the same file.
- **Cursor:** set via `hl.env("XCURSOR_THEME", ...)`, `XCURSOR_SIZE`, `HYPRCURSOR_*`, and
  `hyprctl setcursor <theme> <size>` at runtime; also `gsettings ... cursor-theme` for GTK. [V wiki env vars]
- **Cursor themes:** see [Cursor themes](#cursor-themes) below.
- **Fonts:** a Nerd Font for terminal/bar glyphs; `noto-fonts` as the sans fallback (the wiki
  warns that without a sans-serif font text renders as boxes). [V wiki must-have]

## GTK and file managers

Generated per palette (`templates/gtk-3.0/gtk.css`, `templates/gtk-4.0/gtk.css`,
`templates/kde/scheme.colors`); deployed as below.

| Target | File | Mechanism |
| --- | --- | --- |
| GTK3 (Thunar, GTK3 file pickers) | `~/.config/gtk-3.0/gtk.css` + `settings.ini` (`gtk-theme-name=adw-gtk3-dark`) | `@define-color` overrides of adw-gtk3's named colors (`window_bg_color`, `view_bg_color`, `accent_bg_color`, `sidebar_*`, `headerbar_*`, `card_*`, `popover_*`, … [V: adw-gtk3 source 47922ed]) |
| GTK4 / libadwaita | `~/.config/gtk-4.0/gtk.css` | `:root { --window-bg-color: …; }` CSS variables. libadwaita's `@define-color` names are "compatibility colors" that **don't pick up overridden colors** [V: libadwaita `doc/css-variables.md` f2e30ed] |
| Dolphin (and KDE apps) | `~/.local/share/color-schemes/Quasar.colors`; `dolphinrc [UiSettings] ColorScheme=Quasar` | KColorSchemeManager reads `[UiSettings] ColorScheme` from the app's own config and applies it, also outside Plasma [V: kcolorscheme `kcolorschememanager.cpp` 8bb948c; Dolphin `dolphinmainwindow.cpp` 11f42e6 creates the manager and a "Window Color Scheme" menu]. Format follows Breeze Dark [V: KDE/breeze `colors/BreezeDark.colors`] |

### Qt apps (qt6ct)

Decision D41 (2026-10-30, needed so Strawberry is not light): `QT_QPA_PLATFORMTHEME=qt6ct`
(`hypr/conf/env.lua`) makes every Qt 6 app take its style, palette, icons and fonts from
`~/.config/qt6ct/qt6ct.conf`:

- `[Appearance] style=Breeze` (installed for Dolphin; Qt falls back to Fusion if absent),
  `custom_palette=true`, `color_scheme_path=~/.config/qt6ct/colors/rice.conf` (qt6ct expands `~`
  and `$VAR/` [V: qt6ct `src/qt6ct-common/qt6ct.cpp` `resolvePath`]), `icon_theme=Papirus-Dark`;
  `[Fonts] general="IBM Plex Sans,11"`, `fixed="JetBrains Mono,11"` (the short `QFont::fromString`
  form parses [V: Qt 6.12 via PySide6]). Keys [V: qt6ct `src/qt6ct-qtplugin/qt6ctplatformtheme.cpp`
  `readSettings`, GitHub mirror 0.9]. Deployed with `deploy_once`: the qt6ct GUI rewrites it.
- `colors/rice.conf` (generated, `templates/qt6ct/colors/rice.conf`): `[ColorScheme]`
  `active_colors`, `inactive_colors`, `disabled_colors`, each one `#AARRGGBB` per
  `QPalette::ColorRole` in enum order (22 with `Accent`; qt6ct copies Highlight into Accent when a
  file has 21) [V: `loadColorScheme`; enum order checked in Qt 6.12]. Mapping: window `mantle`,
  views `base`, alternate rows and buttons `surface0`, text `text`, selection purple with `crust`
  text, links blue, placeholder `overlay`; disabled text `overlay`.
- KDE apps that create a `KColorSchemeManager` (Dolphin, Kasts) still apply the Quasar `.colors`
  scheme named in their own rc file on top.
- Rendered with PySide6 (Fusion, this palette): table selection, alternating rows, disabled
  button and slider all readable. Not run with the real qt6ct plugin [TODO-verify on Arch].
- Qt 5 apps would need qt5ct; none in the package lists.

Role mapping (both GTK files and the KDE scheme): sidebar `crust`, window/header bar `mantle`,
file view `base`, cards/popovers/dialogs `surface0`, accent and selection **purple with `crust`
text** (8.8:1; every accent passes the 7:1 pill rule with `crust`), destructive/error red,
warning yellow, success green.

Also set by the installer (they are user files, so merged, not overwritten):
- `gsettings set org.gnome.desktop.interface color-scheme prefer-dark`, `gtk-theme adw-gtk3-dark`,
  `icon-theme Papirus-Dark`, `font-name 'IBM Plex Sans 11'`: under Wayland GTK reads these
  (via the settings portal) before `settings.ini` [BK].
- `kwriteconfig6 --file dolphinrc --group UiSettings --key ColorScheme Quasar` and
  `kwriteconfig6 --file kdeglobals --group Icons --key Theme Papirus-Dark` [BK tool; ships with
  KConfig, a Dolphin dependency].
- `xdg-mime default thunar.desktop inode/directory` (Thunar opens folders; Dolphin stays
  available from the launcher and "Open with").
- Dolphin's "Open with" is empty outside Plasma unless a menu file exists: package
  `archlinux-xdg-menu`, `XDG_MENU_PREFIX=arch-` in the session environment, then
  `kbuildsycoca6 --noincremental` [S: forum/blog reports 2024-2026; Arch wiki unreachable].
- `~/.config/xfce4/helpers.rc`: `TerminalEmulator=kitty`: Thunar's "Open Terminal Here" runs
  `exo-open`/`xfce-open --launch TerminalEmulator`, which reads that key and runs the named
  program from `PATH` [V: exo 4.20.0 `exo-execute.c`, libxfce4ui main `xfce-execute.c`].

## Readability rules that constrain every app theme

1. Body text never on a surface lighter than `surface1`.
2. Accent-colored text only on `base`/`mantle`/`crust`; on `surface1` only for short tokens (≥ 4.5:1 rule).
3. Dark text (`crust`) on accent fills is allowed only for accents passing the 7:1 pill rule (cyan
   is checked; extend `tools/palette.py` before using others as fills).
4. No pure `#000000` / `#FFFFFF` anywhere.
5. Translucency only on chrome (bar, launcher, notifications), never on content windows by default.

## Cursor themes

Owner asked for suggestions (2026-10-30) and chose **Capitaine, light variant** (D30). Where the theme name is set: `hypr/conf/env.lua` (`XCURSOR_THEME`; falls back to Adwaita if
the theme is missing), gsettings `cursor-theme` (GTK apps), `/etc/greetd/{hyprland.lua,regreet.toml}`
(login screen). The installer writes all of them from one value:
`RICE_CURSOR=<theme directory name> ./install.sh`.

| Theme | Look | Source | Notes |
| --- | --- | --- | --- |
| **Capitaine** (`capitaine-cursors`, light: `capitaine-cursors-light`) | macOS-like, Breeze-based; dark or white | official repos [V: upstream README "available in the official Arch Linux repositories"; S: archlinux.de extra 4-3] | default; light variant directory name on Arch [TODO-verify]: the installer checks and falls back to `capitaine-cursors`, then Adwaita |
| Breeze (`breeze_cursors`, `Breeze_Light`) | KDE's, neutral | official (`breeze`, already installed for Dolphin) [BK names] | safest match for the Qt apps |
| Adwaita | GNOME default, dark | official, always present | fallback |
| Bibata Modern Ice / Classic | rounded, modern; white or black | AUR `bibata-cursor-theme(-bin)` [S] | most popular "riced" cursor; would need the AUR stage |
| phinger-cursors | flat, minimal, light/dark | AUR `phinger-cursors` [S] | crisp at small sizes |
| Catppuccin cursors (Mocha) | Bibata shapes in pastel accents | AUR [BK] | colors are Catppuccin's, not Quasar's |

Hyprcursor (Hyprland's own scalable cursor format, `HYPRCURSOR_THEME`) needs a theme built for it;
the ones above are XCursor themes, which Hyprland also renders. Size 24 logical (36 physical at
scale 1.5).
