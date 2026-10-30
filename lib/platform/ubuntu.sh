# shellcheck shell=bash
# Ubuntu 26.04 LTS: apt; Mozilla team and LibreOffice PPAs, LibreWolf and VSCodium through
# extrepo; the Hyprland 0.57 stack, Quickshell and ReGreet built from source (lib/extras.sh),
# because Ubuntu ships Hyprland 0.53. Interface: lib/platform.sh. Facts: docs/knowledge-base/platforms.md#ubuntu.

# shellcheck disable=SC2034  # used by install.sh and lib/
declare -g PLAT_NAME="Ubuntu 26.04 LTS" PKG_DIR="${REPO}/packages/ubuntu" GREETER_USER=_greetd
# Names that exist only once plat_setup_repos has added their repositories.
# shellcheck disable=SC2034
declare -ga PLAT_REPO_PACKAGES=(librewolf codium)
# Build dependencies of the source builds, installed with everything else.
# shellcheck disable=SC2034
declare -ga PLAT_EXTRA_LISTS=(build.txt)

ubuntu_apt() {
    as_root env DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 "$@"
}

plat_preflight() {
    local version
    version="$(sed -n 's/^VERSION_ID=//p' /etc/os-release | tr -d '"')"
    [[ "${version}" == 26.04 ]] || die "this installer supports Ubuntu 26.04 LTS (this is ${version})"
    command -v apt-get > /dev/null || die "apt-get not found"
    [[ "$(dpkg --print-architecture)" == amd64 ]] || die "only amd64 is supported (upstream release files)"
    getent hosts archive.ubuntu.com > /dev/null || die "no network (cannot resolve archive.ubuntu.com)"
}

# Names with an install candidate (one apt-cache call), plus the repository-provided ones.
plat_available() {
    apt-cache policy "$@" 2> /dev/null | awk '
        /^[^ ].*:$/ { name = substr($0, 1, length($0) - 1) }
        /Candidate:/ && $2 != "(none)" { print name }'
    printf '%s\n' "${PLAT_REPO_PACKAGES[@]}"
}

plat_plan() {
    info "repositories: universe; PPAs mozillateam (Firefox, Thunderbird as .deb instead of snap),"
    info "  libreoffice (LibreOffice 26.8); LibreWolf and VSCodium through extrepo"
    info "built from source into /usr/local (Ubuntu has Hyprland 0.53, no Quickshell or ReGreet):"
    info "  Hyprland 0.57 and its libraries, hyprlock, hypridle, xdg-desktop-portal-hyprland, Quickshell,"
    info "  ReGreet, wayland-protocols 1.49; upstream releases: Neovim 0.12, tree-sitter CLI, fonts, themes"
    info "  (about 30-60 minutes of compiling the first time)"
}

plat_setup_repos() {
    step "Adding repositories"
    ubuntu_apt update -q
    ubuntu_apt install -y -q software-properties-common extrepo ca-certificates curl gnupg
    as_root add-apt-repository -y -n universe
    as_root add-apt-repository -y -n ppa:mozillateam/ppa
    as_root add-apt-repository -y -n ppa:libreoffice/ppa
    # Ubuntu's firefox and thunderbird packages only install the snaps; the PPA's .debs must win,
    # and the snap shims must never come back (Mozilla team PPA instructions).
    printf '%s\n' \
        'Package: firefox* thunderbird*' 'Pin: release o=LP-PPA-mozillateam' 'Pin-Priority: 1001' '' \
        'Package: firefox* thunderbird*' 'Pin: release o=Ubuntu' 'Pin-Priority: -1' \
        > "${WORK_DIR}/mozillateam.pref"
    deploy_system_file "${WORK_DIR}/mozillateam.pref" /etc/apt/preferences.d/rice-mozillateam
    as_root extrepo enable librewolf
    as_root extrepo enable vscodium
    ubuntu_apt update -q
}

plat_install() {
    ubuntu_apt update -q
    ubuntu_apt install -y -q "$@"
}

plat_extras() {
    step "Building what Ubuntu does not package (first run: 30-60 minutes)"
    extras_env
    # Hyprland 0.57 needs wayland-protocols >= 1.49; Ubuntu 26.04 has 1.47, and its
    # wayland-scanner 1.24 rejects the newer protocol XML (found by the Ubuntu full-install CI).
    extras_build "${WAYLAND_SCANNER_PIN}"
    extras_build "${WAYLAND_PROTOCOLS_PIN}"
    extras_hypr_stack
    extras_build "${QUICKSHELL_PIN}"
    extras_build "${REGREET_PIN}"
    extras_build "${ZSH_HSS_PIN}"
    extras_build "${CAPITAINE_PIN}"
    extras_neovim
    extras_tree_sitter
    extras_nerd_symbols
    extras_adw_gtk3
}

plat_installed() { [[ "$(dpkg-query -W -f='${Status}' -- "$1" 2> /dev/null)" == "install ok installed" ]]; }

plat_service_enable() { as_root systemctl enable "$1.service"; }
plat_display_manager() { systemd_display_manager; }
plat_set_display_manager() { systemd_set_display_manager "$@"; }

plat_set_java() {
    local jvm=/usr/lib/jvm/java-${JDK_VERSION}-openjdk-amd64 tool
    [[ -d "${jvm}" ]] || (( DRY_RUN )) || return 0
    for tool in java javac; do
        if [[ "$(update-alternatives --query "${tool}" 2> /dev/null | sed -n 's/^Value: //p')" != "${jvm}/bin/${tool}" ]]; then
            info "default ${tool}: JDK ${JDK_VERSION}"
            as_root update-alternatives --set "${tool}" "${jvm}/bin/${tool}"
        fi
    done
}
