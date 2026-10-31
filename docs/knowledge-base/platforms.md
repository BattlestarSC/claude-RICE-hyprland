# Platforms: one installer, five systems

Owner (2026-10-30, D43): besides Arch, set up "this GUI, as closely as is possible" on Ubuntu 26.04
LTS, Gentoo (OpenRC and systemd; source builds, binary packages only when no source build
exists), FreeBSD and Fedora (latest stable), in that order; extra repositories and overlays are
allowed. Labels as in [README.md](README.md#verification-labels).

## Architecture

`./install.sh` is the only entry point. `lib/platform.sh` detects the system (`ID` in
`/etc/os-release`; `uname -s` = FreeBSD; Gentoo's init from the `make.profile` link) and sources
`lib/platform/<id>.sh`, which implements a fixed interface (listed at the top of
`lib/platform.sh`): package manager (`plat_available`, `plat_install`, `plat_installed`),
repositories (`plat_setup_repos`, run after the plan is accepted), things packages cannot
provide (`plat_extras`), services and the display manager, the default JDK, and system paths
(`GREETD_DIR`, `GREETER_USER`, `PAM_DIR`, `FIREFOX_POLICY_DIR`, `ZSH_BIN`). Package lists:
`packages/*.txt` for Arch (historical location), `packages/<id>/*.txt` for the others, same file
names. Everything after the packages (configuration in `$HOME`, assets, desktop defaults, system
setup) is shared.

## Why source builds

The configuration is Hyprland 0.57 Lua (hard rule 1). Hyprland 0.57.0 was released 2026-10-28 and
only Arch packages it (2026-10-30):

| System | Packaged Hyprland | Source |
| --- | --- | --- |
| Arch | 0.57.0 | [V: full-install CI] |
| Ubuntu 26.04.1 | 0.53.3 (universe) | [V: probe CI] |
| Fedora 44 | none; the solopasha/hyprland COPR cannot be enabled for 44 | [V: probe CI 2026-10-31] |
| FreeBSD 15.1 packages | 0.56.2 (every library of the 0.57 stack is current) | [V: probe CI 2026-10-31] |
| Gentoo | not in the main tree; hyproverlay has 0.57.0 | [V: probe CI 2026-10-31] |

So where the packaged version is older, `lib/extras.sh` builds the stack into `/usr/local` at the
exact commits Hyprland v0.57.0's `flake.lock` pins (`lib/pins.sh`). Hyprland 0.57 needs a C++26
compiler, Lua 5.5, wayland-protocols >= 1.49, libinput >= 1.29, xkbcommon >= 1.11, glaze (fetched
by its CMake if absent), muparser, re2, lcms2, libcanberra, glslang [V: Hyprland v0.57.0
`CMakeLists.txt`].

### Source builds (`lib/extras.sh`)

- `extras_build "name|url|ref|system|args"`: shallow fetch of the exact ref into
  `~/.cache/rice/src/<name>`, CMake/Meson/Cargo build as the user, install with sudo into
  `/usr/local` (`lib` as libdir on every system), `ldconfig`, stamp
  `/usr/local/share/rice/built/<name>` = ref. A matching stamp skips the component on re-runs.
- Upstream release files (Neovim, tree-sitter CLI, Symbols Nerd Font, adw-gtk3) are checked
  against SHA-256 values recorded in `lib/pins.sh` (computed 2026-10-30 from the downloads).
- Capitaine cursors: the r4 tag has only SVG sources and a `build.sh` written for the Inkscape
  0.x command line; `extras_capitaine` follows its recipe (specs in `src/config`, sizes 1-3x,
  `cursor-aliases`) with `rsvg-convert` and `xcursorgen`.
- Files other programs look for only under `/usr` (the Hyprland session entry for ReGreet,
  XDPH's `hyprland.portal`) are copied there with the usual backup (`extras_link_into_usr`).

## Fedora

Fedora 44 is `fedora:latest` (2026-10-31) [V: probe CI, `tests/platforms/probe-fedora{,-2}.sh`].
The base repository is the release snapshot; `updates` carries the current versions (Firefox
159, Thunderbird 158, Neovim 0.12.6, kitty 0.47, fastfetch 2.68, LibreOffice 26.2.6), and dnf
installs from both.

- **Built from source** (as on Ubuntu, `lib/extras.sh`): the Hyprland 0.57 stack (no Hyprland
  package; the solopasha COPR cannot be enabled for 44), wayland-scanner 1.26 + wayland-protocols
  1.50 (Fedora: 1.24 / 1.47), Quickshell 0.3.2 (Fedora: 0.2.1), ReGreet, starship 1.27 (only a
  COPR with 1.24 exists), texlab, zsh-history-substring-search, Capitaine cursors; upstream
  releases: tree-sitter CLI (Fedora: 0.25), Symbols Nerd Font. GCC 16, so no libstdc++ patch is
  needed (it is applied anyway; it is equivalent code).
- **Repositories:** LibreWolf (`repo.librewolf.net`) and VSCodium (`download.vscodium.com`) as
  `.repo` files in `config/fedora/` [BK: both projects' install instructions; TODO-verify in the
  Fedora full-install CI]. Amberol is not in Fedora: installed from Flathub (its upstream
  channel) with `flatpak override --filesystem=xdg-config/gtk-4.0:ro`, so the generated GTK 4 CSS
  still applies; `/var/lib/flatpak/exports/share` is in `DATA_DIRS` for the default-app step.
- **Names:** `gnome-keyring-pam` carries `pam_gnome_keyring.so`; `kf6-kconfig` carries
  `kwriteconfig6`; `libeis-devel` carries `libeis-1.0.pc`; `libglvnd-devel` carries `glesv2.pc`;
  `qsb` is `/usr/lib64/qt6/bin/qsb` (`qt6-qtshadertools`) [V: `dnf repoquery --whatprovides`].
- **Not available:** haskell-language-server (ghcup), sbt (Coursier), Code - OSS (VSCodium
  instead, as on Ubuntu), capitaine-cursors (rendered), nwg-look (not used by the installer).
  LibreOffice is 26.2, older than the 26.8 the theme extension targets [office.md].
- Fedora's dynamic linker does not search `/usr/local/lib` (Debian/Ubuntu's does): the built
  Hyprland could not load its libraries [V: Fedora CI, "could not read the Hyprland version"].
  `extras_env` adds `/etc/ld.so.conf.d/rice-usr-local.conf` (backed up like every /etc file) on
  every Linux system. `dbus-run-session` is in `dbus-daemon`, absent from a minimal Fedora.
- Greeter user `greetd` [TODO-verify: Fedora's greetd package; the full-install CI creates
  `/var/lib/regreet` owned by it].

## Sessions without systemd

Gentoo with OpenRC and FreeBSD have no systemd user manager, so nothing starts a D-Bus session
bus, the polkit agent or PipeWire for the session, and `systemctl` does not exist.

- **Session bus:** the installer adds `/etc/greetd/sessions/wayland-sessions/hyprland.desktop`
  (`Exec=dbus-run-session start-hyprland`) there. The greeter's Hyprland sets
  `XDG_DATA_DIRS=/etc/greetd/sessions:/usr/local/share:/usr/share`; ReGreet reads session files
  from `$XDG_DATA_DIRS/{xsessions,wayland-sessions}` in that order and skips a later file with the
  same relative name [V: ReGreet 0.5.0 `src/sysutil.rs` `init_sessions`], so this entry replaces
  the package's `hyprland.desktop` without touching it. On systemd systems the directory does not
  exist and nothing changes. `start-hyprland` itself starts no bus [V: Hyprland v0.57.0 `start/`].
- **Polkit agent:** `autostart.lua` runs `systemctl --user start hyprpolkitagent || rice-session
  start`; `rice-session start` asks the session bus to start `org.hyprland.hyprpolkitagent`
  (hyprpolkitagent installs a D-Bus service file whose `Exec=` is the agent and whose
  `SystemdService=` is used only under systemd [V: hyprpolkitagent v0.2.0 `CMakeLists.txt`,
  `assets/hyprpolkitagent-dbus.in`]). dbus-daemon finds service files under
  `$XDG_DATA_DIRS/dbus-1/services`, default `/usr/local/share:/usr/share` [BK: dbus-daemon(1)].
- **PipeWire:** `rice-session start` runs `gentoo-pipewire-launcher restart` where it exists
  [BK; TODO-verify: Gentoo probe], else `pipewire`, `wireplumber` and `pipewire-pulse`.
- **Power:** `rice-menu` calls `rice-session power suspend|reboot|poweroff`: systemctl under
  systemd, else elogind's `loginctl` (same verbs [BK]), else FreeBSD's `shutdown -r|-p now`
  (allowed for group `operator`) and `acpiconf -s 3`. ReGreet's reboot/poweroff commands get
  the platform's `POWER_CTL` in place of `systemctl` (`with_system_paths`).

## Ubuntu

Probe of the real `ubuntu:26.04` image (26.04.1, 2026-10-30, `tests/platforms/probe-ubuntu.sh`)
[V]:

- Packaged and recent enough: everything in `packages/ubuntu/*.txt`, including all build
  dependencies of the Hyprland stack (`liblua5.5-dev` 5.5.0, gcc 15.2, Qt 6.10 with private
  headers, sdbus-c++ 2.2.1, libinput 1.31, xkbcommon 1.13), greetd 0.10.3, rofi 2.0, kitty 0.45,
  foot 1.25, starship 1.22, btop, fastfetch, imv 5.0, zathura, strawberry, amberol, kasts,
  openjdk-25-jdk, texlive-full, texstudio, texlab, Helix as `hx` 25.07.1.
- Too old: hyprland 0.53.3 (whole stack built), wayland-protocols 1.47 (1.49 built), neovim
  0.11.6 (0.12.3 release), tree-sitter-cli 0.25.9 (release), libreoffice 26.2 (the theme targets
  26.8: `ppa:libreoffice/ppa`).
- Missing: quickshell, regreet (built), satty (unused by the rice), capitaine-cursors (rendered),
  adw-gtk3 (release), zsh-history-substring-search (copied from its tag), zathura-pdf-mupdf
  (Poppler plugin instead: no EPUB), haskell-language-server (ghcup, per user), sbt (Coursier),
  librewolf and codium (extrepo), Firefox/Thunderbird debs (`firefox`/`thunderbird` are snap
  shims: `ppa:mozillateam/ppa`, pinned at 1001, Ubuntu's shims at -1).
- Greeter user `_greetd` (Debian's greetd packaging) [V: Ubuntu full-install CI, the greeter
  checks pass].
- First complete install (CI, 2026-10-31): 2462 s, everything built. What the verifier then
  found, all fixed: `bsdtar` is not in a minimal Ubuntu (`libarchive-tools`; the setup scripts zip
  with it); Debian's imv has only `imv-wayland`/`imv-x11` (`/usr/local/bin/imv` link);
  VSCodium's command is `codium` (the desktop step only looked for `code`); source-built cursor
  themes are in `/usr/local/share/icons`, which libXcursor's default path lacks, so `env.lua`
  sets `XCURSOR_PATH`.

## Gentoo

Source-first, as the owner asked: Portage builds everything; the only binary package is
VSCodium (no source ebuild exists). Requirements checked by `plat_preflight`: amd64, a 23.0
desktop profile (`default/linux/amd64/23.0/desktop` for OpenRC, `.../desktop/systemd`), and
`/etc/portage/package.{accept_keywords,use,license}` as directories (or absent). The installer
does not switch profiles: that rebuilds the world and is the owner's call.

- **Overlays** (`eselect repository enable`, then `emaint sync`): `guru` (Quickshell, ReGreet,
  cliphist, brightnessctl, adw-gtk3, nwg-look, Amberol, texlab, two zsh plugins), `hyproverlay`
  (Hyprland 0.57.0 with its libraries, hyprlock, hypridle, XDPH, hyprpolkitagent,
  hyprland-guiutils, hyprshutdown), `librewolf`.
- **Portage files** (`config/portage/`, deployed with a backup as `/etc/portage/package.*/rice`):
  `~amd64` for the three overlays (GURU has no stable keywords by policy) and for the few
  main-tree packages whose stable version is too old; USE flags (Hyprland's Lua target, rofi
  Wayland, PipeWire sound server, `pam` for gnome-keyring, gvfs MTP, TeX Live collections).
- **Facts from the probe** (Gentoo tree, GURU, hyproverlay, librewolf synced 2026-10-31,
  `tests/platforms/probe-gentoo{,-2}.sh`) [V]:
  - hyproverlay `gui-wm/hyprland-0.57.0`: `LUA_COMPAT=( lua5-4 lua5-5 )`; the tree has Lua up to
    5.4.8 only. Hyprland's own CMake accepts 5.4 too (`pkg_search_module(LUA ... lua>=5.5 lua<5.6)`:
    the last alternative matches 5.4) [V: Hyprland v0.57.0 `CMakeLists.txt`].
  - `dev-java/openjdk:25` exists as a source ebuild (25.0.5); `openjdk-bin` is not needed.
  - Not packaged: `capitaine-cursors` (rendered by `lib/extras.sh`), `pipx` (rice-lsp-setup puts
    fortls in a venv), haskell-language-server (ghcup), Scala (Coursier; `scala-cli-bin` exists
    but is binary).
  - Name differences: `gui-apps/qt6ct`, `gui-apps/ReGreet`, `sys-auth/hyprpolkitagent`,
    `media-sound/kasts`, `app-text/texlab`, `app-misc/nwg-look`.
- **OpenRC:** `dbus` and `elogind` are added to the default runlevel; greetd runs on VT 7
  (agetty holds 1-6); an existing display manager running through Gentoo's `display-manager`
  service is removed from the runlevel and `greetd` added. Session bus, polkit agent, PipeWire and
  power actions: [Sessions without systemd](#sessions-without-systemd).
- **Greeter user:** `greetd` [TODO-verify: the ebuild's acct-user].
- **Resolved** [V: gentoo workflow, systemd profile, 2026-10-31]: the whole selection is 1002
  packages (981 new on a stage3), about 10 GB of sources, every one an ebuild built from source;
  `go-bootstrap` and `openjdk-bin:25` (bootstrap compilers) are the only binary payloads. What it
  took, all in `config/portage/` and `lib/platform/gentoo.sh`: testing keywords for the Haskell
  stack, Elixir 1.20 (stable Erlang is 29, stable Elixir needs < 29), the opam family, Neovim's
  luv, zsh 5.9.2, sdbus-c++, nss/aom; USE flags for texlive-core, lpeg, libvpx, zlib;
  Quickshell without the crash handler, Thunar without the panel plugin; and building
  dev-python/pillow without truetype first (docutils/pillow/harfbuzz/glib cycle on a fresh system).
- **CI:** `.github/workflows/gentoo.yml` runs the real module up to the package transaction for
  both init systems and lets Portage resolve it (`tests/platforms/gentoo-pretend.sh`); compiling
  the desktop (Qt, three Mozilla browsers, LibreOffice, GHC, TeX Live) takes many hours and does
  not fit a CI job, so the builds themselves are unverified.

## FreeBSD

FreeBSD 15.1-RELEASE, amd64 (`tests/platforms/probe-freebsd.sh` in a FreeBSD VM, 2026-10-31)
[V]. 15.x names the ports package repository `FreeBSD-ports`, and its default URL is already
`latest`, so quarterly and latest gave the same versions.

- **Packaged and current:** the whole Hyprland 0.57 library stack (hyprutils 0.14.3, hyprlang
  0.6.8, aquamarine 0.15.1, hyprgraphics 0.5.1, hyprcursor 0.1.13, hyprwire 0.3.1,
  hyprland-protocols 0.8.0, wayland-protocols 1.49, lua55 5.5.1), hyprlock 0.9.6, hypridle 0.1.8,
  hyprpolkitagent, hyprland-guiutils, hyprshutdown, hyprtoolkit, Quickshell 0.3.2, kitty 0.49,
  foot 1.28, starship 1.27, neovim 0.12.6, tree-sitter-cli 0.26.13, htop 3.5.3, btop 1.4.8,
  fastfetch 2.70, LibreWolf/Firefox/Thunderbird 159, LibreOffice 26.8.1, texlive-full, texlab,
  Haskell (GHC 9.12 + haskell-language-server), openjdk25, sbt, scala, Amberol, Kasts, Strawberry.
- **Hyprland 0.56.2 only**, which cannot read the Lua config. `ports/x11-wm/hyprland` is the
  FreeBSD port (freebsd-ports `e3ae9611c587`) moved to 0.57.0: the release tarball's SHA-256 in
  `distinfo`, two patches regenerated against 0.57.0 (Linux capability headers in
  `src/init/initHelpers.cpp`; hyprpm's headers check), two unchanged; the 0.56 port's
  `alloca.h` patch is upstream now (`Eis.cpp` handles FreeBSD), and its `post-patch` file list
  follows 0.57's moves (`src/desktop/view/window/Window.cpp`, `src/helpers/SystemInfo.cpp`,
  `src/render/types.hpp`) [V: patches applied to the 0.57.0 tarball with `patch --dry-run`;
  the build itself: FreeBSD full-install CI]. 0.57's bell player uses `std::jthread`, which
  FreeBSD 15.1's base libc++ only offers with `-fexperimental-library`; the overlay adds it
  [V: FreeBSD CI, `RotatingPlayerThread.hpp:33: no type named 'jthread'`]. With that and the
  `subview` patch, Hyprland 0.57.0 compiles, stages and packages on FreeBSD 15.1 with the base
  clang [V: FreeBSD CI 2026-10-31, "Building packages for hyprland-0.57.0"]. The installer fetches the ports framework (`Mk`,
  `Templates`, `Keywords`) at that commit, builds the port as the user, generates `pkg-plist` from
  the staged files (`make makeplist`), and installs the package. Once FreeBSD's package reaches
  0.57, `pkg install hyprland` is used instead.
- **No greetd:** greetd uses Linux VT ioctl numbers and `/proc/self/exe` [V: greetd master
  `greetd/src/terminal/ioctl.rs`, `src/session/interface.rs`], so it has no FreeBSD port. The
  login-screen question becomes "start Hyprland after a console login on ttyv0":
  `~/.config/rice/tty-autostart` names the console, `config/zsh/session.zsh` runs
  `rice-session hyprland` there (XDG_RUNTIME_DIR if nothing set one, `dbus-run-session
  start-hyprland`). An enabled display manager in `rc.conf` is disabled. The keyring is not
  unlocked at login (no greeter PAM service to add it to): gnome-keyring asks on first use.
- **Seat and services:** `seatd_enable`, `dbus_enable` (sysrc), the user joins group `video`
  (seatd's socket group [BK]); AMD GPUs: `drm-kmod` and `amdgpu` in `kld_list`. Bluetooth and
  NetworkManager are skipped (FreeBSD's own stacks; configured by the owner).
- **Missing, handled:** capitaine-cursors (rendered), adw-gtk3 (release),
  zsh-history-substring-search (copied), brightnessctl (not used by the rice), `gfortran` (gcc15
  installs `gfortran15`; linked in `~/.local/bin`).
- **Missing, skipped (`?` in the lists):** Code - OSS / VSCodium (no binary package), biber,
  IBM Plex, Tumbler, Breeze, ffmpegthumbs under these names [TODO-verify: FreeBSD names].
- **Paths:** zsh `/usr/local/bin/zsh`; Firefox policies in
  `/usr/local/lib/firefox/distribution/policies.json` [BK: the distribution directory is read on
  every platform; TODO-verify on FreeBSD]; data dirs `/usr/local/share` first.
- **Locking:** no logind, so `rice-session lock` starts hyprlock itself and hypridle's
  `before_sleep_cmd` never fires.
- **First complete install** (CI, 2026-10-31): 1981 s; every package, Hyprland 0.57 from the
  overlay, Capitaine, configs, defaults, services. What the verifier then found: the generated
  plist lost `bin/Hyprland` (makeplist's reminder line was dropped by position, and
  `bin/Hyprland` sorts first; now by content, and the build stops if it is missing); BSD `chmod`
  takes `--` after the mode for a file (ElixirLS, Coursier); Coursier's native launcher is
  Linux-only (its JVM launcher is used elsewhere); observer is in `erlang-wx`.

## Shared portability rules (from the FreeBSD port)

The installer runs on GNU and BSD userlands: no `install -D` (BSD `install -D` is a destdir
option), no `find -printf`, `df -P` instead of `df --output`, `cp -R` for directories, desktop
files searched in every `DATA_DIRS` entry. `/etc/os-release` is read by a shell
(`os_release KEY`), because Gentoo single-quotes its values (`ID='gentoo'`) [V: Gentoo resolve CI].

## Source patches

`patches/<component>/*.patch` are applied with `git apply` after `extras_build` fetches the
pinned ref. `patches/hyprland/0001-ranges-starts-with-gcc15.patch`: Hyprland 0.57.0 calls
`std::ranges::starts_with`, missing from Ubuntu 26.04's libstdc++ (GCC 15.2) [V: Ubuntu
full-install CI]; replaced by the equivalent `ranges::equal` over `views::take`.
`0002-string-subview-gcc15.patch`: `std::string::subview` (C++26) in a log message, likewise
missing; `std::string_view(...).substr`. With both, the whole Hyprland 0.57 build compiles on
GCC 15.2 except what they cover [V: Ubuntu CI with `ninja -k 0`: these were the only two errors].
The FreeBSD overlay carries the same `subview` change (`files/patch-src_ipc_s1_S1.cpp`).

## Tests

```sh
tests/platforms/probe-ubuntu.sh     # in ubuntu:26.04: candidate names and versions
tests/platforms/probe-fedora.sh     # in fedora:latest (and probe-fedora-2.sh: build deps, COPRs)
tests/platforms/gentoo-resolve.sh default/linux/amd64/23.0/desktop   # in gentoo/stage3: emerge --pretend
docker run --rm -v "$PWD:/src:ro" ubuntu:26.04 bash /src/tests/installer/full-install.sh
tests/platforms/probe-freebsd.sh    # in a FreeBSD VM: package names, quarterly and latest
SRC=$PWD bash tests/installer/full-install.sh   # as root in a FreeBSD 15 VM (CI: freebsd.yml)
```
