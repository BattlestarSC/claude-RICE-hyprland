#!/usr/bin/env bash
# tests/x11/run.sh [OUT_DIR]: the i3 desktop without installing it. Deploys the rice's files for
# RICE_DESKTOP=i3 into a throwaway $HOME with the installer's own file layer (lib/files.sh), then
# runs tests/x11/smoke.sh there (Xvfb: i3, picom, polybar, dunst, xss-lock, the lock screen).
# CI runs it on Ubuntu (ci.yml, older i3/picom/polybar than FreeBSD's); the FreeBSD VM job runs
# smoke.sh after a real install. Needs the programs smoke.sh lists, plus rsvg-convert and jq.
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "${tmp}"' EXIT
home="${tmp}/home"
real_home="${HOME}"
(
    # shellcheck disable=SC2030  # this HOME is the subshell's on purpose
    export HOME="${home}" XDG_CONFIG_HOME="${home}/.config" XDG_DATA_HOME="${home}/.local/share"
    unset XDG_STATE_HOME
    REPO="${repo}" PALETTE=quasar CURSOR_THEME=capitaine-cursors-light RICE_DESKTOP=i3
    WORK_DIR="$(mktemp -d -p "${tmp}")"
    SKY_MODE=still SKY_LAYOUT=mirror SKY_IMAGE=""
    # shellcheck source=lib/log.sh
    source "${repo}/lib/log.sh"
    # shellcheck source=lib/deploy.sh
    source "${repo}/lib/deploy.sh"
    # shellcheck source=lib/files.sh
    source "${repo}/lib/files.sh"
    start_backups
    deploy_user_files > /dev/null
    build_assets > /dev/null
)
# Fonts the bar and the notifications use, where the system has them only in the real home.
if [[ -d "${real_home}/.local/share/fonts" ]]; then
    mkdir -p "${home}/.local/share"
    cp -R "${real_home}/.local/share/fonts" "${home}/.local/share/"
fi
HOME="${home}" XDG_CONFIG_HOME="${home}/.config" XDG_DATA_HOME="${home}/.local/share" \
    "${repo}/tests/x11/smoke.sh" "${1:-${tmp}/shots}"
