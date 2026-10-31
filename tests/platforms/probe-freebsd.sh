#!/usr/bin/env bash
# tests/platforms/probe-freebsd.sh: which candidate package names exist in FreeBSD's binary
# package repositories, quarterly (the default) and latest. Run as root in a FreeBSD VM.
# One line per name: NAME QUARTERLY-VERSION LATEST-VERSION ("-" = missing).
set -Eeuo pipefail
echo "== $(freebsd-version) $(uname -m)"
names=(
  hyprland hyprlock hypridle xdg-desktop-portal-hyprland hyprpolkitagent hyprland-guiutils hyprshutdown
  hyprtoolkit hyprutils hyprlang aquamarine hyprgraphics hyprcursor hyprwire hyprland-protocols
  hyprwayland-scanner quickshell greetd regreet gtkgreet seatd dbus polkit consolekit2 xwayland mesa-dri
  mesa-devel drm-kmod wayland wayland-protocols libinput libxkbcommon lua54 lua55 glaze re2 muparser lcms2
  libcanberra glslang sdbus-cpp libei udis86 tomlplusplus
  xdg-desktop-portal-gtk xdg-utils xdg-user-dirs dconf gnome-keyring seahorse qt6ct qt6-wayland qt6-shadertools
  qt6-base qt6-declarative librsvg2-rust rofi rofi-wayland jq libnotify wl-clipboard cliphist grim slurp
  pipewire wireplumber pavucontrol playerctl brightnessctl jetbrains-mono ibm-plex noto noto-emoji
  nerd-fonts nerd-fonts-symbols papirus-icon-theme capitaine-cursors adw-gtk3 nwg-look xcursorgen
  kitty foot zsh zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search zsh-completions
  starship fzf zoxide eza bat htop btop fastfetch
  thunar thunar-archive-plugin thunar-volman xarchiver tumbler ffmpegthumbnailer gvfs dolphin kio-extras
  ffmpegthumbs breeze librewolf firefox thunderbird vscode vscodium imv zathura zathura-pdf-mupdf
  strawberry amberol kasts gstreamer1-plugins-good gstreamer1-plugins-bad gstreamer1-plugins-ugly
  gstreamer1-libav gstreamer1-plugins-pipewire neovim vis helix tree-sitter-cli tree-sitter
  erlang elixir ghc hs-cabal-install hs-haskell-language-server swi-pl openjdk25 openjdk26 sbt scala
  ocaml ocaml-opam bubblewrap gcc14 gcc15 py311-pipx py312-pipx pipx
  texlive-full texstudio biber texlab libreoffice en-hunspell hyphen mythes networkmgr wifimgr sudo doas git
  bash cmake ninja meson pkgconf rust gmake
)
query() { pkg rquery '%v' "$1" 2> /dev/null | head -n 1 || true; }
pkg -o ASSUME_ALWAYS_YES=yes update -q > /dev/null 2>&1 || true
declare -A quarterly=()
for n in "${names[@]}"; do quarterly[$n]="$(query "$n")"; done
mkdir -p /usr/local/etc/pkg/repos
# 15.x names the ports repository FreeBSD-ports (pkgbase splits the base system off).
grep -h -A3 'FreeBSD-ports' /etc/pkg/FreeBSD.conf || true
# shellcheck disable=SC2016  # pkg expands ${ABI} itself
echo 'FreeBSD-ports: { url: "pkg+https://pkg.FreeBSD.org/${ABI}/latest" }' > /usr/local/etc/pkg/repos/FreeBSD.conf
pkg -o ASSUME_ALWAYS_YES=yes update -f -q > /dev/null 2>&1 || true
for n in "${names[@]}"; do
    printf '%-34s %-22s %s\n' "$n" "${quarterly[$n]:--}" "$(query "$n" || true)"
done | sed 's/ $/ -/'
echo "== pkg search hypr / greet / nerd"
pkg search -q hypr 2> /dev/null | head -n 40 || true
pkg search -q greet 2> /dev/null || true
pkg search -q nerd 2> /dev/null | head || true
pkg search -q -o openjdk 2> /dev/null | head || true
