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
`~/.config/rice/settings.json`), 10-bit output, mild gaps + rounding, hyprlock + hypridle,
Quickshell notifications + volume OSD, ASCII screensaver, Thunar + Dolphin, LibreWolf/Firefox (+ optional
ungoogled-chromium) with privacy policies, Thunderbird (prefs + palette userChrome), colored man pages,
generated `hyprtoolkit.conf`, kitty + foot, Code - OSS (telemetry and AI off),
Neovim (primary) + vis + Helix with LSPs for Elixir/Haskell/SWI-Prolog/Scala/OCaml/Fortran,
htop/btop/fastfetch, office (full TeX Live, TeXstudio, LibreOffice with a generated theme), Capitaine cursor, installer that copies with
backups and makes the rice the default environment (D29).
Present beyond docs: theme generator + templates, generated `themes/quasar/`, `config/rofi/`,
`config/quickshell/` (bar, services, sky), `config/hypr/hyprland.lua` + `conf/{binds,env,monitors,input,look,layers,rules,session,autostart}.lua`,
`config/hypr/{hyprlock,hypridle}.conf`, `config/{gtk-3.0,gtk-4.0,xfce4,browsers,thunderbird,kitty,foot,code-oss,nvim,helix,vis,btop,htop,greetd}/`,
`install.sh` + `lib/` + `packages/`, `bin/rice-{menu,sky-atlas,browser-setup,code-setup,lsp-setup,monitors,libreoffice-setup}`,
`.github/workflows/ci.yml`, tests.
Shell: zsh (`home/.zsh*`, `config/zsh/`) with a generated starship prompt and theme.
**Nothing has run on real hardware yet**: the installer is tested with dry runs and a throwaway
home, package names only by CI in `archlinux:latest`. **Not yet present:** `uninstall.sh`, a theme
switcher. Quickshell code is render-tested
with PySide6 and mocks but has **never run inside Quickshell**; treat `Bar.qml`, `Wallpaper.qml`,
`shell.qml`, `OsdWindow.qml` and `services/` as unverified. Decided and open questions are in
[docs/decisions.md](docs/decisions.md). Do not guess answers to open decisions in code; ask the
owner or implement behind an obvious, documented default.

Primary target machine (D8): AMD RX 6000 / Navi 21 (gfx1030), two 27" 4K ASUS ProArt panels through a Level1Techs dual-DP KVM that
**removes the outputs when switched away**, Blender with HIP/ROCm; it currently logs in through SDDM, which the rice replaces with greetd +
ReGreet (D7). Every
monitor-related change must consider hot-unplug; see [hardware.md](docs/knowledge-base/hardware.md).
**Owner (D37): no hardware-specific configs.** New configs must work on any machine (detect at
runtime or use generic defaults); the D8-specific monitor setup is listed for generalization in O16.
Keybindings follow i3's defaults ([docs/keybindings.md](docs/keybindings.md)); do not repurpose an
i3 default key, and give every new bind a `description` (it feeds the in-session cheat sheet).

## Read before changing anything

| Task | Read first |
| --- | --- |
| Any Hyprland config | [docs/knowledge-base/hyprland.md](docs/knowledge-base/hyprland.md) |
| hyprlock / hypridle / hyprpaper / launcher | [docs/knowledge-base/hypr-ecosystem.md](docs/knowledge-base/hypr-ecosystem.md) |
| Installer, packages, session startup | [docs/knowledge-base/arch-install.md](docs/knowledge-base/arch-install.md), [packages/README.md](packages/README.md) |
| Colors, any app theme | [docs/knowledge-base/theming.md](docs/knowledge-base/theming.md), [docs/colors/proposals.md](docs/colors/proposals.md) |
| kitty / foot / zsh | [docs/knowledge-base/kitty.md](docs/knowledge-base/kitty.md), [docs/knowledge-base/zsh.md](docs/knowledge-base/zsh.md) |
| Monitors, GPU, ROCm, login (greetd) | [docs/knowledge-base/hardware.md](docs/knowledge-base/hardware.md) |
| rofi, launcher, scripted menus | [docs/knowledge-base/launcher.md](docs/knowledge-base/launcher.md) |
| Status bar, telemetry sources, Quickshell, notifications, ASCII sky, screensaver | [docs/knowledge-base/bar.md](docs/knowledge-base/bar.md) |
| GTK/Qt app theming, file managers | [docs/knowledge-base/theming.md](docs/knowledge-base/theming.md) |
| Browsers (policies, prefs, userChrome) | [docs/knowledge-base/browsers.md](docs/knowledge-base/browsers.md) |
| Code - OSS (settings, theme extension) | [docs/knowledge-base/editor.md](docs/knowledge-base/editor.md) |
| Neovim / Helix / vis, language servers | [docs/knowledge-base/editors.md](docs/knowledge-base/editors.md) |
| htop / btop / fastfetch | [docs/knowledge-base/cli-tools.md](docs/knowledge-base/cli-tools.md) |
| TeX Live, TeXstudio, LibreOffice | [docs/knowledge-base/office.md](docs/knowledge-base/office.md) |
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
bin/                        user commands deployed to ~/.local/bin (rice-menu, rice-sky-atlas, rice-browser-setup, rice-code-setup, rice-lsp-setup, rice-monitors)
tools/                      dev-only tooling (python): palette.py, preview.py, render-theme
tests/                      rofi-render.sh (themes under Xvfb), lua/ (hl API stub + bind/rule/event tests),
                            quickshell/ (bar render with mocks), sky/ (ASCII sky frames + timing),
                            installer/ (file layer + dry run; package names in Arch), cli/, editors/, nvim/
