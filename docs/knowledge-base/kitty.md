# Kitty

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
