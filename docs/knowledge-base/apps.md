# Desktop apps: viewers, music, podcasts, keyring

Owner's choices (2026-10-30; D38–D40). Labels as in [README.md](README.md#verification-labels).
Sources read 2026-10-30 unless noted.

| Role | App | Package(s) | Default for | Colors |
| --- | --- | --- | --- | --- |
| Images | imv | `imv` | every `image/*` type its desktop file declares | `~/.config/imv/config` (generated) |
| PDF / EPUB / XPS | Zathura | `zathura`, `zathura-pdf-mupdf` | the types the MuPDF plugin's desktop file declares | `~/.config/zathura/zathurarc` (generated) |
| Music library | Strawberry | `strawberry` | (none; open it from the launcher) | qt6ct palette ([theming.md](theming.md#qt-apps-qt6ct)) |
| Music files | Amberol | `amberol` | every `audio/*` type its desktop file declares | GTK 4 / libadwaita: `~/.config/gtk-4.0/gtk.css` |
| Podcasts | Kasts | `kasts` | (none) | Quasar KDE scheme via `kastsrc`, qt6ct palette underneath |
| Keyring | gnome-keyring | `gnome-keyring`, `seahorse` | Secret Service (D-Bus) | seahorse: GTK |

Package names are `?` in `packages/apps.txt` / `desktop.txt` until CI has seen them in Arch.

## Default applications

`lib/desktop.sh` `set_default_app GLOB PREFIX...` finds the installed desktop file by name
(the first match of GLOB in `/usr/share/applications`), reads its `MimeType=` line and runs
`xdg-mime default FILE` for the declared types that start with a PREFIX. Desktop file names and
MIME lists change between versions and plugins (Zathura's MIME types live in the plugin's desktop
file, `org.pwmt.zathura-pdf-*.desktop`, not in `org.pwmt.zathura.desktop` [V: Ubuntu's zathura 0.5.4
files]), so nothing is hard-coded. A missing app is skipped. Desktop names: `imv.desktop` [V: imv
4.4 package], `io.bassi.Amberol.desktop` [BK; TODO-verify].

## imv

- Config `$XDG_CONFIG_HOME/imv/config`, else `~/.config/imv/config` [V: imv `src/imv.c`
  `get_config_path`, GitHub mirror 4.3.0; Arch ships 5.x: TODO-verify nothing changed].
- `[options]`: `background` (6 hex digits, `#` optional, or `checks`), `overlay_text_color`,
  `overlay_background_color` (6 hex), `overlay_*_alpha` (2 hex), `overlay_font` (`Family:size`),
  `overlay_position_bottom` [V: `src/imv.c` option handler].
- Set: background `crust`, overlay `mantle` at 90 % with `text`, IBM Plex Sans 12, at the bottom.
  imv's own key bindings are kept (the overlay toggles with `d`).
- Run: imv 4.4 (Ubuntu, X11 backend) under Xvfb loaded the file and drew exactly these colors.

## Zathura

- `~/.config/zathura/zathurarc`, generated; `include local` at the end loads
  `~/.config/zathura/local` (created empty, never overwritten). A missing include is only a
  warning [V: zathura `girara-gtk/config.c` `config_parse`]. Lines are parsed like a shell
  command line (`g_shell_parse_argv`), so values with spaces are quoted.
- Option names: every `girara_setting_add` in zathura's source (the girara UI options are
  registered there too since girara was split) [V: zathura main 2026-10-30,
  `zathura/config.c`]; colors go through `gdk_rgba_parse` (`#RRGGBB`, `rgba(r, g, b, a)`).
- Set: UI in the palette (status bar `mantle`, input bar `crust`, completion selection purple
  with `crust` text, notifications), search highlights yellow 35 % / active purple 50 %, JetBrains
  Mono 11, clipboard selection, SyncTeX on. **Pages stay white**; `Ctrl+R` recolors them to `base`
  background and `text` foreground (`recolor-keephue` keeps image hues).
- Checked by `tests/apps/check_viewers.py`; run: zathura 0.5.4 (Ubuntu) under Xvfb accepted every
  option (only warning: the absent `local` in the test directory).
- SyncTeX inverse search to an editor is not configured (needs a choice of editor); forward
  search from TeXstudio: set its external viewer to `zathura --synctex-forward %l:1:%f %.pdf`
  [BK; TODO-verify].

## Music: Strawberry + Amberol

- **Strawberry** for the library. Its GStreamer output defaults to `autoaudiosink` (PipeWire like
  every other app) [V: strawberry `src/engine/gstengine.cpp` `kAutoSink`]; choosing an ALSA
  `hw:`/`plughw:` device in Settings > Backend opens the card directly
  [V: `src/engine/alsaaudiodevicelister.cpp`], which is bit-perfect but blocks every other app's
  sound while it plays. That is why audio files do not open in Strawberry.
- **Amberol** opens single files and folders without a library and plays through PipeWire; it
  is the default for audio files. libadwaita, so the generated `gtk-4.0/gtk.css` themes it.
  It tints its window from the album art by default (a setting in its menu) [BK]. Source not
  readable from the build environment (gitlab.gnome.org blocked): package name and desktop file
  [TODO-verify].
- Both, and Kasts, publish MPRIS [V: strawberry `HAVE_MPRIS2`; kasts `kmediasession/mpris2`;
  Amberol BK], so the bar's media pill and the media keys (playerctl) control whichever plays.

## Podcasts: Kasts

KDE's podcast app (Kirigami): feeds, queue, downloads, chapters, gpodder.net / Nextcloud sync.
It creates a `KColorSchemeManager` at start [V: kasts `src/utils/colorschemer.cpp`], which applies
`[UiSettings] ColorScheme` from the app's own config, the same mechanism as Dolphin
(theming.md); the installer writes `kastsrc` `ColorScheme=Quasar` (file name from the KAboutData
component `kasts` [V: `src/main.cpp`]; `rc` suffix: KConfig convention [BK]).
Alternative: GNOME Podcasts (libadwaita, themed by gtk.css), not chosen because its source could
not be checked from here.

## Keyring (D40)

- **gnome-keyring** provides the Secret Service D-Bus API; **seahorse** shows and edits it.
- **Unlock at login:** greetd authenticates user sessions through the PAM service `greetd`
  [V: greetd `greetd/src/config/mod.rs` `GENERAL_SERVICE`]. The installer adds, after a backup and
  as one of the listed system changes, `auth optional pam_gnome_keyring.so` after the last `auth`
  line and `session optional pam_gnome_keyring.so auto_start` after the last `session` line of
  `/etc/pam.d/greetd` (`lib/pam-keyring.awk`; a file that already mentions the module is left as
  is). The `login` keyring is then created with, and unlocked by, the login password.
  Arch's file contents [TODO-verify: CI runs `tests/installer/pam_keyring.sh /etc/pam.d/greetd`
  on the real package].
