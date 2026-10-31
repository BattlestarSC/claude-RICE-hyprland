#!/usr/bin/env bash
# tests/installer/full-install.sh: a real (not dry) run of ./install.sh --yes on Arch, as a
# normal user with sudo rights, followed by tests/installer/verify-install.sh and a second run
# that must change nothing. Run as root inside a disposable archlinux:latest container; the
# repository is expected at /src (read-only is fine):
#
#   docker run --rm -v "$PWD:/src:ro" archlinux:latest bash /src/tests/installer/full-install.sh
#
# What a container cannot show: Hyprland, greetd or any GUI actually starting (no GPU, no
# systemd as PID 1). Everything up to that point runs for real: the pacman transaction,
# every post-install step, the setup scripts, the system changes.
set -Eeuo pipefail

user=builder
section() { printf '\n######## %s\n' "$*"; }

section "base system"
# The repository: /src in the Linux containers; the FreeBSD VM job passes its checkout in SRC.
src="${SRC:-/src}"
if [[ "$(uname -s)" == FreeBSD ]]; then
    distro=freebsd
else
    # shellcheck source=/dev/null
    distro="$(. /etc/os-release && printf '%s' "${ID}")"
fi
admin_group=wheel
sudoers_d=/etc/sudoers.d
case "${distro}" in
    arch)
        pacman -Syu --noconfirm --needed sudo git
        xvfb=(pacman -S --noconfirm --needed xorg-server-xvfb)
        ;;
    ubuntu)
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -q
        apt-get install -y -q sudo git ca-certificates locales
        admin_group=sudo
        xvfb=(apt-get install -y -q xvfb)
        ;;
    fedora)
        dnf -y -q install sudo git
        xvfb=(dnf -y -q install xorg-x11-server-Xvfb)
        ;;
    freebsd)
        env ASSUME_ALWAYS_YES=yes pkg install -y sudo git bash
        sudoers_d=/usr/local/etc/sudoers.d
        xvfb=(true)   # the Quickshell check below is Linux-only
        ;;
    *) echo "full-install.sh: no base setup for ${distro}"; exit 2 ;;
esac
if [[ "${distro}" == freebsd ]]; then
    pw useradd "${user}" -m -G "${admin_group}" -s /usr/local/bin/bash
else
    useradd -m -G "${admin_group}" -s /bin/bash "${user}"
fi
# A sudo user whose sudo does not ask for a password stands in for "types the password once".
mkdir -p "${sudoers_d}"
printf '%%%s ALL=(ALL:ALL) NOPASSWD: ALL\n' "${admin_group}" > "${sudoers_d}/10-admin"
chmod 0440 "${sudoers_d}/10-admin"
cp -r "${src}" "/home/${user}/rice"
chown -R "${user}:${user}" "/home/${user}/rice"

as_user() { su - "${user}" -c "$1"; }

# Whatever happens, end with the installer's warnings (lines starting with "!"), so they are
# in the last screen of a long CI log.
summary() {
    local rc=$?
    section "installer warnings"
    grep -h '^  ! ' /tmp/run1.log /tmp/run2.log 2> /dev/null | sort | uniq -c || echo "(none)"
    section "Quickshell under Xvfb (see above)"
    cat /tmp/qs-summary.txt 2> /dev/null || echo "(not run)"
    section "size"
    grep -h '^first run:' /tmp/full-install-time 2> /dev/null || true
    du -sxh /usr /opt /var/cache/pacman/pkg /var/cache/apt/archives "/home/${user}" 2> /dev/null || true
    return "${rc}"
}
trap summary EXIT

section "install.sh --yes (first run)"
start=${SECONDS}
as_user 'cd ~/rice && ./install.sh --yes' 2>&1 | tee /tmp/run1.log
printf 'first run: %d s\n' $((SECONDS - start)) | tee /tmp/full-install-time

section "verify"
as_user "/home/${user}/rice/tests/installer/verify-install.sh"

section "Quickshell loads the shell (Xvfb; informational)"
if [[ "${distro}" != freebsd ]]; then
# No Wayland compositor can run here, so Hyprland/Pipewire/layer-shell features are missing, but
# QML syntax, imports and type errors in the real shell show up in its log.
"${xvfb[@]}" > /dev/null
# shellcheck disable=SC2016  # expanded by the user's shell, not this one
as_user 'export XDG_RUNTIME_DIR=$(mktemp -d) DISPLAY=:99 QT_QPA_PLATFORM=xcb
    Xvfb :99 -screen 0 1920x1080x24 > /dev/null 2>&1 & xpid=$!
    sleep 2
    timeout 25 dbus-run-session -- quickshell > /tmp/qs.log 2>&1 || true
    kill $xpid 2> /dev/null || true' || true
{ grep -E '\.qml:[0-9]+|ReferenceError|TypeError|is not a type|is not installed|Cannot assign|Type .* unavailable|failed to load|ERROR' /tmp/qs.log | sort | uniq -c | head -n 60 || echo "(no QML errors in the log)"; } | tee /tmp/qs-summary.txt
fi

section "install.sh --yes (second run: must change nothing)"
as_user 'cd ~/rice && ./install.sh --yes' 2>&1 | tee /tmp/run2.log
if ! grep -qE '^ *0 written, [0-9]+ already current, 0 backed up' /tmp/run2.log; then
    echo "FAIL second run changed files:"
    grep -E 'written,|would|install -D' /tmp/run2.log || true
    exit 1
fi
if grep -q 'replaced file(s) backed up' /tmp/run2.log; then
    echo "FAIL second run replaced system files:"
    grep -B2 -A2 'backed up' /tmp/run2.log || true
    exit 1
fi
echo "ok   second run: nothing written, nothing backed up (home and /etc)"

echo "FULL INSTALL OK"
