#!/usr/bin/env bash
# Render the rofi themes headlessly and save screenshots. Dev-only.
#
#   tests/rofi-render.sh OUTDIR
#
# Needs: Xvfb, rofi (>= 1.7; X11 is fine, the rasi language is the same as on Wayland),
# rsvg-convert, hsetroot, ImageMagick (import), Papirus icons, python3.
# Hyprland's blur cannot be reproduced here: Orbit shows the wallpaper through its
# translucent body unblurred. Everything else (layout, colors, icons, text) is real.
set -Eeuo pipefail

out=${1:?usage: tests/rofi-render.sh OUTDIR}
repo=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$out"
out=$(cd "$out" && pwd)

work=$(mktemp -d)
trap 'kill "${xvfb_pid:-0}" 2>/dev/null || true; rm -rf "$work"' EXIT

export HOME="$work/home" XDG_CONFIG_HOME="$work/home/.config" XDG_DATA_HOME="$work/home/.local/share"
mkdir -p "$XDG_CONFIG_HOME/rofi" "$XDG_DATA_HOME/applications" "$XDG_DATA_HOME/rice/art"

# Same layout the installer will create.
cp "$repo/config/rofi/config.rasi" "$XDG_CONFIG_HOME/rofi/"
cp "$repo"/themes/quasar/rofi/*.rasi "$XDG_CONFIG_HOME/rofi/"
# rofi treats a missing @import as fatal (it shows the error in place of the menu), so the
# user override file must always exist. The installer creates it empty and never overwrites it.
: > "$XDG_CONFIG_HOME/rofi/local.rasi"

palette="$repo/colors/quasar.toml"
python3 "$repo/tools/spacegen.py" "$palette" planet 256 orange --ring --seed 3 > "$work/planet.svg"
python3 "$repo/tools/spacegen.py" "$palette" wallpaper 1600 1000 --seed 7 > "$work/wall.svg"
rsvg-convert -w 128 -h 128 "$work/planet.svg" -o "$XDG_DATA_HOME/rice/art/planet.png"
rsvg-convert "$work/wall.svg" -o "$work/wall.png"

# Desktop entries with real icon names from Papirus.
while IFS='|' read -r name icon comment categories; do
  cat > "$XDG_DATA_HOME/applications/${icon}.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$name
Comment=$comment
Icon=$icon
Exec=true
Categories=$categories
EOF
done <<'APPS'
Firefox|firefox|Browse the World Wide Web|Network;WebBrowser;
Blender|blender|3D modeling, animation, rendering and post-production|Graphics;3DGraphics;
Steam|steam|Manage and play games on Steam|Game;
Discord|discord|All-in-one voice and text chat|Network;Chat;
Code - OSS|code-oss|Code editing. Redefined.|Development;IDE;
Inkscape|inkscape|Create and edit Scalable Vector Graphics images|Graphics;VectorGraphics;
Heroic Games Launcher|heroic|Open source GOG and Epic Games launcher|Game;
Timeshift|timeshift|System restore utility|System;
APPS
export XDG_DATA_DIRS="$XDG_DATA_HOME:/usr/share"

export DISPLAY=:99
Xvfb "$DISPLAY" -screen 0 1600x1000x24 >/dev/null 2>&1 &
xvfb_pid=$!
sleep 1
hsetroot -cover "$work/wall.png" >/dev/null

# The Nerd Font is not available here; fall back to plain JetBrains Mono for the render.
font_fix='* { font: "JetBrains Mono 12"; }'

shot() { # name, then the rofi command line
  local name=$1; shift
  "$@" 2>"$out/$name.log" &
  local pid=$!
  sleep 2
  import -window root "$out/$name.png"
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  [[ -s $out/$name.log ]] && { echo "--- $name stderr:"; cat "$out/$name.log"; }
  echo "wrote $out/$name.png"
}

shot orbit rofi -show drun -theme-str "$font_fix"
shot orbit-filter rofi -show drun -filter bl -theme-str "$font_fix"
shot deck-session sh -c "printf '%s\n' '  lock' '󰍃  log out' '󰤄  suspend' '  reboot' '  shut down' |
  rofi -dmenu -p session -mesg 'uptime 3:26 · 2 monitors' -theme deck -theme-str '$font_fix'"
