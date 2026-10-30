# Code - OSS (the open-source build of VS Code)

Owner (2026-10-30): "the open source version of VSCode; remove all telemetry and AI features and
theme it".

## Which build

| Build | Repo | Marketplace | Notes |
| --- | --- | --- | --- |
| **`code`** (Code - OSS) | Arch `extra` [S: Arch wiki "Visual Studio Code" via search] | Open VSX (Arch ships a product.json that enables it) [S] | built from microsoft/vscode sources by Arch; **used** (D2: official repos) |
| VSCodium | AUR | Open VSX | same sources, extra telemetry patches; AUR-only |
| `visual-studio-code-bin` | AUR | Microsoft | proprietary build, telemetry endpoints configured |

Upstream `product.json` for the OSS build: `nameShort`/`nameLong` "Code - OSS",
`applicationName` "code-oss", `dataFolderName` ".vscode-oss", no `extensionsGallery`, and a
`defaultChatAgent` for GitHub Copilot [V: microsoft/vscode main `product.json`, 2026-10-30].
So the chat UI exists even in the OSS build; it needs switching off.
Paths: user settings `$XDG_CONFIG_HOME/Code - OSS/User/settings.json` (user data =
`$XDG_CONFIG_HOME/<product name>` [V: `userDataPath.ts`]; product name "Code - OSS" [BK on
which product field]); extensions `~/.vscode-oss/extensions` [V: dataFolderName]. CLI: `code`
and/or `code-oss` [TODO-verify on Arch]; `bin/rice-code-setup` tries both.

## Settings (`config/code-oss/`)

Every key checked against VS Code's sources (main e245892, 2026-10-30) by
`tests/vscode/check_theme.py`; enum values read from their registrations.

**Enforced** (`settings.json`, re-applied on every run of `rice-code-setup`):

| Key | Value | Why |
| --- | --- | --- |
| `telemetry.telemetryLevel` | `"off"` | all usage/error/crash telemetry [V: `TELEMETRY_SETTING_ID`] |
| `telemetry.enableCrashReporter` | `false` | [V] |
| `telemetry.editStats.enabled` | `false` | edit-statistics telemetry [V: `EDIT_TELEMETRY_SETTING_ID`] |
| `workbench.enableExperiments` | `false` | "Fetches experiments to run from a Microsoft online service" [V] |
| `chat.disableAIFeatures` | `true` | "Disable and hide built-in AI features provided by GitHub Copilot, including chat and inline suggestions" [V: `ChatAIDisabledSettingId`] |
| `chat.agent.enabled` | `false` | agent mode [V] |
| `workbench.settings.enableNaturalLanguageSearch` | `false` | settings search sent to an online service [V] |
| `workbench.settings.showAISearchToggle` | `false` | [V] |
| `update.mode` | `"none"` | pacman updates the app; enum none/manual/start/default [V] |
| `update.showReleaseNotes` | `false` | fetched online [V] |
| `npm.fetchOnlinePackageInfo` | `false` | built-in npm extension queries the registry on hover [V: extensions/npm package.json] |

**Defaults** (`settings-defaults.json`, applied only where you have no value): start with no
editor, no walkthroughs or tips, theme "Rice", native title bar (Hyprland draws none: saves the
custom title bar's height in a tiling layout), menu bar on Alt, JetBrainsMono Nerd Font 14 with
ligatures, solid cursor, same font in the integrated terminal.

Merge order: defaults < your settings < enforced (jq `*`). A `settings.json` with comments or
trailing commas (valid for VS Code, not JSON) is never rewritten; the script says what to add.

Not done: `extensions.autoUpdate` stays on (it contacts Open VSX for extension updates, which is
not telemetry). Third-party extensions can bring their own telemetry settings (e.g.
`redhat.telemetry.enabled`); add those to `settings.json` when such an extension is installed.

## Theme (`templates/code-oss/extension/`)

A local extension "Rice" generated from the palette: `package.json` + `themes/rice-color-theme.json`
(153 workbench colors, TextMate token colors, semantic token colors). Syntax roles follow the
palette's Monokai mapping (docs/colors/proposals.md): keywords red, functions green, strings
yellow, numbers/constants purple, types cyan (storage types italic), parameters orange italic,
comments `overlay` italic, escapes/regex pink. Selection purple at 28 %, cursor yellow, active tab
and focus purple, sidebar `mantle`, activity/status/title bars `crust`, integrated terminal with
the same ANSI map as kitty and foot. Every color key is registered in VS Code's color registry
(1000 ids scanned) [V: check_theme.py].

Installation: zipped to a `.vsix` with `bsdtar --format zip` and installed with
`code --install-extension … --force`. A VSIX install reads only `extension/package.json` from the
archive [V: `extensionManagementUtil.ts`]; dropping a folder into `~/.vscode-oss/extensions` is not
enough because user extensions are tracked in a profile index [V: `extensionsScannerService.ts`].

## Tests

```sh
python3 tests/vscode/check_theme.py <vscode checkout with src/vs, extensions/git, extensions/npm>
shellcheck -x bin/rice-code-setup
```
