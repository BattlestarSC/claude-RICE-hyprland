#!/usr/bin/env bash
# tests/platforms/gentoo-resolve.sh PROFILE: in a gentoo/stage3 container (as root), switch to
# PROFILE (e.g. default/linux/amd64/23.0/desktop or .../desktop/systemd), create a sudo user and
# run tests/platforms/gentoo-pretend.sh as that user. The repository is expected at /src.
set -Eeuo pipefail
profile="$1" user=builder
# Docker without privileges cannot unshare; Portage then only warns, on every call.
export FEATURES="-ipc-sandbox -network-sandbox -pid-sandbox"
# shellcheck disable=SC2016  # make.conf expands ${FEATURES} itself
printf 'FEATURES="${FEATURES} %s"\n' "${FEATURES}" >> /etc/portage/make.conf
emerge-webrsync -q > /dev/null 2>&1
eselect profile set "${profile}"
echo "profile: $(readlink /etc/portage/make.profile)"
# A sudo user stands in for the owner (wheel, NOPASSWD = "typed the password once").
emerge --quiet-build=y --oneshot --noreplace app-admin/sudo dev-vcs/git > /dev/null
useradd -m -G wheel -s /bin/bash "${user}"
mkdir -p /etc/sudoers.d
grep -q '^@includedir /etc/sudoers.d\|^#includedir /etc/sudoers.d' /etc/sudoers || echo '@includedir /etc/sudoers.d' >> /etc/sudoers
printf '%%wheel ALL=(ALL:ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/10-admin
chmod 0440 /etc/sudoers.d/10-admin
cp -r /src "/home/${user}/rice"
chown -R "${user}:${user}" "/home/${user}/rice"
su - "${user}" -c 'bash ~/rice/tests/platforms/gentoo-pretend.sh'
