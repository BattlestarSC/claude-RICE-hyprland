# Vanilla Arch: assumptions and installer constraints

## What "vanilla Arch" means here

A fresh install from the official ISO (`archinstall` or the manual Installation Guide),
booted into a TTY, with:

| Assume present | Do **not** assume |
| --- | --- |
| `base`, a kernel, `linux-firmware` | `sudo` configured for the user (archinstall usually does it; the manual guide does not) |
| systemd as init, logind | `base-devel` (needed only for AUR builds) |
| `pacman` with a working mirrorlist | NetworkManager (could be `iwd`, `systemd-networkd`, or nothing beyond the live ISO) |
| `git` (the user just cloned this repo) | pipewire, fonts, a display manager, any GPU userspace beyond mesa defaults |
| network access | an AUR helper (`yay`/`paru`) |
| a regular user account running the installer | `multilib` enabled |

[BK] These are the defaults of the Arch Installation Guide and archinstall's minimal profile.

## Installer rules (derived constraints)

1. **Refuse to run as root.** User configs land in `$HOME`; root ownership breaks them.
   Escalate with `sudo` only for `pacman` and the few system-level steps.
2. **Preflight before changing anything:** `/etc/arch-release` exists; `sudo -v` works;
   network reachable (`pacman -Sy` is not a network test you want; use `curl -sI https://archlinux.org`
   or a `getent hosts` check); pacman DB lock `/var/lib/pacman/db.lck` absent; enough disk.
3. **Never partial-upgrade.** On Arch, installing packages after `-Sy` without `-u` is
   unsupported and can break library sonames. Use `sudo pacman -Syu --needed <pkgs>` in one transaction. [BK; Arch wiki "System maintenance"]
4. **Official repos only on the default path.** Every core package must come from `core`/`extra`.
   AUR packages go in an explicit opt-in stage (default no) built with `makepkg -si` as the
   invoking user, never as root (no AUR helper is installed).
5. **Avoid interactive provider prompts.** `pacman --noconfirm` silently picks the default
   provider, which is sometimes wrong (e.g. JACK implementation, font provider). Name the
   provider explicitly in the package list (`pipewire-jack`, `noto-fonts`) instead of relying on
   prompts or `--noconfirm`. Show the full package list and ask once before installing.
6. **Idempotent.** Re-running must be safe: `--needed` for pacman, compare-before-link for
   dotfiles, no duplicate lines appended to files.
7. **Back up, never clobber.** Any existing file at a target path is moved to
   `~/.local/state/<rice>/backups/<timestamp>/` with its relative path preserved, and listed in
   a manifest so `uninstall.sh` can restore it.
8. **Don't touch `/etc` silently.** System-level changes (display manager, login shell, services,
   browser policies) are listed in the installer's plan and confirmed once; the owner asked for
   them to be part of the default install (D29). Every replaced `/etc` file is backed up first.
9. **Logs.** Tee all output to `~/.local/state/<rice>/install-<timestamp>.log`.
10. **`set -Eeuo pipefail`, `shellcheck`-clean, bash only.** No python/node at install time.

## GPU / VM detection without extra packages

`lspci` is in `pciutils`, which is not in `base`. Read sysfs instead:

```sh
# Display controllers have PCI class 0x03xxxx. Vendors: 0x10de NVIDIA, 0x1002 AMD, 0x8086 Intel.
for d in /sys/bus/pci/devices/*; do
  [[ $(<"$d/class") == 0x03* ]] && printf '%s %s\n' "$(<"$d/vendor")" "$(<"$d/device")"
done
systemd-detect-virt   # "none" on bare metal; "kvm", "oracle", "vmware", ...
```

- **NVIDIA:** needs the proprietary/open kernel module, `nvidia_drm modeset=1`, env vars.
  Follow the Hyprland wiki NVIDIA page at the target version. Scope: detect and warn in v1;
  automate later. [V: wiki installation.md says NVIDIA is "often not usable out of the box"]
