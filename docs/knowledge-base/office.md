# Office: TeX Live, TeXstudio, LibreOffice

Owner's request (2026-10-30): "a full office setup. Full texlive install and LaTeX editor, plus
libreoffice. Theme libreoffice if possible." Decision D31. Labels as in
[README.md](README.md#verification-labels); sources read 2026-10-30.

Installed by `packages/office.txt` (installer question, default yes; about 7 GB).

## TeX Live (full)

- Arch split TeX Live into per-collection packages in 2023; **`texlive-meta`** depends on every
  collection except the language ones, which are separate `texlive-lang*` packages;
  **`texlive-doc`** is the offline documentation [S: Arch news "TeX Live package reorganization";
  archlinux.org texlive-meta 2025.2-2 page, via search]. "Full" here = `texlive-meta` +
  `texlive-doc` + all 17 language collections + `biber`. The language package names come from
  the AUR `texlive-full` conflicts list [S], so they carry `?` in the list until CI confirms them.
- Arch also has package **groups** for this; the installer cannot use groups (it checks names
  with `pacman -Si`, which does not resolve groups), hence the explicit list.
- Not used: the AUR `texlive-full` (a single TeX Live install in /opt; build failures reported [S]).

## LaTeX editor: TeXstudio

- `texstudio` is in `extra` (4.9.4 [S: archlinux.org via search]). Chosen over Kile (pulls KDE
  frameworks for a smaller feature set) and Setzer (GTK, not in the official repos [BK]):
  TeXstudio is the most complete (completion, structure view, built-in PDF viewer with SyncTeX,
  spell/grammar check, wizards). Neovim, Helix and vis also get **texlab** (below).
- Config: `~/.config/texstudio/texstudio.ini`, a Qt `QSettings` INI file. TeXstudio rewrites it
  with every setting when it exits, so the installer writes it **only if it does not exist**
  (`deploy_once`); re-runs never undo your changes.
- Look: `[texmaker] X11\Style=Adwaita Dark (txs)`: TeXstudio's built-in Adwaita style (built by
  default, `TEXSTUDIO_BUILD_ADWAITA ON` [V: TeXstudio `CMakeLists.txt` @ d42eb4e]), which matches the
  adw-gtk3-dark GTK apps and sets `darkMode`, so TeXstudio uses its **dark** syntax format set
  [V: `src/configmanager.cpp`]. The editor background follows the style's palette.
- Syntax colors: `[formatsDark]` (`version=1.0`, `data\<id>\<field>=…`), read by
  `QFormatScheme::load(QSettings&)` [V: `src/qcodeedit/lib/qformatscheme.cpp`]; ids from
  `utilities/qxs/defaultFormatsDark.qxf`. Mapping as in the editors: commands red, environments
  cyan, `\begin`/`\end`-type extra keywords purple bold, sectioning orange bold, math green and
  yellow, comments overlay italic, TODO yellow, missing references/citations/packages red wavy,
  current line `surface0`, selection `surface2`, search yellow.
- Fonts: JetBrains Mono 12.
- Verified: Qt's own `QSettings` (PySide6 6.x) reads every key as intended (style, font, 31 format
  ids). Not run inside TeXstudio.

## LaTeX in Neovim, Helix, vis

- **texlab** (`?texlab` in office.txt [BK repo]) serves LaTeX and BibTeX.
- Neovim: parsers `latex` (generated from its grammar at install: nvim-treesitter marks it
  `generate = true` [V: `parsers.lua` @ a2f6944], which is why tree-sitter-cli is installed) and
  `bibtex`; server `texlab` (lspconfig `cmd = { 'texlab' }` [V]), enabled only if installed.
- Helix 25.07: `latex` and `bibtex` already use `texlab` [V: `languages.toml`]; nothing to add.
- vis: lexers `latex`, `bibtex` [V: vis `lua/lexers/`]; vis-lspc entries for both added in
  `visrc.lua` (vis-lspc ships none [V]).

## LibreOffice

