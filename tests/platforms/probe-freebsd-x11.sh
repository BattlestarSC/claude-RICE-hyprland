#!/usr/bin/env bash
# tests/platforms/probe-freebsd-x11.sh: FreeBSD package names and versions for the i3/X11 desktop
# (lib/platform/freebsd.sh, desktop "i3"). Run as root in a FreeBSD VM. NAME VERSION or "-".
set -Eeuo pipefail
echo "== $(freebsd-version) $(uname -m)"
pkg -o ASSUME_ALWAYS_YES=yes update -q > /dev/null 2>&1 || true
names=(
  i3 i3-gaps i3status i3blocks i3lock i3lock-color xss-lock xautolock xidlehook xsecurelock
  polybar picom compton dunst rofi feh xwallpaper hsetroot nitrogen maim scrot slop xclip xsel
  greenclip clipmenu clipcat xdotool xprop xrandr xset xsetroot xinput setxkbmap xrdb autorandr
  arandr numlockx xorg xorg-minimal xorg-server xf86-input-libinput xf86-video-amdgpu xinit
  lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings slick-greeter
  polkit-gnome lxqt-policykit mate-polkit gnome-keyring xdg-desktop-portal-gtk
  pulseaudio pavucontrol pulseaudio-module-sndio playerctl volumeicon sndio virtual_oss
  redshift xbacklight network-mgr networkmgr wifimgr udiskie automount
  kitty alacritty xterm noto-emoji papirus-icon-theme capitaine-cursors xcursor-themes
  xdg-utils xdg-user-dirs libnotify dunstify jq python3 py311-i3ipc py312-i3ipc i3ipc
  imagemagick7 ImageMagick7 librsvg2-rust
)
for n in "${names[@]}"; do
    printf '%-30s %s\n' "$n" "$(pkg rquery '%v' "$n" 2> /dev/null | head -n 1 || true)"
done | sed 's/ $/ -/'
echo "== pkg search i3 / lock / clip / polkit / picom"
for q in '^i3' 'lock' 'clip' 'polkit' 'picom' 'greeter'; do
    pkg search -q -x "${q}" 2> /dev/null | head -n 25 || true
done
echo "== lightdm files"
pkg install -y lightdm lightdm-gtk-greeter i3 > /dev/null 2>&1 || true
pkg info -l lightdm lightdm-gtk-greeter i3 2> /dev/null | grep -E 'etc/|xsessions|xgreeters|pam.d|Xsession|sbin|bin/' | head -n 60 || true
echo "== mixer"
mixer --help 2>&1 | head -n 20 || true
man -w mixer 2> /dev/null || true
