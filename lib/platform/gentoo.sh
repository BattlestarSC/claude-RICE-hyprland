# shellcheck shell=bash
# Gentoo (OpenRC or systemd, amd64, a 23.0 desktop profile): Portage builds everything from
# source, with the GURU, hyproverlay (Hyprland 0.57 stack) and librewolf overlays. Binary
# packages only where no source ebuild exists (VSCodium). Keywords and USE flags the rice needs
# go to /etc/portage/package.{accept_keywords,use,license}/rice. Interface: lib/platform.sh.
# Facts: docs/knowledge-base/platforms.md#gentoo.

# shellcheck disable=SC2034  # used by install.sh and lib/
declare -g PLAT_NAME="Gentoo (${PLAT_INIT})" PKG_DIR="${REPO}/packages/gentoo" \
    ZSH_BIN=/bin/zsh GREETER_USER=greetd
# shellcheck disable=SC2034
declare -ga PLAT_EXTRA_LISTS=()
# OpenRC: elogind is the seat and session manager (systemd-logind's role), and power actions in
# the greeter go through its loginctl.
if [[ "${PLAT_INIT}" == openrc ]]; then
    PLAT_EXTRA_LISTS=(openrc.txt)
    # agetty runs on tty1-6 under OpenRC (/etc/inittab); greetd takes the first free VT.
    # shellcheck disable=SC2034
    declare -g POWER_CTL=loginctl GREETD_VT=7
fi
# Overlays this module enables (eselect repository), and the portage config it writes.
declare -ga GENTOO_OVERLAYS=(guru hyproverlay librewolf)
declare -g GENTOO_CONF="${REPO}/config/portage"

gentoo_emerge_opts() {
    local opts=(--verbose --noreplace --update --deep --newuse --autounmask=n --quiet-build=y)
    (( ASSUME_YES )) || opts+=(--ask)
    printf '%s\n' "${opts[@]}"
}

plat_preflight() {
    command -v emerge > /dev/null || die "emerge not found"
    [[ "$(portageq envvar ARCH 2> /dev/null)" == amd64 ]] || die "only amd64 is supported"
    local profile
    profile="$(readlink -f /etc/portage/make.profile)"
    [[ "${profile}" == */23.0/desktop* ]] ||
        die "use a 23.0 desktop profile first (eselect profile list; e.g. default/linux/amd64/23.0/desktop or .../desktop/systemd): it sets the USE flags a Wayland desktop needs"
    local d
    for d in package.accept_keywords package.use package.license; do
        [[ ! -e "/etc/portage/${d}" || -d "/etc/portage/${d}" ]] ||
            die "/etc/portage/${d} is a file; make it a directory (move the file into it as ${d}/main) and re-run"
    done
    getent hosts gentoo.org > /dev/null || die "no network (cannot resolve gentoo.org)"
}

# Atom without slot or repository, e.g. dev-java/openjdk:25 -> dev-java/openjdk.
gentoo_atom_dir() {
    local atom="${1%%::*}"
    printf '%s' "${atom%%:*}"
}

# Names in the main tree (a package directory exists), plus every overlay atom (name::repo):
# those exist once plat_setup_repos has synced the overlay.
plat_available() {
    local tree name
    tree="$(portageq get_repo_path / gentoo 2> /dev/null || echo /var/db/repos/gentoo)"
    for name in "$@"; do
        if [[ "${name}" == *::* ]]; then
            printf '%s\n' "${name}"
        elif compgen -G "${tree}/$(gentoo_atom_dir "${name}")/*.ebuild" > /dev/null; then
            printf '%s\n' "${name}"
        fi
    done
}

plat_plan() {
    info "overlays: ${GENTOO_OVERLAYS[*]} (eselect repository); keywords, USE flags and licenses in"
    info "  /etc/portage/package.{accept_keywords,use,license}/rice"
    info "everything is compiled by Portage (VSCodium is binary-only): expect many hours the first"
    info "  time (Qt, Firefox, Thunderbird, LibreWolf, LibreOffice, GHC, TeX Live)"
    [[ "${PLAT_INIT}" == openrc ]] && info "OpenRC: dbus and elogind are enabled at boot"
    return 0
}

plat_setup_repos() {
    step "Adding overlays and Portage settings"
    local need=() overlay enabled
    command -v eselect > /dev/null && eselect repository list > /dev/null 2>&1 ||
        need+=(app-eselect/eselect-repository)
    command -v git > /dev/null || need+=(dev-vcs/git)
    (( ${#need[@]} )) && as_root emerge --noreplace --oneshot --quiet-build=y "${need[@]}"
    enabled="$(eselect repository list -i 2> /dev/null || true)"
    for overlay in "${GENTOO_OVERLAYS[@]}"; do
        if ! grep -qE "^ *\[[0-9]+\] +${overlay}( |$)" <<< "${enabled}"; then
            as_root eselect repository enable "${overlay}"
        fi
        as_root emaint sync --repo "${overlay}"
    done
    local f
    for f in package.accept_keywords package.use package.license; do
        deploy_system_file "${GENTOO_CONF}/${f}" "/etc/portage/${f}/rice"
    done
}

plat_install() {
    local opts
    mapfile -t opts < <(gentoo_emerge_opts)
    as_root emerge "${opts[@]}" "$@"
}

plat_extras() {
    step "What Gentoo does not package"
    extras_env
    extras_build "${CAPITAINE_PIN}"
    if [[ "${PLAT_INIT}" == openrc ]]; then
        local svc
        for svc in dbus elogind; do
            plat_service_enable "${svc}"
        done
    fi
}

plat_installed() {
    local atom="${1%%::*}"
    [[ -n "$(portageq match / "${atom}" 2> /dev/null)" ]]
}

plat_service_enable() {
    if [[ "${PLAT_INIT}" == systemd ]]; then
        as_root systemctl enable "$1.service"
    elif ! rc-update show default 2> /dev/null | grep -qE "^ *$1 \|"; then
        as_root rc-update add "$1" default
    fi
}

# OpenRC: Gentoo's display managers run through the display-manager service
# (x11-misc/display-manager-init, DISPLAYMANAGER in /etc/conf.d/display-manager); greetd has its
# own init script.
plat_display_manager() {
    if [[ "${PLAT_INIT}" == systemd ]]; then
        systemd_display_manager
    elif rc-update show default 2> /dev/null | grep -qE '^ *display-manager \|'; then
        sed -n 's/^DISPLAYMANAGER="\{0,1\}\([^"]*\)"\{0,1\}/\1/p' /etc/conf.d/display-manager 2> /dev/null |
            tail -n 1 | sed 's/$/ (display-manager)/'
    elif rc-update show default 2> /dev/null | grep -qE '^ *greetd \|'; then
        echo greetd
    fi
    return 0
}

plat_set_display_manager() {
    local new="$1" old="${2:-}"
    if [[ "${PLAT_INIT}" == systemd ]]; then
        systemd_set_display_manager "$@"
        return 0
    fi
    if [[ "${old}" == *"(display-manager)" ]]; then
        info "replacing ${old% (display-manager)} (display-manager service) with ${new}"
        as_root rc-update del display-manager default
    fi
    plat_service_enable "${new}"
}

plat_set_java() {
    local vm="openjdk-${JDK_VERSION}"
    eselect java-vm list 2> /dev/null | grep -q "\b${vm}\b" || (( DRY_RUN )) || return 0
    if ! eselect java-vm show system 2> /dev/null | grep -q "\b${vm}\b"; then
        info "default JDK: ${vm}"
        as_root eselect java-vm set system "${vm}"
    fi
}
