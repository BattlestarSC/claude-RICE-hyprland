#!/usr/bin/env bash
# tests/platforms/gentoo-pretend.sh: the Gentoo installer up to the package transaction, which
# Portage only resolves (emerge --pretend): profile checks, overlays, the files in
# /etc/portage/package.*/rice, package names, then keywords, USE flags, licences, slots and
# blockers for the whole selection. Run as the sudo user in a Gentoo container (see
# tests/platforms/gentoo-resolve.sh). Compiling all of it does not fit a CI job.
set -Eeuo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.."
# shellcheck source=install.sh
source ./install.sh
ASSUME_YES=1
detect_platform
preflight
ask_plan
resolve_packages
show_plan
start_backups
plat_setup_repos
# Real, like the installer: the cycle-breaking builds happen before the main transaction.
gentoo_break_cycles
mapfile -t opts < <(gentoo_emerge_opts)
printf '\n######## emerge --pretend (%s packages)\n' "${#PKG_REQUIRED[@]}"
# --autounmask=y with --autounmask-write=n: on failure Portage prints the exact keyword, USE and
# licence changes it would need, which is what this test is for.
if sudo emerge --pretend "${opts[@]/--autounmask=n/--autounmask=y}" --autounmask-write=n \
    --autounmask-continue=n "${PKG_REQUIRED[@]}" 2>&1 | tee /tmp/pretend.log; then
    echo "RESOLVED: $(grep -c '^\[ebuild' /tmp/pretend.log) ebuilds, $(grep -c '^\[binary' /tmp/pretend.log) binary"
else
    echo "NOT RESOLVED"
    exit 1
fi