- **VM:** Hyprland needs 3D acceleration (virtio-gpu with GL / virgl, or GPU passthrough);
  otherwise it will not start. Detect and warn. [V: wiki master-tutorial.md]

## Package set

The lists live in [`packages/`](../../packages/README.md), one name per line; the table below is
the overview. Arch mirrors are unreachable from the build environment (proxy policy,
2026-10-30), so names are verified by CI (`tests/installer/check_packages.sh` in
`archlinux:latest`): **every name in `packages/*.txt` exists [V: CI run 2, 2026-10-30]**, and
`install.sh --dry-run --yes` completes there as a normal user. New, unconfirmed names get a `?`
(skipped with a warning if missing) until CI has seen them. Labels in this table describe the
other claims (repository, versions).

| Group | Packages |
| --- | --- |
| Compositor + hypr stack | `hyprland` [V wiki], `xdg-desktop-portal-hyprland` [V wiki], `xdg-desktop-portal-gtk`, `hyprlock`, `hypridle`, `hyprpaper`, `hyprpolkitagent`, `hyprlauncher`, `hyprshutdown`, `hyprsunset`, `hyprpicker` |
| Qt/GTK integration | `qt5-wayland`, `qt6-wayland` [V wiki must-have], `hyprqt6engine` or `qt6ct`, `nwg-look` |
| Audio / media | `pipewire`, `wireplumber` [V wiki], `pipewire-pulse`, `pipewire-alsa`, `pipewire-jack`, `pavucontrol`, `playerctl`, `brightnessctl` |
| Terminal + shell | `kitty`, `foot`, `zsh`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-history-substring-search`, `zsh-completions` [S: extra], `starship` [S: extra 1.25.1], `fzf`, `zoxide`, `eza`, `bat`; CLI tools `htop`, `btop`, `fastfetch` (D28); `man-db`, `man-pages`, `less` (`?` until CI) |
| Bar / wallpaper / notifications | `quickshell` [S], `qt6-shadertools` (`qsb`, compiles the sky shaders at install) [BK]; notifications are Quickshell's own (D20) |
| Bluetooth | `bluez`, `bluez-utils` [BK]; enabling `bluetooth.service` is a prompted system change |
| Launcher / menus | `rofi` (≥ 2.0 for native Wayland), `jq`, `libnotify`, `librsvg` (`rsvg-convert` rasterizes generated art at install) |
| Login | `greetd`, `greetd-regreet` (greeter runs inside Hyprland; no X server) |
| GPU (AMD) | `mesa`, `vulkan-radeon`; asked: `blender`, `hip-runtime-amd`, `hiprt` [S: Arch blender optdepends] |
| Clipboard / screenshots | `wl-clipboard`, `cliphist`, `grim`, `slurp`, `satty` (verify repo) |
| Fonts / icons / cursor | `ttf-jetbrains-mono` (terminal/editor text) [S: extra], `ttf-nerd-fonts-symbols-mono` (terminal icons) [S: extra 3.4.0], `ttf-ibm-plex` (bar text) [BK], `ttf-nerd-fonts-symbols` (bar icons) [BK], `noto-fonts`, `noto-fonts-emoji`, `papirus-icon-theme`, `capitaine-cursors` [V: upstream README: in the official repos] (D30) |
| Network (only if none present) | `networkmanager`, `network-manager-applet` |
| File managers | `thunar`, `thunar-volman`, `thunar-archive-plugin`, `xarchiver`, `tumbler`, `ffmpegthumbnailer`, `gvfs`, `gvfs-mtp`, `udisks2`; `dolphin`, `kio-extras`, `ffmpegthumbs`, `breeze` (Qt widget style Dolphin falls back to), `archlinux-xdg-menu`; theme `adw-gtk-theme` [S: extra 6.5-1] [others BK / TODO-verify] |
| Editor | `code` (Code - OSS) [S: extra], `jq` (settings merge); `bsdtar` from `libarchive` (pacman dependency) [BK] |
| Browsers + mail | `librewolf` [S: extra], `firefox`; optional AUR: `ungoogled-chromium`(-bin); `thunderbird` (D33; `?` until CI) |
| Office (asked) | `texlive-meta`, `texlive-doc`, `texlive-lang*`, `biber`, `texstudio`, `texlab`, `libreoffice-fresh`, `hunspell-en_us`, hyphen/mythes (office.md) |
| Terminal editors | `neovim` [S: extra 0.12.3], `helix` [S: extra 25.07.1; binary `helix`, V: Helix book], `vis`, `vis-lexers`, `tree-sitter-cli` (≥ 0.26.1) [S], `gcc`, `git`, `wl-clipboard` |
| Language toolchains (prompted, per language) | `elixir`, `ghc` + `haskell-language-server` [S], `swi-prolog` [S: 10.0.2], `jdk-openjdk` (Metals) + `sbt`, `ocaml` + `opam`, `gcc-fortran`, `python-pipx` (fortls) [BK unless marked]; servers outside the repos: `bin/rice-lsp-setup` |

## The installer

```sh
git clone <repo> && cd <repo> && ./install.sh      # --yes: defaults, no questions; --dry-run: print only
```

Order (`install.sh`, functions in `lib/`):

| Step | What | Where |
| --- | --- | --- |
| preflight | not root, `/etc/arch-release`, pacman/sudo/git, no `db.lck`, a sync db, DNS, ≥ 12 GB free, `sudo -v`; detects GPU vendor (sysfs), active network manager, current display manager, VM | `lib/preflight.sh` |
| questions | language toolchains (y), Blender + HIP on AMD (y), AUR ungoogled-chromium (n), wallpaper mode and layout, greetd (y), zsh login shell (y) | `install.sh` |
| package check | every name against the **local** sync db (`pacman -Si`); no `-Sy` before the upgrade, so stopping here leaves the system consistent | `lib/packages.sh` |
| plan | packages, files, system changes; one confirmation | `install.sh` |
| packages | `sudo pacman -Syu --needed <all>` (one transaction); then makepkg for the AUR extra | `lib/packages.sh` |
| files | copy into `$HOME` with backups (below) | `lib/deploy.sh`, `lib/files.sh` |
| assets | `qsb` → `~/.config/quickshell/sky/shaders/*.frag.qsb`; `rice-sky-atlas` at 8×16 × {1, 1.25, 1.5, 2} → `~/.local/share/rice/quickshell/`; still sky → `~/.local/share/rice/lock.png` | `lib/files.sh` |
| desktop | gsettings (through `dbus-run-session`: a TTY has no session bus), kwriteconfig6, `xdg-mime` defaults (Thunar, LibreWolf, Neovim), `rice-browser-setup`, `rice-code-setup`, `rice-libreoffice-setup`, `rice-lsp-setup` | `lib/desktop.sh` |
| system | `/etc/greetd/*` + enable greetd (disable the previous display manager), `chsh` to zsh, enable bluetooth (+ NetworkManager if none active), Firefox policies | `lib/system.sh` |

Not started now: greetd (it would take over the TTY running the installer); reboot instead.
Log: `~/.local/state/rice/install-<time>.log`. Any unexpected failure prints file and line (ERR
trap with `set -E`).

### Copy with backups (D29)

- A target that already exists and differs is copied to
  `~/.local/state/rice/backups/<time>/home/<path>` (or `…/system/etc/<path>`) and listed in
  `manifest.tsv` (`target<TAB>backup`) before it is replaced. Identical targets are skipped, so a
  re-run with no changes writes nothing (tested).
- `local.*` override hooks (`rofi/local.rasi`, `foot/local.ini`) are created empty if missing and
  never written again. Configs the app rewrites on exit (`btop.conf`, `htoprc`, `texstudio.ini`)
  are written only when absent (`deploy_once`), so a re-run never undoes changes made in the app. `~/.config/rice/settings.json` is written once (wallpaper answers).
- `hypr/conf/monitors.lua` keeps the panel descriptions `rice-monitors` captured; `env.lua` and
  the greeter files get the chosen cursor theme before comparison, so neither causes a backup on
  every run.

### Deploy map

| Source | Target |
| --- | --- |
| `config/hypr/**`, `themes/<p>/hypr/colors.{lua,conf}`, `themes/<p>/hypr/hyprtoolkit.conf` | `~/.config/hypr/**`, `~/.config/hypr/theme/`, `~/.config/hypr/hyprtoolkit.conf` |
| `config/quickshell/**`, `themes/<p>/quickshell/common/Theme.qml`, `assets/earth/land-1024x512.png` | `~/.config/quickshell/**`, `…/sky/land.png` |
| `config/rofi/config.rasi`, `themes/<p>/rofi/*.rasi` | `~/.config/rofi/` |
| `config/{kitty,foot,zsh}/**` + their `themes/<p>/` files; `home/.zsh*`; `themes/<p>/starship/starship.toml` | `~/.config/…`, `~/`, `~/.config/starship.toml` |
| `config/{btop,htop}`, `themes/<p>/{btop,fastfetch}` | `~/.config/{btop,htop,fastfetch}/` (btop.conf, htoprc: only if absent) |
| `themes/<p>/texstudio/texstudio.ini`, `themes/<p>/libreoffice/extension` | `~/.config/texstudio/` (only if absent), `~/.local/share/rice/libreoffice/extension` (read by `rice-libreoffice-setup`) |
| `config/{nvim,helix,vis}/**` + `themes/<p>/{nvim,helix,vis}` | `~/.config/{nvim,helix,vis}/` |
| `config/code-oss/*`, `themes/<p>/code-oss/extension` | `~/.local/share/rice/code-oss/` (read by `rice-code-setup`) |
| `config/browsers/{user.js,librewolf.overrides.cfg}`, `themes/<p>/firefox/*.css`, `config/thunderbird/user.js`, `themes/<p>/thunderbird/userChrome.css` | `~/.local/share/rice/browsers/` (`thunderbird/` below it; read by `rice-browser-setup`) |
| `config/gtk-{3,4}.0/settings.ini`, `themes/<p>/gtk-{3,4}.0/gtk.css`, `themes/<p>/kde/scheme.colors`, `config/xfce4` | `~/.config/gtk-{3,4}.0/`, `~/.local/share/color-schemes/Quasar.colors`, `~/.config/xfce4/` |
| `bin/*` | `~/.local/bin/` (0755) |
| `config/greetd/*`, `themes/<p>/greetd/regreet.css`, `themes/<p>/hypr/colors.lua`, the user's `monitors.lua`, rendered sky | `/etc/greetd/` |
| `config/browsers/firefox-policies.json` (+ `themes/<p>/chromium/policies.json` with the AUR browser) | `/etc/firefox/policies/policies.json` (`/etc/chromium/policies/managed/rice.json`) |

### Monitors

The panels' EDID descriptions are only known inside Hyprland (`hyprctl monitors all -j`), not on
the TTY where the installer runs. `bin/rice-monitors --auto` runs at the first login (autostart),
writes both descriptions into `monitors.lua` (left = the panel with the smaller x) and reloads;
`rice-menu monitors` (Super+Shift+M) offers capture, swap and "copy to login screen"
(`/etc/greetd/monitors.lua`, sudo). Until then the generic monitor rule applies.

## Installer questions (beyond packages)

| Question | Choices | Stored in |
| --- | --- | --- |
| Language toolchains + servers | yes (default) · no | `packages/languages.txt`, `rice-lsp-setup` |
| Office (TeX Live full, TeXstudio, LibreOffice) | yes (default) · no | `packages/office.txt`, `rice-libreoffice-setup` |
| Blender with HIP | yes (default, AMD GPU only) · no | `packages/blender.txt` |
| Optional AUR browser | ungoogled-chromium-bin | off by default (D2); makepkg |
| Wallpaper | animated ASCII Earth/Moon (default) · still ASCII (no animation, zero cost) · your own image (path; e.g. a NASA Earth photo) | `~/.config/rice/settings.json` (`skyMode`, `skyImage`), written only if the file does not exist |
| Wallpaper layout (two monitors) | mirror (default) · span | same file (`skyLayout`) |
| Login screen | greetd + ReGreet (default) · keep the current one | `lib/system.sh` |
| Login shell | zsh (default) · keep | `chsh` |
| Cursor theme | env `RICE_CURSOR=<name> ./install.sh` (default `capitaine-cursors-light`) | `hypr/conf/env.lua`, gsettings, greeter |

Browser policies are written without a separate question (part of the plan, D29).

NASA imagery is generally not copyrighted [S: search summary of NASA's media guidelines;
nasa.gov unreachable from the build environment], but the installer does not download it by
default (rule 4: no non-repo downloads on the default path); it asks for a local path.

Deploy-time requirements found while writing configs: `~/.config/hypr/theme/colors.conf` must
exist before hyprlock/hypridle run (they `source` it); `~/.local/share/rice/lock.png` is rendered
from the generated ASCII art (falls back to a solid color if absent); `hypridle` must not be
started before `hyprlock.conf` is in place.

## Starting the session

| Method | Pros | Cons |
| --- | --- | --- |
| **TTY + `exec start-hyprland` from `~/.zprofile` on VT1** | No extra packages, no `/etc` changes, transparent | No graphical greeter; keyring auto-unlock needs a PAM edit |
| greetd + tuigreet/ReGreet | Small, Wayland-native; wiki: "works flawlessly" | `/etc/greetd` config, service enable |
| SDDM (≥ 0.20) | Familiar, themeable | Pulls Qt; theming is a separate project |
| uwsm | systemd units per session, XDG autostart, clean shutdown | Wiki calls it "for advanced users"; adds a layer to debug |

[V: wiki master-tutorial.md, uwsm.md, 2026-10-29]

**Decided: greetd + ReGreet inside Hyprland** (D7 in [decisions.md](../decisions.md)); see
[hardware.md](hardware.md#login-greetd--regreet). The TTY method below is kept as reference for users of this repo
who prefer no display manager; the installer will not set it up by default.

```sh
# ~/.zprofile
if [[ -z $WAYLAND_DISPLAY && $XDG_VTNR -eq 1 ]] && command -v start-hyprland >/dev/null; then
  exec start-hyprland
fi
```

For TTY login, GNOME Keyring auto-unlock needs `pam_gnome_keyring.so` lines in
`/etc/pam.d/login` (example in wiki uwsm.md). Opt-in only.

## Validation strategy (CI and local)

- `shellcheck -x install.sh lib/*.sh`; `tests/installer/run.sh` (file layer in a throwaway home:
  first run, idempotent re-run, backups, user hooks, captured monitors, cursor; plus a full
  `--dry-run` with stubbed pacman/sudo/systemctl when run on Arch as a normal user).
- Package existence: `tests/installer/check_packages.sh` in `archlinux:latest` (CI job `packages`,
  which also runs `install.sh --dry-run --yes` as a normal user).
- Lua syntax: `luac -p` with a **5.5** compiler (Arch package name for Lua 5.5 [TODO-verify]).
  Semantic check: `Hyprland --verify-config -c <file>` if it runs headless [TODO-verify].
- Full dry run: installer in an `archlinux` container with a `--dry-run` flag that prints every
  action without executing it. Cannot exercise the compositor; a VM with virgl or real hardware
  is required for that.
