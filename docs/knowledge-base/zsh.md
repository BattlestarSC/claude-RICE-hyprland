# Zsh

## Approach: no framework

No oh-my-zsh / prezto / zinit by default. Reasons: startup latency, a large amount of
third-party code sourced on every shell, and network fetches at first launch. Arch packages
the plugins that matter; source them directly.

## Packages and plugin paths

[BK] Arch layout; the installer must test each path with `[[ -r ... ]]` before sourcing so a
renamed file degrades to "plugin missing" instead of a broken shell. [TODO-verify] in container.

| Package | File to source |
| --- | --- |
| `zsh-autosuggestions` | `/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh` |
| `zsh-syntax-highlighting` | `/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh` (must be sourced **last**) |
| `zsh-completions` | adds to `fpath` automatically via `/usr/share/zsh/site-functions` |
| `fzf` | `/usr/share/fzf/key-bindings.zsh`, `/usr/share/fzf/completion.zsh` (or `source <(fzf --zsh)` on fzf ≥ 0.48) |
| `starship` | `eval "$(starship init zsh)"`; config `~/.config/starship.toml` |
| `zoxide` | `eval "$(zoxide init zsh)"` |

## File layout

| File | Loaded for | Contents |
| --- | --- | --- |
| `~/.zshenv` | every zsh | `ZDOTDIR` (optional), `XDG_*` defaults, `EDITOR`. Keep tiny; no output. |
| `~/.zprofile` | login shells | the guarded `exec start-hyprland` on VT1 (see [arch-install.md](arch-install.md#starting-the-session)) |
| `~/.zshrc` | interactive shells | options, history, completion, keybinds, plugins, prompt |
| `~/.config/zsh/*.zsh` | sourced from `.zshrc` | split modules: `aliases.zsh`, `completion.zsh`, `plugins.zsh`, `theme.zsh` (generated) |
| `~/.config/zsh/local.zsh` | sourced last if it exists | user overrides; never touched by the installer |

## Theme dependencies on ANSI colors

The shell inherits colors from kitty's ANSI palette, so most theming happens in kitty. The
places that pick ANSI indices directly:

- `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE` defaults to `fg=8` (ANSI bright black). Our ANSI 8 is the
  palette `overlay`, which every proposal holds at ≥ 4.5:1 on the background, so suggestions
  are readable without overriding this. [BK default value]
- `ZSH_HIGHLIGHT_STYLES[...]` for syntax highlighting: set from the generated `theme.zsh` using
  hex (`fg=#7FD7E6`) so it does not depend on ANSI slot order. zsh-syntax-highlighting accepts
  hex colors when the terminal supports truecolor (kitty does) [BK].
- `LS_COLORS` / `eza` colors: generate `EZA_COLORS` from the palette or leave defaults (ANSI-based).
- `fzf`: `FZF_DEFAULT_OPTS="--color=bg+:#302E42,fg:#E4E1EE,hl:#FF6E8A,..."` from palette.
- `bat`: needs a `.tmTheme`; generate one later or use `--theme=ansi`.
- `starship`: palette support via `[palettes.<name>]` in `starship.toml` [BK]; generate it.

## Changing the login shell

```sh
chsh -s /usr/bin/zsh      # prompts for the user's password; /usr/bin/zsh is in /etc/shells once zsh is installed [BK]
```

The installer must check `getent passwd "$USER" | cut -d: -f7` first and skip when already zsh.