docs/                       knowledge-base/, colors/, decisions.md
```

## Commands

```sh
python3 tools/render_theme.py colors/quasar.toml           # templates/ -> themes/quasar/
python3 tools/render_theme.py colors/quasar.toml --check   # fails if committed themes are stale
lua5.4 tests/lua/run.lua config/hypr/hyprland.lua         # whole config: dispatchers, keys, option names, rule keys, events
python3 tests/lua/gen_options.py <hyprland-wiki checkout> > tests/lua/options.lua   # refresh valid option names
python3 tests/lua/gen_rules.py <hyprland-wiki checkout> > tests/lua/rules.lua       # refresh rule keys + event names
shellcheck -x install.sh lib/*.sh bin/rice-menu bin/rice-sky-atlas bin/rice-browser-setup bin/rice-code-setup bin/rice-lsp-setup bin/rice-monitors bin/rice-libreoffice-setup tests/rofi-render.sh tests/zsh/run.sh tests/installer/*.sh
tests/installer/run.sh                                     # installer file layer in a throwaway home (+ dry run on Arch as non-root)
tests/installer/check_packages.sh                          # inside Arch after pacman -Sy: every packages/*.txt name exists
./install.sh --dry-run                                     # on Arch: every action printed, nothing changed
python3 tests/office/check_office.py <libreoffice core 26.8> <texstudio>   # LibreOffice theme vs registry schema, TeXstudio keys/format ids
python3 tests/cli/check_cli.py <htop 3.5.3> <btop v1.4.8> <fastfetch 2.70.0>   # checkouts; htoprc keys, btop theme/conf, fastfetch schema
python3 tests/terminals/check_kitty.py <kitty checkout>/kitty/options/definition.py   # kitty keys
python3 tests/vscode/check_theme.py <vscode checkout>            # theme colors + settings (see docstring)
python3 tests/prompt/check_starship.py <starship v1.25.1 checkout>   # starship options, palette names
python3 tests/nvim/check_colorscheme.py <neovim v0.12.3 checkout> [<nvim-tree>]   # every tree-sitter capture + @lsp.type.* defined; NvimTree names
lua5.4 tests/nvim/check_explorer.lua <nvim-tree> <bufferline>   # explorer.lua options vs the plugins' defaults, API calls
python3 tests/editors/check_helix.py <helix 25.07.1 checkout>         # config keys, theme scopes, languages.toml
tests/zsh/run.sh                                           # loads the zsh config in real zsh; needs zsh (+ plugins)
python3 tests/browsers/check_policies.py <policy-templates checkout> <chromium policies.yaml>   # see its docstring
python3 tests/browsers/check_thunderbird.py <comm-central checkout>   # userChrome tokens, prefs, Dark theme id
python3 tests/hypr/check_hyprtoolkit.py <hyprtoolkit v0.6.0 checkout>   # hyprtoolkit.conf keys
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
python3 tools/spacegen.py colors/quasar.toml ascii 3840 2160 --cell 12x24 > assets/sky/still-3840x2160.svg   # lock/login background; also: wallpaper, starfield, planet
python3 tools/bar_preview.py --standalone colors/quasar.toml > docs/bar/concepts.html
```

Round-1 palettes fail the APCA rules by design (they predate them); only round 2 and later must pass.
`tools/preview.py` embeds a JavaScript port of `palette.py`/`blend.py` for the blend dial. If you change
the color math or blend constants, change both and confirm the dial's default output still equals
`quasar.toml` (same hex values).

Planned (add here when they exist): `Hyprland --verify-config -c <file>`. When the target Hyprland version changes, refresh the
dispatcher list in `tests/lua/hl_stub.lua` from `src/config/lua/bindings/LuaBindingsDispatchers.cpp`.

Regenerate `docs/colors/preview.html` and `docs/launcher/concepts.html` whenever a palette or a
generator changes, in the same commit; also `assets/sky/still-3840x2160.svg` when the palette changes.

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
  Areas: `hypr`, `kitty`, `zsh`, `bar`, `theme`, `colors`, `apps` (browsers, file managers, other app configs), `installer`, `docs`, `tools`, `ci`.

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
- Firefox on Linux reads `/etc/<app>/policies/policies.json` **instead of** the install's
  `distribution/policies.json`: never write `/etc/librewolf/...` (it would discard LibreWolf's
  own policies).
- Firefox theme CSS variables are internals and get renamed; check `LightweightThemeConsumer.sys.mjs`.
- Notification text must stay `Text.PlainText`; apps send markup regardless of advertised caps.
- The volume OSD reacts to Pipewire change signals, which also fire for initial values: it is
  disarmed for 2 s at start and after the default sink changes. Keep that, or it flashes at login.
- Thunderbird's shadow roots recompute `--layout-*` from tokens (`layout.css` is `:host, :root`):
  theme the tokens (`--color-gray-*`, `--color-*-dark`), not only `--layout-*`, and keep `!important`.
- Colored man pages need `GROFF_NO_SGR=1`; without it grotty sends SGR and `LESS_TERMCAP_*` never applies.
- `Quickshell.screens` order is not "left first"; use `Screens.primary`.
- foot ≥ 1.26 uses `[colors-dark]`; 1.28 refuses to start with the old `[colors]`. Most foot
  examples online (and the gitlab mirror) are older. foot comments are `#` only.
- foot/kitty includes: a missing `include` is an error in both; kitty's `globinclude` is not.
- Code - OSS ships a Copilot `defaultChatAgent` even in the OSS build; `chat.disableAIFeatures`
  is what hides it. VS Code `settings.json` is JSONC: never rewrite one jq cannot parse.
- A VS Code extension folder copied into `~/.vscode-oss/extensions` is not picked up; install a VSIX.
- zsh plugin order is fixed: theme vars before plugins, syntax-highlighting last but one,
  history-substring-search after it. Keep `NO_FLOW_CONTROL` (Ctrl+S searches the Tab menu).
- starship's directory segment ends differently inside git work trees (`repo_root_format`); if you
  touch the directory or git modules, keep the arrow hand-over intact (zsh.md#prompt-starship).
- The starship config is fully generated (one file, inline palette): edit the template.
- Neovim plugins are pinned commits in `config/nvim/lua/rice/plugins.lua` (`vim.pack`, 0.12 only).
  nvim-treesitter is the **main** branch: no `require('nvim-treesitter.configs').setup`, needs
  `tree-sitter-cli` ≥ 0.26.1 + a C compiler. Most nvim-treesitter examples online are `master`.
- `.pl` is Prolog in all three editors, and each needs its own override (Neovim `g:filetype_pl`;
  Helix: perl's `file-types` minus `pl`; vis: ftdetect tables). Keep them in sync.
- Helix rejects unknown `[editor]` keys and silently falls back to defaults; Arch's binary is
  `helix`, not `hx`.
- Installer: a new config file must be added to the deploy map in `lib/files.sh` (and the table in
  arch-install.md#deploy-map), or it is never installed. Files it rewrites before comparing
  (`env.lua` cursor, `monitors.lua` panel IDs, greeter files) must stay byte-identical across
  re-runs, or every run makes a backup. A new package goes in `packages/*.txt`; prefix `?` until CI
  has seen it in Arch.
- Installer bash runs under `set -Eeuo pipefail` with an ERR trap: a function whose last command
  is a false `[[ … ]] && …` returns 1 and aborts the install. End such functions with `return 0`.
- The cursor theme name appears in `hypr/conf/env.lua`, `config/greetd/{hyprland.lua,regreet.toml}`
  and gsettings; the installer substitutes `capitaine-cursors-light` in all of them. Keep that
  literal as the default everywhere.
- `shell.qml` pins Quickshell's data dir (`//@ pragma DataDir $BASE/rice/quickshell`); the sky
  atlases are found there. Pragmas must come before the first `import` line.
- Configs an app rewrites on exit (btop.conf, htoprc, texstudio.ini) are deployed with
  `deploy_once` (only if absent); everything else with `deploy_file`. Pick the right one.
- LibreOffice: theming is off by default in 26.8 (`LibreOfficeTheme = 0`); the theme extension turns
  it on. Values in the user's `registrymodifications.xcu` override any extension: that is why
  `rice-libreoffice-setup` removes exactly three items. Registry colors are decimal ints
  (template filter `int`). XML templates (.xcu/.xml) get no generated header (nothing may precede
  `<?xml`); TeXstudio's INI header uses `;` (`HEADER_BY_NAME` in render_theme.py).
- The greeter runs as user `greeter`: anything it needs (monitor config, CSS, wallpaper) must be
  copied under `/etc/greetd/`, not referenced from `~`.
