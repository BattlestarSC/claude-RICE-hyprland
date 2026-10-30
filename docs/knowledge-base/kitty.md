# Terminals: kitty (primary) and foot (secondary)

Option names below were checked against kitty's `kitty/options/definition.py` on the `master`
branch (commit dated 2026-10-29). [V: kovidgoyal/kitty source, 2026-10-29]

## Files

- `~/.config/kitty/kitty.conf`; `include <file>` pulls in other files (relative to the config dir).
- Plan: `kitty.conf` holds behavior; `include theme.conf` holds generated colors only. Swapping
  the palette rewrites `theme.conf` and nothing else.

## Reload

- **`auto_reload_config` (default `0.1` s)**: kitty reloads config files automatically when they
  change, debounced by that delay. Only works if `kitty.conf` existed when kitty started.
  Negative value disables. [V]
- Manual: `reload_config_file` action, default shortcut `kitty_mod+f5` (`ctrl+shift+f5`). [V]
- Live recolor of running windows without touching config: `kitten @ set-colors --all <file>`
  (requires `allow_remote_control` + `listen_on`) [BK]. With auto-reload in place this is only
  needed for temporary previews.

## Color keys (what the theme generator must emit)

| Key | Palette role |
| --- | --- |
| `foreground` / `background` | `text` / `base` |
| `selection_foreground` / `selection_background` | `text` / `surface1` |
| `cursor` / `cursor_text_color` | palette `meta.cursor` / `base` |
| `url_color` | `blue` |
| `active_border_color` / `inactive_border_color` / `bell_border_color` | gradient start / `surface2` / `yellow` (kitty-internal splits only) |
| `active_tab_foreground` / `active_tab_background` | `crust` / gradient start |
| `inactive_tab_foreground` / `inactive_tab_background` | `subtext` / `mantle` |
| `tab_bar_background` | `crust` |
| `mark1_*` … `mark3_*` | optional, from accents |
| `color0` … `color15` | ANSI map, see [docs/colors/proposals.md](../colors/proposals.md#ansi-mapping) |

kitty also supports `color16`–`color255`; leave them at defaults (the xterm 256 cube) so
256-color apps keep working.

## Transparency and blur under Hyprland

- `background_opacity` (0–1) only affects cells using the **default** background. Apps that
  paint their own background (nvim with a colorscheme bg, tmux status) stay opaque. [V]
- `background_blur` works on Wayland **only when the compositor supports the background-blur
  extension protocol**. Whether Hyprland 0.57 implements it: [TODO-verify]. Hyprland can blur
  any translucent window itself via `decoration.blur`, so this rice relies on that, not on kitty's option.
- Readability position for this rice: terminal **opaque by default** (`background_opacity 1.0`).
  Translucency lowers effective contrast unpredictably depending on what is behind the window.
  Offer `0.92` as an opt-in.

## Other options worth setting

| Option | Value | Why |
| --- | --- | --- |
| `font_family` | `JetBrainsMono Nerd Font` (pending font decision) | glyphs for prompt/bar icons |
| `window_padding_width` | `8`–`12` | breathing room; matches Hyprland gaps |
| `confirm_os_window_close` | `0` or `-1` | avoid prompt on every close; `-1` only prompts with running programs [BK] |
| `shell_integration` | `enabled` (default) | prompt marks, cwd tracking; zsh is supported [V] |
| `tab_bar_style` | `powerline` or `separator` | choices: fade, hidden, powerline, separator, slant, custom [V] |
| `cursor_trail` | e.g. `3` (ms threshold) | optional "comet" effect; fits the space theme, off by default [V] |
| `enable_audio_bell` | `no` | [BK] |

## Verification

```sh
kitty --version
kitty +runpy 'from kitty.config import *; print("ok")'   # sanity: kitty's python runs
kitty --debug-config | less                              # effective config incl. includes [BK]
```

## This rice's kitty (`config/kitty/kitty.conf`, 2026-10-30)

Every key checked against `kitty/options/definition.py` @ 02b2b10 (2026-10-29) by
`tests/terminals/check_kitty.py`. [V]

- `include theme.conf` (generated: `themes/<palette>/kitty/theme.conf`: colors, tab bar, marks,
  `cursor_trail_color`, ANSI 0–15 per the palette's ANSI map).
- Font **JetBrains Mono** (unpatched, `ttf-jetbrains-mono` 2.304 in extra [S]) 11 pt with
  **ligatures everywhere** (`disable_ligatures never`; JetBrains Mono's ligatures are its `calt`
  feature, on by default).
- **Nerd Font icons** via `symbol_map` to `Symbols Nerd Font Mono` (`ttf-nerd-fonts-symbols-mono`
  3.4.0 in extra [S]): ranges are the private-use blocks actually present in Nerd Fonts 3.4.0's
  symbol font plus U+23FB–23FE, U+2665, U+26A1, U+2B58 (read from the font's cmap with fontTools).
  Single-cell icons regardless of the text font; kitty's own bundled Nerd symbols stay as a last
  fallback [V: kitty changelog]. foot gets the same font pair as a fallback list (foot renders no
  ligatures [BK]).
- Block cursor, no blink, `cursor_trail 3` (the trail follows jumps after the cursor rested 3 ms;
  purple), `cursor_trail_decay 0.1 0.3`.
- 10 000 lines scrollback, curly URL underlines, no copy-on-select, `strip_trailing_spaces smart`.
- No audio or visual bell; `window_alert_on_bell yes` (urgency hint to Hyprland).
- `window_padding_width 6 10` (pt: vertical, horizontal; one or two values like CSS [V]).
- `confirm_os_window_close -1`: with shell integration, only windows running a command count [V].
- Opaque (`background_opacity 1.0`); powerline tab bar with round separators, at the bottom.
- `update_check_interval 0`: only official binaries check for updates at all [V], distro builds
  never do; set anyway.
- User overrides: `globinclude local.conf`. A plain `include` of a missing file logs an error;
  `globinclude` with no match is silently empty [V: `kitty/conf/utils.py`].

## foot (`config/foot/foot.ini`)

Current release **1.28.0** [S: nixpkgs `pkgs/by-name/fo/foot/package.nix`, 2026-10-30]. foot's
home is codeberg, which is unreachable from the build environment; the gitlab mirror stops at
1.13.1 (2022). Facts below are labelled accordingly.

- **Colors moved**: `[colors]` was deprecated in 1.26.0 in favor of `[colors-dark]` /
  `[colors-light]`, and foot 1.28.0 reportedly refuses to start with `[colors]` [S: catppuccin/foot
  PR #24, omarchy and DankMaterialShell issues, 2026]. Default theme is dark unless
  `initial-color-theme=light` [S: foot.ini(5) via search]. The rice writes `[colors-dark]` only.
- `[colors-dark]` keys used: `alpha`, `foreground`, `background`, `cursor=<text> <cursor>`
  (the cursor color lives in the colors section now), `selection-foreground/-background`, `urls`,
  `jump-labels`, `search-box-no-match`, `search-box-match`, `regular0-7`, `bright0-7`; values
  `RRGGBB` without `#` [S: catppuccin/foot `themes/catppuccin-mocha.ini`, current].
- `include=` accepts absolute paths and `~/`; a file that cannot be opened is a config error
  [V: `config.c` @ 1.13.1 mirror]. Hence the installer creates an empty `~/.config/foot/local.ini`
  if absent, and `foot.ini` includes `theme.ini` first and `local.ini` last.
- Comments start with `#` only [V: same source]; the generated header uses `#`.
- Other keys (`[main] font, pad`, `[scrollback] lines`, `[cursor] style, blink`,
  `[mouse] hide-when-typing`, `[bell] urgent`) are present in 1.13.1 [V] and not reported as
  changed since [S]. Verify with `foot --check-config` on the target [TODO-verify].
