#!/usr/bin/env bash
# Exercise the installer's file layer (lib/deploy.sh, lib/files.sh) in a throwaway $HOME:
# first install, re-run without changes, backup of a changed file, user hooks kept, captured
# monitors kept, cursor substitution, then a full ./install.sh --dry-run with stubbed system
# commands. No packages, no sudo, no network. Needs: bash, coreutils, jq, awk (all but jq in Arch's base).
#
#   tests/installer/run.sh
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -r -- "${tmp}"' EXIT
fails=0
pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }

# Run the file layer in a subshell with its own HOME; prints "written unchanged backed_up".
deploy_once() {
    (
        export HOME="${tmp}/home" XDG_CONFIG_HOME="${tmp}/home/.config" XDG_DATA_HOME="${tmp}/home/.local/share"
        unset XDG_STATE_HOME
        REPO="${repo}" PALETTE=quasar CURSOR_THEME="${1:-capitaine-cursors-light}"
        WORK_DIR="$(mktemp -d -p "${tmp}")"
        SKY_MODE=animated SKY_LAYOUT=mirror SKY_IMAGE=""
        # shellcheck source=lib/log.sh
        source "${repo}/lib/log.sh"
        # shellcheck source=lib/deploy.sh
        source "${repo}/lib/deploy.sh"
        # shellcheck source=lib/files.sh
        source "${repo}/lib/files.sh"
        start_backups
        deploy_user_files > /dev/null
        finish_backups
        printf '%s %s %s\n' "${DEPLOYED}" "${UNCHANGED}" "${BACKED_UP}"
    )
}

cfg="${tmp}/home/.config"
mkdir -p "${cfg}/kitty"
printf 'font_size 99\n' > "${cfg}/kitty/kitty.conf"       # a user's own file, must be backed up

read -r w u b <<< "$(deploy_once)"
if (( w > 100 && b == 1 )); then pass "first run writes files"; else fail "first run writes files"; fi
if grep -rqs "font_size 99" "${tmp}/home/.local/state/rice/backups"; then pass "user kitty.conf backed up"; else fail "user kitty.conf backed up"; fi
if grep -qs "kitty/kitty.conf" "${tmp}"/home/.local/state/rice/backups/*/manifest.tsv; then pass "manifest lists it"; else fail "manifest lists it"; fi
if [[ -f "${cfg}/rofi/local.rasi" && -f "${cfg}/foot/local.ini" ]]; then pass "local.rasi and local.ini created"; else fail "local.rasi and local.ini created"; fi
if [[ -x "${tmp}/home/.local/bin/rice-monitors" ]]; then pass "bin is executable"; else fail "bin is executable"; fi
if [[ $(jq -r .skyMode "${cfg}/rice/settings.json") == animated ]]; then pass "settings.json written"; else fail "settings.json written"; fi
if [[ "$(sha256sum < "${repo}/config/hypr/hyprland.lua")" == "$(sha256sum < "${cfg}/hypr/hyprland.lua")" ]]; then pass "hyprland.lua deployed"; else fail "hyprland.lua deployed"; fi

read -r w u b <<< "$(deploy_once)"
if (( w == 0 && b == 0 && u > 100 )); then pass "re-run changes nothing"; else fail "re-run changes nothing"; fi

printf 'include extra.conf\n' > "${cfg}/rofi/local.rasi"
printf 'vim_keys = False\n' >> "${cfg}/btop/btop.conf"            # apps rewrite these: must survive
printf '[texmaker]\nmine=1\n' > "${cfg}/texstudio/texstudio.ini"
sed -i 's/REPLACE-WITH-LEFT-PANEL-DESCRIPTION/ACME X1 S1/; s/REPLACE-WITH-RIGHT-PANEL-DESCRIPTION/ACME X1 S2/' \
    "${cfg}/hypr/conf/monitors.lua"
read -r w u b <<< "$(deploy_once)"
if grep -qs "extra.conf" "${cfg}/rofi/local.rasi"; then pass "user hook local.rasi kept"; else fail "user hook local.rasi kept"; fi
if grep -q "vim_keys = False" "${cfg}/btop/btop.conf" && grep -q "mine=1" "${cfg}/texstudio/texstudio.ini"; then pass "app-rewritten configs kept (btop, TeXstudio)"; else fail "app-rewritten configs kept (btop, TeXstudio)"; fi
if [[ -f "${tmp}/home/.local/share/rice/libreoffice/extension/registry/ColorScheme.xcu" ]]; then pass "LibreOffice theme staged"; else fail "LibreOffice theme staged"; fi
if grep -q "desc:ACME X1 S1" "${cfg}/hypr/conf/monitors.lua" && (( w == 0 )); then pass "captured panels kept"; else fail "captured panels kept"; fi

read -r w _ b <<< "$(deploy_once Bibata-Modern-Ice)"
if grep -q "^local cursor_theme = \"Bibata-Modern-Ice\"" "${cfg}/hypr/conf/env.lua" && (( w == 1 && b == 1 )); then pass "cursor choice reaches env.lua"; else fail "cursor choice reaches env.lua"; fi
if [[ -f "${cfg}/rice/settings.json" ]]; then pass "settings.json not overwritten"; else fail "settings.json not overwritten"; fi

# Full dry run with stubbed system commands: must finish and never call sudo or pacman -S.
stubs="${tmp}/stubs"
mkdir -p "${stubs}"
cat > "${stubs}/pacman" <<'STUB'
#!/bin/sh
[ "$1" = -Si ] && exit 0
echo "pacman called: $*" >&2; exit 99
STUB
cat > "${stubs}/sudo" <<'STUB'
#!/bin/sh
echo "sudo called: $*" >&2; exit 99
STUB
cat > "${stubs}/systemctl" <<'STUB'
#!/bin/sh
[ "$1" = is-active ] && exit 3
echo "systemctl called: $*" >&2; exit 99
STUB
cat > "${stubs}/getent" <<'STUB'
#!/bin/sh
echo "127.0.0.1 $2"
STUB
chmod +x "${stubs}"/*
if [[ -f /etc/arch-release && -f /var/lib/pacman/sync/extra.db && ${EUID} -ne 0 ]]; then
    out="$(HOME="${tmp}/dry" PATH="${stubs}:${PATH}" "${repo}/install.sh" --dry-run --yes 2>&1)" && rc=0 || rc=$?
    if (( rc == 0 )) && grep -q "==> Done" <<< "${out}"; then pass "install.sh --dry-run finishes"; else fail "install.sh --dry-run finishes"; fi
    if [[ ! -e "${tmp}/dry/.config" ]] && ! grep -q "called:" <<< "${out}"; then pass "dry run touched nothing"; else fail "dry run touched nothing"; fi
else
    printf 'skip install.sh --dry-run (needs Arch: /etc/arch-release, a pacman sync db, a non-root user)\n'
fi

if (( fails )); then
    printf '%d failed\n' "${fails}"
    exit 1
fi
printf 'OK\n'
