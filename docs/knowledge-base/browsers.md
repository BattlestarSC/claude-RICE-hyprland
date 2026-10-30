# Browsers: privacy configuration and theming

Owner's order (2026-10-30): **LibreWolf** (primary; asked for as "IronWolf", see below), **Firefox**
(secondary), **ungoogled-chromium** (backup), **Zen** (optional).

Labels: [V] read in a primary source (date), [S] search result or secondary source, [BK]
background knowledge not re-checked, [TODO-verify] must be checked on Arch or hardware.

## Which browser is "IronWolf"

No desktop browser of that name exists [S: searches 2026-10-30]. **IronFox** is a hardened Firefox
fork for **Android only** (Mull's successor) [S]. **LibreWolf** is the desktop hardened Firefox fork
and is in Arch `extra` (158.0.1_2-1 built 2026-10-22) [S: archlinux.org package page via search;
archlinux.org itself unreachable from the build environment]. The rice uses LibreWolf; swapping is
one package name if the owner meant something else.

## Packages and sources (D2: official repos on the default path)

| Browser | Package | Repo | Default install? |
| --- | --- | --- | --- |
| LibreWolf | `librewolf` | extra [S] | yes |
| Firefox | `firefox` | extra [BK] | yes |
| ungoogled-chromium | `ungoogled-chromium` / `-bin` | AUR (also OBS, archlinuxcn) [S] | prompted optional extra |
| Zen | `zen-browser-bin` [TODO-verify name] | AUR | prompted optional extra |

## How Firefox-family browsers take settings

1. **Enterprise policies** (`policies.json`). On Linux, Firefox reads
   `/etc/<app name, lowercased>/policies/policies.json` if it exists, **otherwise** the install's
   `distribution/policies.json`; only one file is used [V: `EnterprisePoliciesParent.sys.mjs`,
   `SpecialSystemDirectory.cpp` `GetUnixSystemConfigDir`, Firefox main 2026-10-30]. So:
   - Firefox: `/etc/firefox/policies/policies.json` (written by the installer after a prompt;
     `/etc` is root-owned, installer rule 5).
   - **LibreWolf: never write `/etc/librewolf/policies/policies.json`.** LibreWolf ships its own
     `distribution/policies.json` (telemetry off, updates off, uBlock Origin, search engines…
     [V: librewolf-community/settings `distribution/policies.json`, 2023 archive]); an `/etc`
     file would replace all of it.
   - Zen: same reason (the AUR package disables updates through its distribution policies [S]).
2. **Preferences**: `user.js` in the profile (applied at every start), or LibreWolf's
   `~/.librewolf/librewolf.overrides.cfg` (autoconfig syntax: `defaultPref`/`pref`/`lockPref`)
   [V: librewolf.cfg in librewolf-community/settings (2023): `autoadmin.global_config_url` =
   `$HOME/.librewolf/librewolf.overrides.cfg`; S: current docs also list XDG variants].
3. **Theme**: `<profile>/chrome/userChrome.css` + `userContent.css`, enabled by
   `toolkit.legacyUserProfileCustomizations.stylesheets` [V: all.js default false, main].

Profile locations: Firefox uses `~/.mozilla/firefox` when it already exists, otherwise
`$XDG_CONFIG_HOME/mozilla/firefox` [V: `nsXREDirProvider.cpp` `LegacyHomeExists`, main].
LibreWolf: `~/.librewolf` or `~/.config/librewolf/librewolf` [S: LibreWolf docs listing].
Zen: `~/.zen` or `~/.config/zen` [TODO-verify]. `bin/rice-browser-setup` checks all of them.

## What this rice sets

### Firefox (`config/browsers/firefox-policies.json` → `/etc/firefox/policies/policies.json`)

Policy names and fields checked against mozilla/policy-templates `docs/index.md` @ 5b66711
(2026-10-13) by `tests/browsers/check_policies.py`.

- `DisableTelemetry`, `DisableFirefoxStudies`, `DisableFeedbackCommands`,
  `DontCheckDefaultBrowser`, `SkipTermsOfUse`, empty first-run and post-update pages.
- `GenerativeAI` all off (chatbot, link previews, smart tab groups).
- `FirefoxHome`: no sponsored tiles/stories, no Pocket/stories. `FirefoxSuggest`: no web or
  sponsored suggestions, no "improve suggest". `UserMessaging`: no recommendations, no onboarding.
- `EnableTrackingProtection`: strict, incl. cryptominers, fingerprinters, email trackers.
- `HttpsOnlyMode: "enabled"` (on, user may turn it off per site).
- `ExtensionSettings`: **NoScript** (`{73a6fe31-595d-460b-a920-fcc0f8843232}`) and **uBlock
  Origin** (`uBlock0@raymondhill.net`), `normal_installed` (installed and updated automatically,
  user may disable), toolbar placement. IDs read from each project's own `manifest.json` on
  GitHub [V 2026-10-30]; install URL in the documented AMO form.
- `Preferences` (status `default` unless noted): userChrome enabled, dark web content, Global
  Privacy Control, no add-on recommendations, AI chat/link previews off, no prefetch/speculative
  connections, WebRTC exposes only the default route address; `datareporting.policy.
  dataSubmissionEnabled` **locked** off. Every key is inside the documented allowlist.
- Not used: `DisablePocket` (no longer documented; Pocket was retired), `DisableFirefoxAccounts`
  (sync stays available), `DNSOverHTTPS` (left to the user: it moves DNS trust to a resolver),
  Safe Browsing stays **on** (it is a security feature; lookups use hashed prefixes [BK]).

### Firefox and Zen profiles (`config/browsers/user.js`)

Telemetry, studies, crash reports, captive-portal and connectivity pings off; sponsored and
AI features off; prefetch and speculative connections off; search suggestions off; GPC on; dark
theme (`firefox-compact-dark@mozilla.org` [V: `browser/themes/addons/dark/manifest.json`]) and
dark content. Names checked against arkenfox user.js v144 (2026-09-09; none in its deprecated
section) and Firefox's `firefox.js` / `all.js` / `StaticPrefList.yaml` (main, 2026-10-30).
Dropped after checking: `network.predictor.enabled` (deprecated, default off since 144),
`dom.private-attribution.submission.enabled` (no longer in Firefox).
Side effect worth knowing: with captive-portal detection off, hotel/airport Wi-Fi login pages
do not open by themselves (open any http:// page instead).

### LibreWolf (`config/browsers/librewolf.overrides.cfg`)

Only the look: userChrome enabled, dark web content. LibreWolf's hardening (no telemetry,
uBlock Origin, cleared data on close, fingerprinting protection) is left as shipped. NoScript is
not added: uBlock Origin's medium/hard mode covers script blocking there without a second
blocker fighting the first.

### Theme (`templates/firefox/userChrome.css`, `userContent.css`)

Overrides the CSS variables Firefox's theme engine sets (`--toolbox-background-color`,
`--toolbar-background-color`, `--toolbar-field-*`, `--lwt-*`, `--panel-*`,
`--tab-background-color-selected`, `--newtab-*` …) [V: `LightweightThemeConsumer.sys.mjs`,
`browser-colors.css`, `tabs.css`, main 2026-10-30]. These are internals that get renamed
(`--toolbox-bgcolor` → `--toolbox-background-color` happened); a renamed variable falls back to
the built-in dark theme. A signed static theme would be sturdier but needs AMO signing on
release Firefox [BK]; revisit if renames become frequent.

