#!/usr/bin/env bash
# tests/platforms/tags.sh: latest release tags of upstream projects lib/pins.sh pins whose hosts
# the build environment cannot reach. Prints NAME TAG...
set -Eeuo pipefail
latest() { git ls-remote --tags --refs "$2" | awk '{print $2}' | sed 's|refs/tags/||' | grep -E '^v?[0-9]' | sort -V | tail -n 3 | tr '\n' ' '; }
for entry in \
    "wayland https://gitlab.freedesktop.org/wayland/wayland.git" \
    "wayland-protocols https://gitlab.freedesktop.org/wayland/wayland-protocols.git" \
    "quickshell https://git.outfoxxed.me/quickshell/quickshell"; do
    read -r name url <<< "${entry}"
    printf '%-20s %s\n' "${name}" "$(latest "${name}" "${url}")"
done
