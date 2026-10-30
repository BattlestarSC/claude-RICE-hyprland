#!/usr/bin/env bash
# tests/installer/pam_keyring.sh [PAM_FILE]: lib/pam-keyring.awk (via with_keyring_pam) on a PAM
# service file. Without an argument it uses a sample shaped like Arch's /etc/pam.d/greetd; CI
# also runs it on the real file from the greetd package. Checks: both module lines appear once,
# auth after the last auth line, session after the last session line, nothing else changes,
# and a second pass is byte-identical (no backup on re-runs).
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK_DIR="$(mktemp -d)"
REPO="${repo}"
trap 'rm -rf -- "${WORK_DIR}"' EXIT
# shellcheck source=lib/system.sh
source "${repo}/lib/system.sh"

src="${1:-}"
if [[ -z "${src}" ]]; then
    src="${WORK_DIR}/sample"
    printf '%s\n' '#%PAM-1.0' '' \
        'auth       required     pam_securetty.so' \
        'auth       requisite    pam_nologin.so' \
        'auth       include      system-local-login' \
        'account    include      system-local-login' \
        'session    include      system-local-login' \
        '-session   optional     pam_systemd.so' > "${src}"
fi
fails=0
result() { # result NAME STATUS
    if (( $2 == 0 )); then echo "ok   $1"; else echo "FAIL $1"; fails=$((fails + 1)); fi
}
line_type() { awk -v want="$2" '{ t = $1; sub(/^-/, "", t) } t == want { n = NR } END { print n }' "$1"; }

once="$(with_keyring_pam "${src}")"
twice="$(with_keyring_pam "${once}")"
auth_line="$(sed -n "$(line_type "${once}" auth)p" "${once}")"
session_line="$(sed -n "$(line_type "${once}" session)p" "${once}")"

if [[ "$(grep -c '^auth .*pam_gnome_keyring\.so$' "${once}")" == 1 ]]; then result "one auth line" 0; else result "one auth line" 1; fi
if [[ "$(grep -c '^session .*pam_gnome_keyring\.so auto_start$' "${once}")" == 1 ]]; then result "one session line" 0; else result "one session line" 1; fi
if [[ "${auth_line}" == *pam_gnome_keyring.so ]]; then result "auth module is the last auth line" 0; else result "auth module is the last auth line" 1; fi
if [[ "${session_line}" == *"pam_gnome_keyring.so auto_start" ]]; then result "session module is the last session line" 0; else result "session module is the last session line" 1; fi
# cmp/diff are not in Arch's base: compare contents in bash.
if [[ "$(grep -v pam_gnome_keyring "${once}")" == "$(cat -- "${src}")" ]]; then result "only the two lines added" 0; else result "only the two lines added" 1; fi
if [[ "$(cat -- "${twice}")" == "$(cat -- "${once}")" ]]; then result "second pass changes nothing" 0; else result "second pass changes nothing" 1; fi
printf -- '--- result (%s)\n' "${src}"
cat -- "${once}"

if (( fails )); then
    echo "${fails} failure(s)"
    exit 1
fi
echo OK
