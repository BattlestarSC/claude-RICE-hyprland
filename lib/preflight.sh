# shellcheck shell=bash
# Checks before anything changes, and facts the later steps need. Sourced by install.sh.

HAS_AMD=0
HAS_NVIDIA=0
NET_MANAGER=""        # the active network manager, empty if none
DISPLAY_MANAGER=""    # unit behind display-manager.service, empty if none

detect_gpus() {
    local dev class vendor
    if [[ "${PLAT_ID}" == freebsd ]]; then
        pciconf -l 2> /dev/null | grep -q 'class=0x03.*vendor=0x1002' && HAS_AMD=1
        pciconf -l 2> /dev/null | grep -q 'class=0x03.*vendor=0x10de' && HAS_NVIDIA=1
        return 0
    fi
    for dev in /sys/bus/pci/devices/*; do
        [[ -r "${dev}/class" && -r "${dev}/vendor" ]] || continue
        class="$(< "${dev}/class")"
        vendor="$(< "${dev}/vendor")"
        [[ "${class}" == 0x03* ]] || continue
        case "${vendor}" in
            0x1002) HAS_AMD=1 ;;
            0x10de) HAS_NVIDIA=1 ;;
        esac
    done
}

detect_network_manager() {
    [[ "${PLAT_INIT}" == systemd ]] || return 0
    local unit
    for unit in NetworkManager iwd systemd-networkd connman dhcpcd netctl; do
        if systemctl is-active --quiet "${unit}.service" 2> /dev/null; then
            NET_MANAGER="${unit}"
            return 0
        fi
    done
    return 0
}

detect_display_manager() {
    DISPLAY_MANAGER="$(plat_display_manager)"
}

# Free space on / against the chosen package lists. Measured by the full-install CI (2026-10-30):
# 15 GB under /usr without docs and man pages (the container skips them; TeX Live's docs are
# several GB), 6.9 GB of downloaded packages in pacman's cache, 0.9 GB in the home directory.
check_space() {
    local need=18 free_gb
    (( WANT_OFFICE )) && need=$((need + 12))
    free_gb=$(( $(df --output=avail -k / | tail -n 1) / 1024 / 1024 ))
    if (( free_gb < need )); then
        warn "only ${free_gb} GB free on /; this selection needs about ${need} GB"
    fi
    return 0
}

preflight() {
    step "Checking the system"
    (( EUID != 0 )) || die "run ./install.sh as your normal user, not root (it uses sudo where needed)"
    info "system: ${PLAT_NAME} (${PLAT_INIT})"
    local cmd
    for cmd in sudo git; do
        command -v "${cmd}" > /dev/null || die "${cmd} not found"
    done
    [[ -f "${REPO}/config/hypr/hyprland.lua" ]] || die "run install.sh from a complete checkout"
    plat_preflight
    if (( ! DRY_RUN )); then
        info "sudo is used for packages and the system steps; it may ask for your password now"
        # Run a command rather than `sudo -v`: Ubuntu 26.04's sudo-rs refuses -v without a
        # terminal even under NOPASSWD (found by the Ubuntu full-install CI).
        sudo true || die "sudo does not work for $(id -un); see the README (Requirements)"
        keep_sudo_alive
    fi

    detect_gpus
    detect_network_manager
    detect_display_manager
    local gpus=()
    (( HAS_AMD )) && gpus+=(AMD)
    (( HAS_NVIDIA )) && gpus+=(NVIDIA)
    info "GPU: ${gpus[*]:-other}"
    (( HAS_NVIDIA )) && warn "NVIDIA GPU found: Hyprland needs extra driver setup that this installer does not do (hyprland-wiki: NVIDIA)"
    info "network: ${NET_MANAGER:-none active}"
    info "display manager: ${DISPLAY_MANAGER:-none}"
    local virt
    virt="$(systemd-detect-virt 2> /dev/null || true)"
    [[ -n "${virt}" && "${virt}" != none ]] && warn "virtual machine (${virt}): Hyprland needs 3D acceleration (virgl or GPU passthrough)"
    return 0
}