- Package **`libreoffice-fresh`**, named explicitly (fresh and still both provide `libreoffice`;
  rule 5: no provider prompts). Dictionaries: `hunspell-en_us`, hyphenation and thesaurus (`?`
  until CI confirms the names).
- Toolkit: on a desktop that is not Plasma/LXQt, LibreOffice autodetects the **gtk3** VCL plugin
  [V: `vcl/source/app/salplug.cxx` `autodetect_plugin_list` @ libreoffice-26.8.2.2], so it starts
  from the same adw-gtk3-dark GTK theme as Thunar.

### Theme (generated extension)

LibreOffice 25.8 refactored themes [S: LibreOffice dev list, 2025-06]; the 26.8 mechanism
[V: `vcl/README.themes.md`, `officecfg/registry/schema/org/openoffice/Office/{UI,Common}.xcs`,
`svtools/source/config/colorcfg.cxx` @ libreoffice-26.8.2.2]:

- A theme is a **color scheme**: a node in `Office.UI/ColorScheme/ColorSchemes` with one group
  per element (93 in 26.8: document, Writer/Calc/Draw marks, Basic/SQL highlighting, and since
  25.x the **UI**: `WindowColor`, `MenuColor`, `AccentColor`, `ButtonColor`, …), each holding
  `Color` (`xs:int`, 0xRRGGBB) and for some `IsVisible`. A nil color means "LibreOffice's
  default". `CurrentColorScheme` selects one.
- UI colors are only applied when `Office.Common/Appearance/LibreOfficeTheme = 1`; the 26.8
  default is **0 (disabled)**. `ApplicationAppearance` 0/1/2 = system/light/dark.
  `UseOnlyWhiteDocBackground` (default on) keeps pages white.
- The rice ships this as an **extension** (`themes/<palette>/libreoffice/extension/`:
  `description.xml`, `META-INF/manifest.xml`, `registry/ColorScheme.xcu` (scheme "Quasar" +
  `CurrentColorScheme`), `registry/Appearance.xcu` (theming on, dark, white pages)). The scheme
  copies the entry list and IsVisible flags of LibreOffice's own Automatic scheme; 49 entries get
  palette colors (UI: window `mantle`, menus `mantle`/`crust`, fields `surface0`, accent and
  highlights purple with `crust` text; document: area around the page `crust`, page boundaries
  `surface2`, links blue/purple, spelling red; Basic/SQL editors in the editor colors); the rest
  stay default. The page itself stays white: documents look as printed.
- `bin/rice-libreoffice-setup` zips it into an `.oxt` (bsdtar) and installs it per user with
  `unopkg add --force --suppress-license` [V: flags in `desktop/source/pkgchk/unopkg/unopkg_app.cxx`].
- **User layer wins over extensions.** Values you set in Tools > Options > Appearance live in
  `~/.config/libreoffice/4/user/registrymodifications.xcu`. LibreOffice writes that file one
  `<item oor:path="…"><prop oor:name="…" oor:op="fuse">…</item>` per line [V:
  `configmgr/source/writemodfile.cxx`]; the setup script removes exactly the three items that
  would hide the theme (`CurrentColorScheme`, `LibreOfficeTheme`, `ApplicationAppearance`) once,
  after a backup (`registrymodifications.xcu.rice-bak`), and refuses to run while LibreOffice is
  open (it rewrites the file on exit). Tested with a stub `unopkg` and a profile in that format:
  other settings kept, re-run is a no-op.
- Not verified: LibreOffice was not run (no 26.8 in the build environment; Ubuntu's 24.2 predates
  the format). Check on hardware: Tools > Extensions lists "Quasar (rice theme)"; Tools > Options
  > LibreOffice > Appearance shows scheme Quasar, Dark. If the UI is not themed, check
  Tools > Options > Advanced > Expert configuration > `LibreOfficeTheme` = 1.
- Icons: left at `auto`, which picks the dark variant of the default icon theme.

## Tests

```sh
python3 tests/office/check_office.py <libreoffice core 26.8 (sparse: officecfg schema)> <texstudio checkout>
shellcheck -x bin/rice-libreoffice-setup
```
