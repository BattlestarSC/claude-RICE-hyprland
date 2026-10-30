#!/usr/bin/env bash
# install.sh: set up the rice on a vanilla Arch Linux install. Clone the repository and run this,
# as your normal user, from a TTY or any terminal:
#
#   git clone <repo> && cd <repo> && ./install.sh
#
#   ./install.sh             ask a few questions, show the plan, then install everything
#   ./install.sh --yes       take every default without asking (unattended)
#   ./install.sh --dry-run   show what would happen; changes nothing (no sudo)
#
# What it does, in order: checks the system; installs all packages in one `pacman -Syu`;
# optionally builds AUR extras; copies the configuration into your home (every file it would
# replace is backed up to ~/.local/state/rice/backups/<time>/ first); builds shaders and images;
# sets desktop defaults (GTK, file manager, browser, editor); sets up the login screen (greetd),
# services and your login shell (sudo). Safe to re-run: files already current are left alone.
# Rules it follows: docs/knowledge-base/arch-install.md#installer-rules-derived-constraints.
set -Eeuo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PALETTE=quasar
CURSOR_THEME="${RICE_CURSOR:-capitaine-cursors-light}"
WORK_DIR="$(mktemp -d)"
trap 'stop_sudo_keepalive; rm -rf -- "${WORK_DIR}"' EXIT
# set -E carries this into functions: any unexpected failure names its file and line.
trap 'die "unexpected failure at ${BASH_SOURCE[0]#"${REPO}/"}:${LINENO}: ${BASH_COMMAND}"' ERR

# shellcheck source=lib/log.sh
source "${REPO}/lib/log.sh"
# shellcheck source=lib/preflight.sh
source "${REPO}/lib/preflight.sh"
# shellcheck source=lib/packages.sh
source "${REPO}/lib/packages.sh"
# shellcheck source=lib/deploy.sh
source "${REPO}/lib/deploy.sh"
# shellcheck source=lib/files.sh
source "${REPO}/lib/files.sh"
# shellcheck source=lib/desktop.sh
source "${REPO}/lib/desktop.sh"
# shellcheck source=lib/system.sh
source "${REPO}/lib/system.sh"

# Java for Scala (D42): the newest JDK that Scala 3 LTS, sbt, scala-cli and Metals all support
# (docs.scala-lang.org/overviews/jdk-compatibility, 2026-10-27). packages/languages.txt installs it.
JDK_VERSION=25
JDK_ENV="java-${JDK_VERSION}-openjdk"
WANT_OFFICE=1
WANT_BLENDER=0
WANT_AUR_BROWSER=0
WANT_GREETER=1
WANT_SHELL=1
SKY_MODE=animated
SKY_LAYOUT=mirror
SKY_IMAGE=""

usage() { sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; }

parse_args() {
    while (( $# )); do
        case "$1" in
            -y | --yes) ASSUME_YES=1 ;;
            -n | --dry-run) DRY_RUN=1 ;;
            -h | --help) usage; exit 0 ;;
            *) usage >&2; die "unknown option: $1" ;;
        esac
        shift
    done
}

ask_plan() {
    step "Choices (Enter takes the default)"
    ask_yn "Office: full TeX Live, TeXstudio, LibreOffice (about 7 GB)?" y || WANT_OFFICE=0
    if (( HAS_AMD )); then
        ask_yn "Blender with HIP (GPU) rendering?" y && WANT_BLENDER=1
    fi
    ask_yn "ungoogled-chromium as a backup browser (AUR, built with makepkg)?" n && WANT_AUR_BROWSER=1
    ask_choice SKY_MODE "Wallpaper" animated animated still image
    if [[ "${SKY_MODE}" == image ]]; then
        if (( ASSUME_YES )) || [[ ! -t 0 ]]; then
            SKY_MODE=animated
        else
            read -r -p "    Path to your image: " SKY_IMAGE
            [[ -r "${SKY_IMAGE}" ]] || { warn "cannot read ${SKY_IMAGE}; using the animated sky"; SKY_MODE=animated; SKY_IMAGE=""; }
        fi
    fi
    ask_choice SKY_LAYOUT "Two monitors" mirror mirror span
    ask_yn "Use the graphical login screen (greetd + ReGreet) as the display manager?" y || WANT_GREETER=0
    ask_yn "Make zsh your login shell?" y || WANT_SHELL=0

    # Programming languages are always installed (owner, D42).
    PKG_LISTS=(desktop.txt shell.txt apps.txt editors.txt languages.txt)
    (( WANT_OFFICE )) && PKG_LISTS+=(office.txt)
    [[ -z "${NET_MANAGER}" ]] && PKG_LISTS+=(network.txt)
    (( HAS_AMD )) && PKG_LISTS+=(amd-gpu.txt)
    (( WANT_BLENDER )) && PKG_LISTS+=(blender.txt)
    return 0
}

show_plan() {
    step "Plan"
    info "packages: ${#PKG_REQUIRED[@]} from ${PKG_LISTS[*]} (one pacman -Syu, which also updates the system)"
    info "languages: Elixir/Erlang, Haskell, SWI-Prolog, Fortran, Scala (JDK ${JDK_VERSION}), OCaml + their language servers"
    (( WANT_AUR_BROWSER )) && info "AUR: ungoogled-chromium-bin"
    info "your files: copied into ~/.config, ~/.local; replaced files backed up to ${BACKUP_DIR}"
    info "wallpaper: ${SKY_MODE}, ${SKY_LAYOUT}; cursor: ${CURSOR_THEME}"
    info "system (sudo):"
    (( WANT_GREETER )) && info "  - login screen: /etc/greetd/*, enable greetd${DISPLAY_MANAGER:+ (disable ${DISPLAY_MANAGER})}"
    (( WANT_GREETER )) && info "  - keyring unlocked at login: pam_gnome_keyring in /etc/pam.d/greetd"
    (( WANT_SHELL )) && info "  - login shell: zsh"
    info "  - enable bluetooth$([[ -z "${NET_MANAGER}" ]] && printf ' and NetworkManager')"
    info "  - Firefox privacy policies: /etc/firefox/policies/policies.json"
    info "  - default Java: ${JDK_ENV} (archlinux-java), if another JDK is the default"
    (( DRY_RUN )) && { info "dry run: nothing below is executed"; return 0; }
    ask_yn "Go ahead?" y || die "stopped; nothing was changed"
}

finish() {
    finish_backups
    step "Done"
    if (( BACKED_UP )); then
        info "${BACKED_UP} replaced file(s) backed up: ${BACKUP_DIR}/manifest.tsv"
    fi
    [[ -n "${RICE_LOG}" ]] && info "log: ${RICE_LOG}"
    info "Reboot to start at the new login screen (or run start-hyprland from a TTY)."
    info "After the first login the two panels are recorded automatically; if left and right are"
    info "swapped: Super+Shift+M > swap. Keys: Super+F1 shows every binding."
}

main() {
    parse_args "$@"
    preflight
    ask_plan
    check_space
    resolve_packages
    show_plan
    start_log
    start_backups
    install_packages
    (( WANT_AUR_BROWSER )) && install_aur ungoogled-chromium-bin
    check_hyprland_version
    resolve_cursor_theme
    deploy_user_files
    build_assets
    desktop_defaults
    system_setup
    finish
}

main "$@"
