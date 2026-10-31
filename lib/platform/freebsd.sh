# shellcheck shell=bash
# FreeBSD 15 (amd64): binary packages with pkg; rc.conf services through sysrc; no systemd and
# no greetd (its VT and /proc code is Linux-only), so Hyprland starts after a console login.
# Hyprland itself comes from an overlay of the FreeBSD port moved to 0.57.0 (ports/) while the
# package is older. Interface: lib/platform.sh. Facts: docs/knowledge-base/platforms.md#freebsd.

declare -g PLAT_NAME
# shellcheck disable=SC2034  # used by install.sh
PLAT_NAME="FreeBSD $(freebsd-version -u 2> /dev/null || uname -r)"
# shellcheck disable=SC2034  # used by install.sh and lib/
declare -g PKG_DIR="${REPO}/packages/freebsd" ZSH_BIN=/usr/local/bin/zsh \
    FIREFOX_POLICY_DIR=/usr/local/lib/firefox/distribution \
    PLAT_GREETER=tty PLAT_FIRST_TTY=/dev/ttyv0
# Build dependencies of the Hyprland port (ports/x11-wm/hyprland/Makefile).
# shellcheck disable=SC2034
declare -ga PLAT_EXTRA_LISTS=(build.txt)

# The ports framework (Mk/, Templates/, Keywords/) at the commit the overlay was taken from.
declare -g FREEBSD_PORTS_URL=https://github.com/freebsd/freebsd-ports \
    FREEBSD_PORTS_COMMIT=e3ae9611c587f6fbb0127a1201fdeac130057797
declare -g FREEBSD_CACHE="${XDG_CACHE_HOME:-${HOME}/.cache}/rice/freebsd"

freebsd_pkg() { as_root env ASSUME_ALWAYS_YES="$(( ASSUME_YES ))" pkg "$@"; }

plat_preflight() {
    local major
    major="$(freebsd-version -u | cut -d. -f1)"
    (( major >= 15 )) || die "this installer supports FreeBSD 15 or newer (this is $(freebsd-version -u))"
    [[ "$(uname -m)" == amd64 ]] || die "only amd64 is supported"
    command -v sudo > /dev/null || die "sudo not found: pkg install sudo, then allow your user (visudo)"
    host pkg.FreeBSD.org > /dev/null 2>&1 || drill pkg.FreeBSD.org > /dev/null 2>&1 ||
        die "no network (cannot resolve pkg.FreeBSD.org)"
}

# Every name in the package catalog (one call), intersected with the requested names.
plat_available() {
    (( DRY_RUN )) || freebsd_pkg update -q
    pkg rquery -a '%n' 2> /dev/null | awk 'NR == FNR { want[$0] = 1; next } ($0 in want)' \
        <(printf '%s\n' "$@") -
}

plat_plan() {
    info "packages: pkg (FreeBSD-ports repository); services in /etc/rc.conf: dbus, seatd"
    info "you join group video (seatd); Hyprland starts after a console login on ttyv0"
    if ! freebsd_hyprland_packaged; then
        info "Hyprland 0.57.0 built from the FreeBSD port moved to 0.57 (ports/; FreeBSD has $(pkg rquery '%v' hyprland 2> /dev/null || echo none))"
    fi
    info "rendered or downloaded: Capitaine cursors, adw-gtk3, zsh-history-substring-search"
    return 0
}

plat_install() {
    local opts=(install)
    (( ASSUME_YES )) && opts+=(-y)
    as_root pkg "${opts[@]}" "$@"
}

# Is the repository's Hyprland new enough for the Lua config?
freebsd_hyprland_packaged() {
    local v
    v="$(pkg rquery '%v' hyprland 2> /dev/null | sed 's/[_,].*//' || true)"
    [[ -n "${v}" && "$(printf '%s\n' 0.57.0 "${v}" | sort -V | head -n 1)" == 0.57.0 ]]
}

