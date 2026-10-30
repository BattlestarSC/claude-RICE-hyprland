# shellcheck shell=bash
# Arch Linux: pacman, official repositories only (D2), systemd. Interface: lib/platform.sh.

# shellcheck disable=SC2034  # used by install.sh and lib/
declare -g PLAT_NAME="Arch Linux" PKG_DIR="${REPO}/packages"

plat_preflight() {
    [[ -f /etc/arch-release ]] || die "this does not look like Arch Linux (/etc/arch-release not found)"
    command -v pacman > /dev/null || die "pacman not found"
    if [[ -e /var/lib/pacman/db.lck ]]; then
        die "pacman is busy or crashed (/var/lib/pacman/db.lck exists); finish or remove it, then re-run"
    fi
    [[ -f /var/lib/pacman/sync/extra.db ]] || die "no pacman sync database; run: sudo pacman -Syu"
    getent hosts archlinux.org > /dev/null || die "no network (cannot resolve archlinux.org)"
}

# Checked against the local sync database (no -Sy here: syncing without upgrading would leave the
# system half-updated if the installer stops before pacman -Syu).
plat_available() {
    local name
    for name in "$@"; do
        pacman -Si -- "${name}" > /dev/null 2>&1 && printf '%s\n' "${name}"
    done
    return 0
}

# One transaction, always with -u: never a partial upgrade (arch-install.md rule 3).
plat_install() {
    local flags=(-Syu --needed)
    (( ASSUME_YES )) && flags+=(--noconfirm)
    as_root pacman "${flags[@]}" -- "$@"
}

plat_service_enable() { as_root systemctl enable "$1.service"; }
plat_display_manager() { systemd_display_manager; }
plat_set_display_manager() { systemd_set_display_manager "$@"; }

# The JDK the Scala toolchain supports (D42) must be the default when others exist.
plat_set_java() {
    command -v archlinux-java > /dev/null || (( DRY_RUN )) || return 0
    local current
    current="$(archlinux-java get 2> /dev/null || true)"
    if [[ "${current}" != "java-${JDK_VERSION}-openjdk" ]]; then
        info "default Java: java-${JDK_VERSION}-openjdk${current:+ (was ${current})}"
        as_root archlinux-java set "java-${JDK_VERSION}-openjdk"
    fi
}
