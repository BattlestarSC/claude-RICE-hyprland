# shellcheck shell=bash
# Fedora (latest stable, x86_64): dnf; LibreWolf and VSCodium from their own RPM repositories,
# Amberol from Flathub (its upstream channel); the Hyprland 0.57 stack, Quickshell 0.3, ReGreet,
# starship and texlab built from source (lib/extras.sh), because Fedora packages none of them
# (Quickshell: 0.2). Interface: lib/platform.sh. Facts: docs/knowledge-base/platforms.md#fedora.

declare -g PLAT_NAME
# shellcheck disable=SC2034  # used by install.sh
PLAT_NAME="Fedora $(os_release VERSION_ID)"
# shellcheck disable=SC2034  # used by install.sh and lib/
declare -g PKG_DIR="${REPO}/packages/fedora" GREETER_USER=greetd
# shellcheck disable=SC2034
declare -ga PLAT_REPO_PACKAGES=(librewolf codium) PLAT_EXTRA_LISTS=(build.txt)
# Flatpak's exported desktop files (Amberol) are found by the default-app step.
# shellcheck disable=SC2034
declare -ga DATA_DIRS=(/usr/local/share /usr/share /var/lib/flatpak/exports/share)

fedora_dnf() { as_root dnf -y -q "$@"; }

plat_preflight() {
    local version
    version="$(os_release VERSION_ID)"
    if [[ ! "${version}" =~ ^[0-9]+$ ]] || (( version < 44 )); then
        die "this installer supports Fedora 44 or newer (this is ${version})"
    fi
    command -v dnf > /dev/null || die "dnf not found"
    [[ "$(uname -m)" == x86_64 ]] || die "only x86_64 is supported (upstream release files)"
    getent hosts fedoraproject.org > /dev/null || die "no network (cannot resolve fedoraproject.org)"
}

plat_available() {
    dnf -q repoquery --available --qf '%{name}\n' "$@" 2> /dev/null | sort -u
    printf '%s\n' "${PLAT_REPO_PACKAGES[@]}"
}

plat_plan() {
    info "repositories: LibreWolf and VSCodium RPM repositories (/etc/yum.repos.d), Flathub for Amberol"
    info "built from source into /usr/local (Fedora has no Hyprland, ReGreet or starship):"
    info "  Hyprland 0.57 and its libraries, hyprlock, hypridle, xdg-desktop-portal-hyprland, Quickshell,"
    info "  ReGreet, starship, texlab, wayland-protocols 1.50; upstream releases: tree-sitter CLI, Symbols Nerd Font"
    info "  (about 30-60 minutes of compiling the first time)"
}

plat_setup_repos() {
    step "Adding repositories"
    deploy_system_file "${REPO}/config/fedora/librewolf.repo" /etc/yum.repos.d/librewolf.repo
    deploy_system_file "${REPO}/config/fedora/vscodium.repo" /etc/yum.repos.d/vscodium.repo
}

plat_install() {
    local opts=(install --setopt=install_weak_deps=False)
    (( ASSUME_YES )) && opts+=(-y)
    as_root dnf "${opts[@]}" "$@"
}

plat_extras() {
    step "Building what Fedora does not package (first run: 30-60 minutes)"
    extras_env
    # Fedora 44 has wayland-protocols 1.47 and wayland-scanner 1.24, like Ubuntu 26.04.
    extras_build "${WAYLAND_SCANNER_PIN}"
    extras_build "${WAYLAND_PROTOCOLS_PIN}"
    extras_hypr_stack
    extras_build "${QUICKSHELL_PIN}"
    extras_build "${REGREET_PIN}"
    extras_build "${STARSHIP_PIN}"
    if (( WANT_OFFICE )); then
        extras_build "${TEXLAB_PIN}"
    fi
    extras_build "${ZSH_HSS_PIN}"
    extras_build "${CAPITAINE_PIN}"
    extras_tree_sitter
    extras_nerd_symbols
    fedora_amberol
}

# Amberol from Flathub (system-wide), allowed to read the generated GTK 4 CSS like a native app.
fedora_amberol() {
    info "Amberol (Flathub)"
    as_root flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    as_root flatpak install -y --noninteractive flathub io.bassi.Amberol
    run flatpak override --user --filesystem=xdg-config/gtk-4.0:ro io.bassi.Amberol
}

plat_installed() { rpm -q "$1" > /dev/null 2>&1; }

plat_service_enable() { as_root systemctl enable "$1.service"; }
plat_display_manager() { systemd_display_manager; }
plat_set_display_manager() { systemd_set_display_manager "$@"; }

plat_set_java() {
    local jvm=/usr/lib/jvm/java-${JDK_VERSION}-openjdk tool
    [[ -d "${jvm}" ]] || (( DRY_RUN )) || return 0
    for tool in java javac; do
        if [[ "$(readlink -f "/etc/alternatives/${tool}" 2> /dev/null || true)" != "$(readlink -f "${jvm}/bin/${tool}" 2> /dev/null || echo "${jvm}/bin/${tool}")" ]]; then
            info "default ${tool}: JDK ${JDK_VERSION}"
            as_root alternatives --set "${tool}" "${jvm}/bin/${tool}"
        fi
    done
}