- **Who uses it:** apps that store secrets through libsecret: Chromium (current Chromium sends
  unknown desktops such as Hyprland to the Secret Service [V: chromium
  `components/os_crypt/async/browser/freedesktop_secret_key_provider.cc`, main 2026-10-30]),
  Code - OSS (see below), NetworkManager applets, `git-credential-libsecret`. Firefox, LibreWolf
  and Thunderbird keep their own password stores [BK].
- **Code - OSS:** Electron's backend choice for unknown desktops has historically been plain text,
  so `rice-code-setup` sets `"password-store": "gnome-libsecret"` in `~/.vscode-oss/argv.json`,
  which VS Code passes to Electron [V: vscode `src/mainImpl.ts`; argv.json is JSONC with trailing
  commas allowed, `src/vs/base/common/jsonc.ts`]. An existing `password-store` is kept.
- **Failure modes:** a login password that differs from the keyring password, or autologin, leaves
  the keyring locked (apps then ask for its password); changing the login password with `passwd`
  does not change the keyring password (seahorse does) [BK].

## Tests

```sh
python3 tests/apps/check_viewers.py <zathura checkout> <imv checkout>   # option names, color formats
tests/installer/pam_keyring.sh [/etc/pam.d/greetd]                   # PAM edit: placement, idempotent
```
