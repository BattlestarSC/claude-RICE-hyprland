#!/usr/bin/env bash
# tests/platforms/probe-ubuntu.sh: which candidate package names exist in Ubuntu (and at what
# version). Run as root in ubuntu:26.04. One line per name: NAME VERSION, or NAME MISSING.
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
sed -i 's/^Components: main$/Components: main restricted universe multiverse/' /etc/apt/sources.list.d/ubuntu.sources 2> /dev/null || true
apt-get update -qq
# shellcheck source=/dev/null
. /etc/os-release
echo "== ${PRETTY_NAME}"
names=(
  # hypr stack (packaged?) and its build dependencies
  hyprland hyprlock hypridle xdg-desktop-portal-hyprland hyprpolkitagent hyprland-qtutils hyprland-guiutils hyprcursor-util
  build-essential g++ g++-15 gcc-15 clang cmake meson ninja-build pkg-config git curl ca-certificates
  libwayland-dev wayland-protocols libxkbcommon-dev libinput-dev libdrm-dev libgbm-dev libegl-dev libgles-dev
  libpixman-1-dev libcairo2-dev libpango1.0-dev libseat-dev libdisplay-info-dev hwdata libudev-dev libxcursor-dev
  libzip-dev librsvg2-dev libtomlplusplus-dev libjxl-dev libwebp-dev libheif-dev libspng-dev libmagic-dev
  libre2-dev libmuparser-dev liblcms2-dev libcanberra-dev glslang-dev glslang-tools libsdbus-c++-dev
  libpipewire-0.3-dev libpam0g-dev libxcb1-dev libxcb-composite0-dev libxcb-xfixes0-dev libxcb-icccm4-dev
  libxcb-res0-dev libxcb-errors-dev xwayland libudis86-dev libiniparser-dev libffi-dev libgtest-dev
  liblua5.5-dev lua5.5 liblua5.4-dev libglaze-dev
  qt6-base-dev qt6-declarative-dev qt6-base-private-dev qt6-declarative-private-dev qt6-wayland-dev
  qt6-wayland-private-dev qt6-shadertools-dev qt6-svg-dev libpolkit-qt6-1-dev libjemalloc-dev libcli11-dev
  spirv-tools libpolkit-agent-1-dev libglib2.0-dev qml6-module-qtquick-controls quickshell
  cargo rustc libgtk-4-dev greetd regreet
  # desktop
  xdg-desktop-portal-gtk xdg-utils xdg-user-dirs dconf-service dconf-cli gnome-keyring seahorse qt6ct
  qtwayland5 qt6-wayland librsvg2-bin rofi jq libnotify-bin wl-clipboard cliphist grim slurp satty
  pipewire wireplumber pipewire-pulse pipewire-alsa pipewire-jack pavucontrol playerctl brightnessctl
  bluez fonts-jetbrains-mono fonts-ibm-plex fonts-noto-core fonts-noto-color-emoji papirus-icon-theme
  capitaine-cursors adw-gtk3 nwg-look
  # shell
  kitty foot zsh zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search starship fzf
  zoxide eza bat man-db manpages less htop btop fastfetch lm-sensors
  # apps
  thunar thunar-volman thunar-archive-plugin xarchiver tumbler ffmpegthumbnailer gvfs gvfs-backends udisks2
  dolphin kio-extras ffmpegthumbs breeze firefox thunderbird librewolf codium imv zathura zathura-pdf-mupdf
  strawberry amberol kasts gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad
  gstreamer1.0-plugins-ugly gstreamer1.0-libav
  # editors
  neovim vis helix hx tree-sitter-cli
  # languages
  erlang elixir ghc cabal-install haskell-language-server swi-prolog swi-prolog-core openjdk-25-jdk
  openjdk-27-jdk sbt ocaml opam bubblewrap gfortran pipx python3
  # office
  texlive-full texstudio biber texlab libreoffice libreoffice-gtk3 hunspell-en-us hyphen-en-us mythes-en-us
  # network
  network-manager network-manager-gnome
)
for n in "${names[@]}"; do
  v="$(apt-cache policy "$n" 2> /dev/null | awk '/Candidate:/ { print $2 }')"
  if [[ -z "$v" || "$v" == "(none)" ]]; then
    # a virtual or transitional name?
    if apt-cache showpkg "$n" 2> /dev/null | grep -q '^Reverse Provides:' && apt-cache showpkg "$n" | sed -n '/^Reverse Provides:/,$p' | grep -q .; then
      printf '%-36s VIRTUAL %s\n' "$n" "$(apt-cache showpkg "$n" | sed -n '/^Reverse Provides:/{n;p}' | head -c 80)"
    else
      printf '%-36s MISSING\n' "$n"
    fi
  else
    printf '%-36s %s\n' "$n" "$v"
  fi
done
echo "gcc default: $(apt-cache policy gcc | awk '/Candidate:/ { print $2 }')"
echo "firefox deps: $(apt-cache depends firefox 2> /dev/null | grep -m3 -E 'Depends|snap' | tr '\n' ' ')"
echo "thunderbird deps: $(apt-cache depends thunderbird 2> /dev/null | grep -m3 -E 'Depends|snap' | tr '\n' ' ')"