# Build ports/x11-wm/hyprland with the ports framework, as the user, and install the package.
freebsd_build_hyprland() {
    local ports="${FREEBSD_CACHE}/ports" port version
    port="${ports}/x11-wm/hyprland"
    version="$(sed -n 's/^DISTVERSION=[[:space:]]*//p' "${REPO}/ports/x11-wm/hyprland/Makefile")"
    if [[ "$(pkg query '%v' hyprland 2> /dev/null || true)" == "${version}" ]]; then
        note "Hyprland ${version}: already installed"
        return 0
    fi
    info "building Hyprland ${version} with the ports framework (10-30 minutes)"
    if (( DRY_RUN )); then
        note "would fetch ${FREEBSD_PORTS_URL} @ ${FREEBSD_PORTS_COMMIT} (Mk, Templates, Keywords)"
        note "would build ${REPO}/ports/x11-wm/hyprland and install the package"
        return 0
    fi
    mkdir -p -- "${ports}"
    git -C "${ports}" init -q
    git -C "${ports}" sparse-checkout set Mk Templates Keywords
    git -C "${ports}" fetch -q --depth 1 --filter=blob:none "${FREEBSD_PORTS_URL}" "${FREEBSD_PORTS_COMMIT}"
    git -C "${ports}" -c advice.detachedHead=false checkout -q --force FETCH_HEAD
    rm -rf -- "${port}"
    mkdir -p -- "${port}"
    cp -R "${REPO}/ports/x11-wm/hyprland/." "${port}/"
    local make_env=(env PORTSDIR="${ports}" WRKDIRPREFIX="${FREEBSD_CACHE}/work"
        DISTDIR="${FREEBSD_CACHE}/distfiles" PACKAGES="${FREEBSD_CACHE}/packages" BATCH=yes)
    "${make_env[@]}" make -C "${port}" clean > /dev/null
    "${make_env[@]}" make -C "${port}" stage
    # The overlay carries no plist: list what 0.57 stages (makeplist's first line is a reminder).
    "${make_env[@]}" make -C "${port}" makeplist | tail -n +2 > "${port}/pkg-plist"
    "${make_env[@]}" make -C "${port}" package
    # Replace a packaged (older) Hyprland, which other packages may have pulled in.
    if pkg info -e hyprland; then
        as_root pkg delete -f -y hyprland
    fi
    as_root pkg add "${FREEBSD_CACHE}/packages/All/hyprland-${version}.pkg"
}

plat_extras() {
    step "What FreeBSD does not package"
    if freebsd_hyprland_packaged; then
        plat_install hyprland
    else
        freebsd_build_hyprland
    fi
    extras_env
    extras_build "${ZSH_HSS_PIN}"
    extras_build "${CAPITAINE_PIN}"
    extras_adw_gtk3
    # gcc15 installs gfortran15; the editors and rice-lsp-setup look for gfortran.
    if ! command -v gfortran > /dev/null && command -v gfortran15 > /dev/null; then
        run mkdir -p -- "${HOME}/.local/bin"
        run ln -sfn "$(command -v gfortran15)" "${HOME}/.local/bin/gfortran"
    fi
    info "services: dbus, seatd; group video for $(id -un)"
    plat_service_enable dbus
    plat_service_enable seatd
    if ! id -Gn | tr ' ' '\n' | grep -qx video; then
        as_root pw groupmod video -m "$(id -un)"
    fi
    if (( HAS_AMD )) && ! sysrc -n kld_list 2> /dev/null | grep -qw amdgpu; then
        info "kernel module: amdgpu (drm-kmod), loaded at boot"
        as_root sysrc kld_list+=" amdgpu"
    fi
}

plat_installed() { pkg info -e "$1"; }

# Bluetooth and NetworkManager are Linux services; FreeBSD's equivalents are base-system rc
# scripts the owner configures (bluetooth(4), wpa_supplicant(8)).
plat_service_enable() {
    case "$1" in
        bluetooth | NetworkManager) return 0 ;;
    esac
    if [[ "$(sysrc -n "${1}_enable" 2> /dev/null || true)" != YES ]]; then
        as_root sysrc "${1}_enable=YES"
    fi
}

# A display manager enabled in rc.conf would take the console the session starts on.
plat_display_manager() {
    local dm
    for dm in sddm lightdm gdm slim xdm; do
        [[ "$(sysrc -n "${dm}_enable" 2> /dev/null || true)" == YES ]] && { echo "${dm}"; return 0; }
    done
    return 0
}

plat_set_display_manager() {
    local old="${2:-}"
    [[ -n "${old}" ]] || return 0
    info "disabling ${old} (it would take the console)"
    as_root sysrc "${old}_enable=NO"
}

# javavmwrapper picks the newest installed JDK; JDK 25 is the only one the rice installs.
plat_set_java() { return 0; }