### ungoogled-chromium (`templates/chromium/policies.json` → `/etc/chromium/policies/managed/rice.json`)

Chromium (non-Chrome branding) reads `/etc/chromium/policies` [V: `policy_paths.cc`, main];
managed policies go in `managed/` [BK]. Names checked against `policies.yaml` (main,
2026-10-30); enum values read from each policy's YAML definition:
`NetworkPredictionOptions 2` = never, `GenAiDefaultSettings 2` = disabled, `BrowserSignin 0` =
disabled, `HttpsOnlyMode "force_balanced_enabled"` = HTTPS-first (warns before plain HTTP).
Also: metrics, URL-keyed data collection, search suggestions, alternate error pages, spelling
service, translate, Privacy Sandbox (prompt, topics, site ads, measurement), shopping list,
promotions, background mode, default-browser nag all off; third-party cookies blocked; sync off;
`BrowserThemeColor` = palette purple. Flags (`~/.config/chromium-flags.conf`, read by Arch's
chromium-launcher, which the ungoogled-chromium PKGBUILD also builds [V: PKGBUILD]):
`--ozone-platform-hint=auto` (native Wayland), dark UI and web content [BK flags].
Extensions: no Chrome Web Store in ungoogled-chromium; uBlock Origin (MV2) no longer runs on
current Chromium, uBlock Origin Lite (MV3) is installed by hand [BK].

## Applying

- System part (installer, prompted, root): Firefox `policies.json`, Chromium `rice.json`.
- User part: `bin/rice-browser-setup` (no root): marked block in each profile's `user.js`,
  `chrome/*.css` (a foreign file is kept as `*.rice-bak`), LibreWolf overrides. A browser started
  for the first time after setup needs one more run (profiles are created on first start).
- Default browser: `xdg-settings set default-web-browser librewolf.desktop` [BK desktop name].
- Verify: `about:policies` (Firefox: "Active" list, no errors), `about:support` (userChrome),
  `chrome://policy` (Chromium: all "OK"), `about:config` for any pref.

## Tests

```sh
python3 tests/browsers/check_policies.py <policy-templates checkout> <chromium policies.yaml>
shellcheck -x bin/rice-browser-setup
```
