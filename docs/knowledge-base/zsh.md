# Zsh

## Approach: no framework

No oh-my-zsh / prezto / zinit by default. Reasons: startup latency, a large amount of
third-party code sourced on every shell, and network fetches at first launch. Arch packages
the plugins that matter; source them directly.

## Packages and plugin paths

All four plugin packages are in `extra` [S: archlinux.org listings via search, 2026-10-30:
autosuggestions 0.7.1, syntax-highlighting 0.8.0, history-substring-search 1.1.0, completions
0.35.0]. File paths: [BK] Arch layout; `config/zsh/plugins.zsh` tests each path with `[[ -r ... ]]` before sourcing so a
renamed file degrades to "plugin missing" instead of a broken shell. [TODO-verify] in container.

| Package | File to source |
| --- | --- |
| `zsh-autosuggestions` | `/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh` |
| `zsh-syntax-highlighting` | `/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh` (must be sourced **last**) |
| `zsh-completions` | adds to `fpath` automatically via `/usr/share/zsh/site-functions` |
| `zsh-history-substring-search` | `/usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh` (after syntax highlighting) |
| `fzf` | `/usr/share/fzf/key-bindings.zsh`, `/usr/share/fzf/completion.zsh` (or `source <(fzf --zsh)` on fzf ≥ 0.48) |
| `starship` | `eval "$(starship init zsh)"`; config `~/.config/starship.toml` |
| `zoxide` | `eval "$(zoxide init zsh)"` |

## File layout

| File | Loaded for | Contents |
| --- | --- | --- |
| `~/.zshenv` | every zsh | `ZDOTDIR` (optional), `XDG_*` defaults, `EDITOR`. Keep tiny; no output. |
| `~/.zshrc` | interactive shells | options, history, completion, keybinds, plugins, prompt |
| `~/.config/zsh/*.zsh` | sourced from `.zshrc`, in this order | `options`, `history`, `theme` (generated), `completion`, `keybinds`, `aliases`, `plugins`, `prompt`, `local` (yours), `late` |
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

## This rice's zsh (2026-10-30)

Files: `home/.zshenv`, `home/.zshrc`, `config/zsh/*.zsh`, generated
`themes/<palette>/zsh/theme.zsh`. Tested by `tests/zsh/run.sh` (real zsh, throwaway HOME, fails
on any stderr output, missing option, style or binding).

### Load order and why

`theme` before the plugins: zsh-syntax-highlighting and zsh-autosuggestions set their defaults
with `: ${VAR:=default}`, so values set earlier win [V: main-highlighter.zsh @ e6683f2].
`completion` before `plugins` (fzf wraps Tab and passes through to the menu when there is no `**`).
`late` last: zsh-syntax-highlighting must be the last plugin that wraps widgets [V: its
INSTALL.md], and zsh-history-substring-search must load after it [V: its README]; these two
instructions together fix the order syntax-highlighting → history-substring-search.

### Fish-style Tab selector (`config/zsh/completion.zsh`)

zsh's own menu selection (`zsh/complist`), no extra package (fzf-tab exists only in the AUR [S]).
- `zstyle ':completion:*' menu select` + `AUTO_MENU`: first Tab lists, second Tab enters the
  selector; arrows, Tab, Shift+Tab move a highlighted bar; Enter accepts; `/` accepts a directory
  and continues into it (`accept-and-infer-next-history`); Ctrl+S / Ctrl+R search inside the menu
  (`history-incremental-search-*` in the `menuselect` keymap); Ctrl+G cancels [V: mod_complist.yo].
- Scrolling: lists taller than the screen scroll line by line; `select-prompt` shows
  "%m of %M · %p" (match position, Top/Bottom/percent) [V: compsys.yo list-prompt escapes].
- Group headers (`group-name ''` + `descriptions` format), descriptions (`verbose`), directories
  first, case-insensitive and partial-word matching (`matcher-list`), `_approximate` for typos.
- Colors: selected entry `ma=48;2;<purple>;38;2;<crust>;1` (24-bit SGR inside complist's
  `\e[`…`m`); file types from `LS_COLORS` (set from `dircolors -b` when unset: stock Arch leaves
  it unset); headers via `%F{#RRGGBB}` (prompt escapes accept the zle color forms, which include
  `#` + RGB hex [V: prompt.yo, zle.yo "Character Highlighting"]).
- `NO_FLOW_CONTROL` so Ctrl+S reaches zsh instead of freezing the terminal.

### Other fish-like behavior

zsh-autosuggestions (grey history/completion suggestion; Right/End accept, Alt+Right one word),
zsh-syntax-highlighting (main + brackets, Monokai roles from the palette),
zsh-history-substring-search (Up/Down match what is typed), fzf (Ctrl+R, Ctrl+T, Alt+C,
`source <(fzf --zsh)` [V: fzf man page]), zoxide (`z`), eza for `ls` (`--icons=auto` [V: eza man]).

### Prompt (starship)

Decision: **starship**, not powerlevel10k. p10k's README (2026-10-30): "THE PROJECT HAS VERY
LIMITED SUPPORT / NO NEW FEATURES ARE IN THE WORKS / MOST BUGS WILL GO UNFIXED" [V], and it is
AUR-only now [S]. starship 1.25.1 is in `extra` [S] and has a "gruvbox-rainbow" preset with the
same chained-arrow structure [V: docs/public/presets/toml].

`templates/starship/starship.toml` → `~/.config/starship.toml` (whole file generated: starship
reads one file, and the palette must be inline as `[palettes.rice]`). Every module option checked
against `src/configs/*.rs` @ v1.25.1 by `tests/prompt/check_starship.py` (also checks palette
names in styles and `$module`s in the format).

Layout, two lines:
- Left chain: OS icon (+ `user@host` only over SSH or as root) → directory (blue) → git (green:
  branch or detached commit/tag, rebase/merge state with progress, `+added -deleted` line
  counts, `=conflicted ⇡ahead ⇣behind ?untracked $stashed !modified +staged »renamed ✘deleted`
  with counts).
- Chaining an optional segment needs the previous segment to know what follows. Trick used: the
  directory module renders `repo_root_format` inside a work tree (when `repo_root_style` is set
  and the path is not truncated; `truncation_length = 0`) [V: `modules/directory.rs`], so it can
  end with an arrow into green there and with a closing arrow elsewhere; `git_status`, rendered in
  every work tree, draws the git segment's closing arrow.
- Right side (left-pointing arrow tags): **exit status** only on failure: code, signal name for
  128+n (`130 INT`, `137 KILL`), meaning (`1 ERROR`, `2 USAGE`, `126 NOPERM`, `127 NOTFOUND`, the
  sysexits 64–78), and with `pipestatus = true` every command of a pipeline (`1 ERROR │ 0`)
  [V: `modules/status.rs`]; duration (≥ 2 s); background jobs; Python/Node/Rust/Go versions in
  their projects; clock.
- Line 2: `╰─❯`, green after success, red after failure.

Not verified here: the rendered prompt itself. Running a downloaded starship binary in the build
environment was not permitted, so the prompt has only been validated against starship's source
[TODO-verify: open a terminal on the target, check a git repo, `false | true`, `sleep 3`, Ctrl+C].
