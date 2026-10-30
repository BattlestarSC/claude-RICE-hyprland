#!/usr/bin/env bash
# tests/platforms/probe-fedora.sh: which candidate package names exist in Fedora (official repos,
# then with the COPRs the installer would enable). One line per name: NAME VERSION or MISSING.
set -Eeuo pipefail
# shellcheck source=/dev/null
. /etc/os-release
echo "== ${PRETTY_NAME}"
dnf -y -q install dnf-plugins-core > /dev/null 2>&1 || true
names=(
  hyprland hyprlock hypridle xdg-desktop-portal-hyprland hyprpolkitagent hyprland-guiutils hyprland-qtutils
  hyprshutdown hyprtoolkit quickshell greetd regreet greetd-regreet
  gcc-c++ cmake meson ninja-build git wayland-devel wayland-protocols-devel libxkbcommon-devel libinput-devel
  libdrm-devel mesa-libgbm-devel mesa-libEGL-devel mesa-libGLES-devel pixman-devel cairo-devel pango-devel
  libseat-devel libdisplay-info-devel hwdata-devel systemd-devel libXcursor-devel libzip-devel librsvg2-devel
  tomlplusplus-devel libjxl-devel libwebp-devel libheif-devel libspng-devel file-devel re2-devel muParser-devel
  lcms2-devel libcanberra-devel glslang-devel sdbus-cpp-devel pipewire-devel pam-devel xcb-util-errors-devel
  xcb-util-wm-devel libxcb-devel xorg-x11-server-Xwayland-devel udis86-devel iniparser-devel lua-devel lua
  qt6-qtbase-devel qt6-qtbase-private-devel qt6-qtdeclarative-devel qt6-qtwayland-devel qt6-qtshadertools-devel
  qt6-qtsvg-devel polkit-qt6-1-devel jemalloc-devel cli11-devel cargo rust gtk4-devel glaze-devel
  xdg-desktop-portal-gtk xdg-utils xdg-user-dirs dconf gnome-keyring seahorse qt6ct qt5-qtwayland qt6-qtwayland
  librsvg2-tools rofi rofi-wayland jq libnotify wl-clipboard cliphist grim slurp satty pipewire wireplumber
  pipewire-pulseaudio pipewire-alsa pipewire-jack-audio-connection-kit pavucontrol playerctl brightnessctl bluez
  jetbrains-mono-fonts ibm-plex-sans-fonts ibm-plex-mono-fonts google-noto-sans-fonts google-noto-color-emoji-fonts
  papirus-icon-theme capitaine-cursors adw-gtk3-theme nwg-look
  kitty foot zsh zsh-autosuggestions zsh-syntax-highlighting starship fzf zoxide eza bat man-db man-pages less
  htop btop fastfetch lm_sensors
  Thunar thunar-volman thunar-archive-plugin xarchiver tumbler ffmpegthumbnailer gvfs gvfs-mtp udisks2 dolphin
  kio-extras breeze firefox thunderbird librewolf codium imv zathura zathura-pdf-mupdf strawberry amberol kasts
  gstreamer1-plugins-base gstreamer1-plugins-good gstreamer1-plugins-bad-free gstreamer1-plugins-ugly-free
  gstreamer1-plugin-libav neovim vis helix tree-sitter-cli
  erlang elixir ghc cabal-install ghc-haskell-language-server swi-prolog pl java-25-openjdk-devel
  java-latest-openjdk-devel sbt ocaml opam bubblewrap gcc-gfortran pipx
  texlive-scheme-full texstudio biber texlab libreoffice hunspell-en-US hyphen-en mythes-en
  NetworkManager network-manager-applet
)
mapfile -t avail < <(dnf -q repoquery --available --qf '%{name} %{version}-%{release}\n' "${names[@]}" 2> /dev/null | sort -u)
for n in "${names[@]}"; do
  line="$(printf '%s\n' "${avail[@]}" | awk -v n="$n" '$1 == n { print $2; exit }')"
  printf '%-36s %s\n' "$n" "${line:-MISSING}"
done
