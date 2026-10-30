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
   AUR packages, if ever needed, go in an explicit opt-in stage that bootstraps `paru` or `yay`
   from `base-devel` as the invoking user, never as root.
5. **Avoid interactive provider prompts.** `pacman --noconfirm` silently picks the default
   provider, which is sometimes wrong (e.g. JACK implementation, font provider). Name the
   provider explicitly in the package list (`pipewire-jack`, `noto-fonts`) instead of relying on
   prompts or `--noconfirm`. Show the full package list and ask once before installing.
6. **Idempotent.** Re-running must be safe: `--needed` for pacman, compare-before-link for
   dotfiles, no duplicate lines appended to files.
7. **Back up, never clobber.** Any existing file at a target path is moved to
   `~/.local/state/<rice>/backups/<timestamp>/` with its relative path preserved, and listed in
   a manifest so `uninstall.sh` can restore it.
8. **Don't touch `/etc` silently.** System-level changes (display manager, PAM, `/etc/environment`)
   are opt-in prompts, documented in README.
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

## Package set (draft, to be validated)

Names are [BK] unless marked. Every name must be checked with `pacman -Si` inside an
`archlinux:latest` container before it ships ([TODO-verify] all).

| Group | Packages |
| --- | --- |
| Compositor + hypr stack | `hyprland` [V wiki], `xdg-desktop-portal-hyprland` [V wiki], `xdg-desktop-portal-gtk`, `hyprlock`, `hypridle`, `hyprpaper`, `hyprpolkitagent`, `hyprlauncher`, `hyprshutdown`, `hyprsunset`, `hyprpicker` |
| Qt/GTK integration | `qt5-wayland`, `qt6-wayland` [V wiki must-have], `hyprqt6engine` or `qt6ct`, `nwg-look` |
| Audio / media | `pipewire`, `wireplumber` [V wiki], `pipewire-pulse`, `pipewire-alsa`, `pipewire-jack`, `pavucontrol`, `playerctl`, `brightnessctl` |
| Terminal + shell | `kitty`, `zsh`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions`, `starship`, `fzf`, `zoxide`, `eza`, `bat` |
| Bar / wallpaper / notifications | `quickshell` [S], `qt6-shadertools` (`qsb`, compiles the sky shaders at install) [BK], `mako` or `swaync` (O5) |
| Bluetooth | `bluez`, `bluez-utils` [BK]; enabling `bluetooth.service` is a prompted system change |
| Launcher / menus | `rofi` (≥ 2.0 for native Wayland), `jq`, `libnotify`, `librsvg` (`rsvg-convert` rasterizes generated art at install) |
| Login | `greetd`, `greetd-regreet` (greeter runs inside Hyprland; no X server) |
| GPU (AMD) | `mesa`, `vulkan-radeon`; opt-in Blender GPU step: `hip-runtime-amd`, `hiprt` [S: Arch blender optdepends] |
| Clipboard / screenshots | `wl-clipboard`, `cliphist`, `grim`, `slurp`, `satty` (verify repo) |
| Fonts / icons / cursor | `ttf-jetbrains-mono-nerd`, `ttf-ibm-plex` (bar text) [BK], `ttf-nerd-fonts-symbols` (bar icons) [BK], `noto-fonts`, `noto-fonts-emoji`, `papirus-icon-theme`, a cursor theme (TBD; many are AUR-only) |
| Network (only if none present) | `networkmanager`, `network-manager-applet` |

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

- `shellcheck -x install.sh lib/*.sh`
- Package existence: `docker run --rm archlinux:latest bash -c 'pacman -Sy --noconfirm >/dev/null; pacman -Si <pkgs>'`
- Lua syntax: `luac -p` with a **5.5** compiler (Arch package name for Lua 5.5 [TODO-verify]).
  Semantic check: `Hyprland --verify-config -c <file>` if it runs headless [TODO-verify].
- Full dry run: installer in an `archlinux` container with a `--dry-run` flag that prints every
  action without executing it. Cannot exercise the compositor; a VM with virgl or real hardware
  is required for that.
