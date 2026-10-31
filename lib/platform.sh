# shellcheck shell=bash
# Which system this is, and the module that knows its package manager, services and paths.
# Sourced by install.sh; detect_platform then sources lib/platform/<id>.sh. Docs:
# docs/knowledge-base/platforms.md.
#
# Every platform module provides (plat_ prefix = implemented per system):
#   PLAT_NAME, PKG_DIR                 display name; directory with the package lists
#   plat_preflight                     checks before anything changes (version, package db, lock)
#   plat_available NAME...             print the names the repositories have (one per line)
#   plat_installed NAME                true if the package is installed (used by the CI verifier)
#   plat_plan                          extra plan lines (repositories it will add, builds)
#   plat_setup_repos                   add repositories / overlays (after the plan is accepted)
#   plat_install NAME...               install packages (non-interactive with --yes)
#   plat_extras                        what packages cannot provide: source builds, upstream binaries
#   plat_service_enable NAME           enable a system service at boot
#   plat_display_manager               print the active display manager service, if any
#   plat_set_display_manager NAME OLD  make NAME the display manager (OLD: the one to disable)
#   plat_set_java                      make the D42 JDK the default
#   ZSH_BIN, GREETD_DIR, GREETER_USER, PAM_DIR, FIREFOX_POLICY_DIR, DATA_DIRS
#   POWER_CTL                          program with reboot/poweroff verbs for the greeter
#   GREETD_VT                          virtual terminal greetd runs on (free of gettys)
#   PLAT_GREETER, PLAT_FIRST_TTY       greetd, or tty: no greetd here, so Hyprland starts after a
#                                      console login on PLAT_FIRST_TTY (config/zsh/session.zsh)

PLAT_ID=""      # arch | ubuntu | gentoo | freebsd | fedora
PLAT_INIT=""    # systemd | openrc | rc

# os_release KEY: a value from /etc/os-release. The file is shell syntax and systems quote
# differently (Gentoo: ID='gentoo'), so it is read by a shell, in a subshell.
os_release() {
    # shellcheck source=/dev/null
    (. /etc/os-release && printf '%s' "${!1:-}")
}

detect_platform() {
    if [[ "$(uname -s)" == FreeBSD ]]; then
        PLAT_ID=freebsd
        PLAT_INIT=rc
    else
        [[ -r /etc/os-release ]] || die "cannot tell which system this is (/etc/os-release is missing)"
        local id
        id="$(os_release ID)"
        case "${id}" in
            arch | ubuntu | gentoo | fedora) PLAT_ID="${id}" ;;
            *) die "unsupported system '${id}': this installer knows Arch, Ubuntu 26.04, Gentoo, FreeBSD and Fedora" ;;
        esac
        PLAT_INIT=systemd
        if [[ "${PLAT_ID}" == gentoo ]] && [[ "$(readlink -f /etc/portage/make.profile 2> /dev/null)" != *systemd* ]]; then
            # shellcheck disable=SC2034  # used by lib/preflight.sh and the platform modules
            PLAT_INIT=openrc
        fi
    fi
    # shellcheck source=/dev/null
    source "${REPO}/lib/platform/${PLAT_ID}.sh"
}

# Defaults most systems share; a platform module overrides what differs.
# shellcheck disable=SC2034  # used by install.sh and the other lib/ modules
declare -g ZSH_BIN=/usr/bin/zsh GREETD_DIR=/etc/greetd GREETER_USER=greeter PAM_DIR=/etc/pam.d \
    FIREFOX_POLICY_DIR=/etc/firefox/policies POWER_CTL=systemctl \
    GREETD_VT=1 PLAT_GREETER=greetd PLAT_FIRST_TTY=/dev/tty1
# shellcheck disable=SC2034  # used by lib/desktop.sh
declare -ga DATA_DIRS=(/usr/local/share /usr/share)

# shellcheck disable=SC2034  # lists and names a platform module may add
declare -ga PLAT_EXTRA_LISTS=() PLAT_REPO_PACKAGES=()

plat_plan() { return 0; }
plat_setup_repos() { return 0; }
plat_extras() { return 0; }

# systemd: the unit behind display-manager.service.
systemd_display_manager() {
    local link
    link="$(readlink -f /etc/systemd/system/display-manager.service 2> /dev/null || true)"
    [[ -n "${link}" && -e "${link}" ]] && basename -- "${link}" .service
    return 0
}

systemd_set_display_manager() {
    local new="$1" old="${2:-}"
    if [[ -n "${old}" && "${old}" != "${new}" ]]; then
        info "replacing ${old} as the display manager"
        as_root systemctl disable "${old}.service"
    fi
    # --force: replace a display-manager.service alias left by another login manager.
    as_root systemctl enable --force "${new}.service"
}
