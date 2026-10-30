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
pacman -Syu --noconfirm --needed sudo git
# The docker image skips man pages and docs (NoExtract); keep that, it only saves space.
useradd -m -G wheel "${user}"
# A wheel user whose sudo does not ask for a password stands in for "types the password once".
printf '%%wheel ALL=(ALL:ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/10-wheel
chmod 0440 /etc/sudoers.d/10-wheel
cp -r /src "/home/${user}/rice"
chown -R "${user}:${user}" "/home/${user}/rice"

as_user() { su - "${user}" -c "$1"; }

section "install.sh --yes (first run)"
start=${SECONDS}
as_user 'cd ~/rice && ./install.sh --yes' 2>&1 | tee /tmp/run1.log
printf 'first run: %d s\n' $((SECONDS - start))

section "verify"
as_user "/home/${user}/rice/tests/installer/verify-install.sh"

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

section "disk"
df -h / /var/cache/pacman/pkg 2> /dev/null || true
echo "FULL INSTALL OK"
