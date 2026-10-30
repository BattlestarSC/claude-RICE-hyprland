# Terminal editors: Neovim, Helix, vis

Owner's order (2026-10-30): **Neovim** primary, **vis** secondary, **Helix** also set up. Target
languages: Elixir, Haskell, SWI-Prolog, Scala, OCaml, Fortran; "full syntax highlighting and LSPs
as possible". Code - OSS is a separate page ([editor.md](editor.md)).

Labels as in [README.md](README.md#verification-labels). Sources read 2026-10-30 unless noted.

## Coverage matrix

| Language | Neovim highlighting | Helix highlighting | vis highlighting | Server (all three editors) | Server comes from |
| --- | --- | --- | --- | --- | --- |
| Elixir (+ HEEx, EEx) | tree-sitter `elixir`, `heex`, `eex` | tree-sitter (built in) | lexer `elixir` (no HEEx) | ElixirLS `elixir-ls` | GitHub release, `rice-lsp-setup elixir` |
| Haskell | tree-sitter `haskell` | tree-sitter | lexer `haskell` | `haskell-language-server-wrapper --lsp` | pacman `haskell-language-server` [S] |
| SWI-Prolog | regex `syntax/prolog.vim` (no parser exists) | tree-sitter `prolog` (built in) | lexer `prolog` (ISO keywords, see below) | `swipl` + pack `lsp_server` | pacman `swi-prolog` [S: 10.0.2] + `swipl pack install` |
| Scala | tree-sitter `scala` | tree-sitter | lexer `scala` | Metals `metals` | Coursier, `rice-lsp-setup scala` |
| OCaml (.ml, .mli) | tree-sitter `ocaml`, `ocaml_interface` | tree-sitter | lexer `caml` | `ocamllsp` | opam `ocaml-lsp-server`, `rice-lsp-setup ocaml` |
| Fortran | tree-sitter `fortran` | tree-sitter | lexer `fortran` | `fortls` | PyPI via pipx, `rice-lsp-setup fortran` |
| LaTeX, BibTeX (office, D31) | tree-sitter `latex` (generated), `bibtex` | tree-sitter | lexers `latex`, `bibtex` | `texlab` | pacman (`packages/office.txt`); see office.md |

Not in Arch's official repos (so not installed by default, rule 5): ElixirLS, Metals,
ocaml-lsp-server, fortls (AUR or upstream only [S: aur.archlinux.org via search, 2026-10-30]).
`bin/rice-lsp-setup` installs them per user, opt-in, and reports missing pacman packages.

## Neovim (`config/nvim/`, needs 0.12)

Arch `extra` has Neovim 0.12.3 [S: archlinux.org via search]. The config uses only 0.12 APIs and
two plugins:

- **Plugin manager: built-in `vim.pack`** [V: neovim v0.12.3 `runtime/lua/vim/pack.lua`]:
  `vim.pack.add(specs, { confirm = false })` clones missing plugins on first start (needs `git` and
  network) and writes `~/.config/nvim/nvim-pack-lock.json`. Defaults are
  `{ load = vim.v.vim_did_init == 1, confirm = true }`; during startup plugins are `packadd!`-ed,
  so they are on `runtimepath` when the next `require` runs. `version` pins a commit:
  - nvim-treesitter **main** branch @ `a2f6944` (2026-10-24). Requires Neovim 0.12,
    `tree-sitter-cli` ≥ 0.26.1 ("not npm") and a C compiler [V: README @ a2f6944]. API:
    `require('nvim-treesitter').install{...}` (async; skips installed parsers); highlighting is
    Neovim's own `vim.treesitter.start()`, folding `vim.treesitter.foldexpr()`. Filetype aliases
    (`eelixir` → `eex`, `ocamlinterface` → `ocaml_interface`) come from its
    `plugin/filetypes.lua` [V].
  - nvim-lspconfig @ `7d12077` (2026-10-30): only its `lsp/<name>.lua` server definitions are used,
    through Neovim's `vim.lsp.config` / `vim.lsp.enable`. Commands [V: `lsp/*.lua`]: `hls`
    `haskell-language-server-wrapper --lsp`; `prolog_ls` `swipl -g use_module(library(lsp_server)).
    -g lsp_server:main -t halt -- stdio`; `metals` `metals`; `ocamllsp` `ocamllsp`; `fortls`
    `fortls --notify_init --hover_signature --hover_language=fortran --use_signature_help`;
    `elixirls` `elixir-ls` (its doc comment says "no cmd by default"; the code sets one);
    `expert` `expert --stdio`.
- **Servers are enabled only if their executable is on PATH** (`lsp.lua`), so a missing server
  never errors. Expert (the Elixir team's official server, pre-1.0) is enabled only when ElixirLS
  is absent.
- Completion: built-in `vim.lsp.completion.enable(..., { autotrigger = true })`, `completeopt`
  `menuone,noselect,popup,fuzzy`; inlay hints on; document highlights on CursorHold. Default 0.12
  LSP maps (`grn` rename, `gra` code action, `grr` references, `gri` implementation, `grt` type
  definition, `gO` symbols, `K` hover, `<C-S>` signature help in insert, `[d`/`]d`) [V:
  `runtime/doc/lsp.txt`]; the rice adds `gd`, `<leader>f` format, `<leader>e` float, `<leader>q`
  loclist, `<leader>h` inlay hints toggle (leader = Space).
- **Prolog vs Perl:** Neovim's `.pl` detection honours `vim.g.filetype_pl` [V:
  `runtime/lua/vim/filetype/detect.lua`]; the rice sets `'prolog'`.
- Colors: `themes/<palette>/nvim/colors/rice.lua` (generated). Defines every capture in 0.12's
  `:h treesitter-highlight-groups`, every `@lsp.type.*` in `:h lsp-semantic-highlight`, the legacy
  syntax groups (Prolog's regex highlighting uses them) and diagnostics. Checked by
  `tests/nvim/check_colorscheme.py`; loaded in a real Neovim (0.9.5, `--clean`) to confirm it
  runs.
- Older Neovim: `init.lua` loads only the colors and warns.
- Statusline: plain Lua, no plugin (mode, file, diagnostics, attached servers, filetype, position).

First start: plugins clone, then parsers compile in the background (a few seconds per parser);
highlighting appears for files opened afterwards. `:checkhealth vim.lsp`, `:checkhealth
nvim-treesitter`, `:lua =vim.pack.get()` show the state.

## Helix (`config/helix/`, 25.07.1)

Arch `extra` ships Helix as **`helix`, not `hx`** (`hx` belongs to the `hex` package) [V: Helix
book `package-managers.md` @ 25.07.1; S: FS#72576]. zsh aliases `hx` to `helix` when no `hx`
exists.

- Helix's built-in `languages.toml` already defines grammars and servers for every target
  language [V @ 25.07.1]: `elixir`/`heex` → `elixir-ls`; `haskell` → `haskell-language-server-wrapper
  --lsp`; `prolog` → `swipl ... lsp_server:main ...`; `scala` → `metals`; `ocaml`/`ocaml-interface`
  → `ocamllsp`; `fortran` → `fortls --lowercase_intrinsics`.
- **`.pl`**: listed by both `prolog` and `perl`; the extension map is a HashMap filled in file
  order, so the later `perl` wins [V: `helix-core/src/syntax.rs`]. User `languages.toml` is merged
  by language name with depth 3, so a `file-types` array set there **replaces** the built-in one
  [V: `helix-loader` `merge_toml_values`]. The rice sets perl's list to the built-in one minus
  `pl`; `tests/editors/check_helix.py` fails if the built-in list changes.
- Fortran: adds `f08`, `f18` and upper-case preprocessed extensions.
- `config.toml` keys are checked against the book's `editor.md` tables (Helix rejects unknown
  editor keys and falls back to the default config) [V]. Theme keys are checked against
  `themes.md`'s scope list; Helix uses the longest matching key, so `keyword.control.import`
  falls back to `keyword` [V: themes.md].
- Grammars: Arch's package ships prebuilt grammars in its runtime [BK, TODO-verify]; otherwise
  `helix --grammar fetch && helix --grammar build`. `helix --health <lang>` shows grammar, queries
  and server status.

## vis (`config/vis/`)

Arch `extra` has vis 0.9 or a snapshot [S, TODO-verify the exact version and whether lexers are a
separate `vis-lexers` package].

- Theme: `themes/<palette>/vis/themes/rice.lua` sets `lexers.STYLE_<TAG>` (tag upper-cased, dots
  to underscores) [V: vis `lua/vis.lua` `set_syntax`]; colors `#rrggbb`; attributes `bold`,
  `italics`, `underlined`, `reverse`, `dim`, `blink`, `keep_attribute` [V: `ui-terminal.c`].
  Lexer tags used by the target languages (comment, string, number, keyword, operator, type,
  function, constant, variable, preprocessor, class, label, regex, embedded) are all set [V: vis
  master `lua/lexers/*.lua`].
- Rendered on vis 0.8 (Ubuntu, curses backend) for all six languages: keywords red, types cyan,
  strings yellow, numbers and atoms purple, comments overlay, functions green. The curses backend
  redefines palette slots 16+ with OSC 4 to show the exact colors.
- **`.pl`**: vis 0.9 lists `%.pl$` under both perl and prolog and iterates with `pairs()` (order
  unspecified); newer vis consults `vis.ftdetect.extensions` first [V: `lua/plugins/filetype.lua`
  @ v0.9 and master]. `visrc.lua` removes the perl pattern and sets `extensions.pl = 'prolog'`.
- Prolog lexer dialects: it has ISO, gprolog and SWI keyword sets selected by the lexer property
  `prolog.dialect`, but its check reads `dialog ~= 'swipl'` (typo, undefined variable), so it
  always falls back to ISO unless `gprolog` [V: `lua/lexers/prolog.lua` line 34, v0.9 and master
  2026-10-29]. SWI-only builtins are therefore plain identifiers. Upstream fix pending; not
  patched here.
- LSP: **vis-lspc** (GPL-3.0) @ `9d0f7a0` (2026-07-15), cloned by `rice-lsp-setup vis-lspc` into
  `~/.config/vis/plugins/vis-lspc`. Needs vis ≥ 0.9 (`vis:communicate`); on older vis it shows an
  error and returns `{}` [V: its `init.lua`], which `visrc.lua` ignores. Servers are keyed by vis
  syntax name in `lspc.ls_map`; haskell and caml are preconfigured upstream, the rice adds
  elixir, prolog, scala, fortran and drops entries whose executable is missing (autostart would
  otherwise report a failed start on every file). Diagnostic styles come from the theme
  (`STYLE_DIAGNOSTIC_*`). **Not run inside vis in the build environment** (executing the plugin
  was not permitted there); verify on Arch with `:lspc-start-server`.

## Language servers: install routes

| Server | Command | Route | Notes |
| --- | --- | --- | --- |
| ElixirLS 0.31.1 | `elixir-ls` | `https://github.com/elixir-lsp/elixir-ls/releases/download/v0.31.1/elixir-ls-v0.31.1.zip` → `~/.local/share/rice/elixir-ls/0.31.1`, symlink `~/.local/bin/elixir-ls` → `language_server.sh` | Asset name from the release workflow (`zip -jr elixir-ls-v<ver>.zip`) [V: `.github/workflows/release-asset.yml` @ 328a1c0]; `language_server.sh` resolves its own symlink [V]. First start runs a forked `Mix.install`, fetching deps from Hex (network) [V: `scripts/installer.exs`]. Needs `elixir` (pacman). |
| haskell-language-server | `haskell-language-server-wrapper` | pacman | Arch's HLS is built for Arch's `ghc` only; projects on a ghcup GHC need ghcup's HLS [BK]. |
| SWI-Prolog `lsp_server` | `swipl ...` | `swipl pack install -y lsp_server` | `-y` = `interactive(false)` [V: swipl-devel `app/pack.pl` @ 4f13840]. |
| Metals | `metals` | Coursier: `cs install --install-dir ~/.local/bin metals` | `--install-dir` (alias `--dir`) [V: coursier `SharedInstallOptions.scala` @ f6a7538]. If no `cs`/`coursier` is on PATH, the launcher from `https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz` [V: coursier `doc/docs/cli-installation.md`] goes to `~/.local/share/rice/coursier/cs`. Needs a JDK (`jdk-openjdk` [BK]). |
| ocaml-lsp-server | `ocamllsp` | `opam install -y ocaml-lsp-server`, then a wrapper `~/.local/bin/ocamllsp` running `opam exec -- ocamllsp` | The wrapper picks the current switch (per-project `_opam` too) and refuses to loop if the switch lacks the server. `opam init` is left to the user (it offers to edit shell startup files). |
| fortls | `fortls` | `pipx install fortls` → `~/.local/bin` | `python-pipx` [BK]. |
| Expert (optional) | `expert --stdio` | upstream releases | Not installed by the script; Neovim prefers it automatically when present and ElixirLS is not; Helix: commented block in `languages.toml`. |

`~/.local/bin` is on PATH via `home/.zshenv`. Editors started from a terminal inherit it; a
launcher-started `nvim.desktop` only does if the session environment has it [TODO-verify once the
session startup exists].

## Failure modes

- No network on first Neovim start: `vim.pack` cannot clone; Neovim starts without highlighting
  beyond regex syntax and without LSP configs. Rerun later; nothing is half-written.
- No `tree-sitter` or `gcc`: a warning once per start; regex syntax still works.
- Pinned commits mean upstream fixes arrive only when the pins move (deliberate: nvim-treesitter's
  main branch is a rewrite and still changes API). Update: edit `version` in
  `lua/rice/plugins.lua`, then `:lua vim.pack.update()`.
- Haskell: HLS/GHC version mismatch shows as "no HLS for GHC x.y" in the server log.
- Metals needs a JDK and downloads its own dependencies on first start; first import of an sbt
  build takes minutes.
- A server that is installed but broken (e.g. Prolog without the pack) is still enabled: Neovim
  logs the failure (`:checkhealth vim.lsp`), Helix shows it in `--health`, vis-lspc in a message.

## Tests

```sh
python3 tests/nvim/check_colorscheme.py <neovim v0.12.3 checkout>   # captures, semantic types, links, colors
python3 tests/editors/check_helix.py <helix 25.07.1 checkout>       # config keys, theme scopes, languages
shellcheck -x bin/rice-lsp-setup
```
