#!/usr/bin/env bash
# tests/platforms/probe-fedora-2.sh: follow-up names for the Fedora installer (build
# dependencies, alternatives) and what the candidate COPRs provide. Run as root in fedora:latest.
set -Eeuo pipefail
q() { dnf -q repoquery --available --qf '%{name} %{version}-%{release} %{repoid}\n' "$@" 2> /dev/null | sort -u; }
echo "== $(. /etc/os-release && echo "${PRETTY_NAME}") ; releases: $(dnf -q repoquery --qf '%{version}' fedora-release 2> /dev/null | sort -u | tr '\n' ' ')"
echo "== updates repo versions (firefox thunderbird neovim fastfetch kitty)"
q firefox thunderbird neovim fastfetch kitty libreoffice-core
echo "== names"
for n in zsh-history-substring-search plasma-breeze breeze-gtk kf6-kconfig libglvnd-devel libei-devel \
    libuuid-devel readline-devel libxkbcommon-devel lua-devel lua5.4-devel gcc-c++ hwdata-devel \
    xcb-util-renderutil-devel libXrender-devel vulkan-loader-devel expat-devel libxml2-devel pugixml-devel \
    libjpeg-turbo-devel libpng-devel libffi-devel gtk3-devel gtk4-devel libadwaita-devel \
    gstreamer1-devel gstreamer1-plugins-base-devel glib2-devel polkit-devel spirv-tools libinput-utils \
    xorg-x11-server-Xvfb dbus-daemon xcursorgen xorg-x11-apps capitaine-cursors ibm-plex-fonts-all \
    google-noto-sans-symbols2-fonts symbols-nerd-fonts nerd-fonts kwriteconfig6 coursier \
    rpmfusion-free-release pipewire-utils pam_gnome_keyring gnome-keyring-pam; do
    line="$(q "$n" | head -n 1)"
    printf '%-36s %s\n' "$n" "${line:-MISSING}"
done
echo "== which package provides"
for f in /usr/bin/kwriteconfig6 /usr/lib64/security/pam_gnome_keyring.so /usr/bin/xcursorgen /usr/bin/rsvg-convert \
    /usr/lib64/pkgconfig/libeis-1.0.pc /usr/lib64/pkgconfig/glesv2.pc /usr/bin/qsb /usr/lib64/qt6/bin/qsb; do
    printf '%-46s %s\n' "$f" "$(dnf -q repoquery --qf '%{name}' --whatprovides "$f" 2> /dev/null | sort -u | tr '\n' ' ')"
done
dnf -y -q install dnf-plugins-core > /dev/null 2>&1 || true
for copr in solopasha/hyprland atim/starship; do
    echo "== copr ${copr}"
    if dnf -y -q copr enable "${copr}" > /dev/null 2>&1; then
        dnf -q repoquery --available --qf '%{name} %{version}-%{release}\n' --repo "copr:copr.fedorainfracloud.org:${copr/\//:}" 2> /dev/null | sort -u | head -n 60
    else
        echo "(cannot enable)"
    fi
done
