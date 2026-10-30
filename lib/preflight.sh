# shellcheck shell=bash
# Checks before anything changes, and facts the later steps need. Sourced by install.sh.

HAS_AMD=0
HAS_NVIDIA=0
NET_MANAGER=""        # the active network manager, empty if none
DISPLAY_MANAGER=""    # unit behind display-manager.service, empty if none

detect_gpus() {
    local dev class vendor
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
    local link
    link="$(readlink -f /etc/systemd/system/display-manager.service 2> /dev/null || true)"
    if [[ -n "${link}" && -e "${link}" ]]; then
        DISPLAY_MANAGER="$(basename -- "${link}" .service)"
    fi
}

# Free space on / against the chosen package lists (rough sizes of what pacman downloads + unpacks).
check_space() {
    local need=16 free_gb
    (( WANT_OFFICE )) && need=$((need + 8))
    free_gb=$(( $(df --output=avail -k / | tail -n 1) / 1024 / 1024 ))
    if (( free_gb < need )); then
        warn "only ${free_gb} GB free on /; this selection needs about ${need} GB"
    fi
    return 0
}

preflight() {
    step "Checking the system"
    (( EUID != 0 )) || die "run ./install.sh as your normal user, not root (it uses sudo where needed)"
    [[ -f /etc/arch-release ]] || die "this installer is for Arch Linux (/etc/arch-release not found)"
    local cmd
    for cmd in pacman sudo git systemctl; do
        command -v "${cmd}" > /dev/null || die "${cmd} not found"
    done
    [[ -f "${REPO}/config/hypr/hyprland.lua" ]] || die "run install.sh from a complete checkout"
    if [[ -e /var/lib/pacman/db.lck ]]; then
        die "pacman is busy or crashed (/var/lib/pacman/db.lck exists); finish or remove it, then re-run"
    fi
    [[ -f /var/lib/pacman/sync/extra.db ]] || die "no pacman sync database; run: sudo pacman -Syu"
    getent hosts archlinux.org > /dev/null || die "no network (cannot resolve archlinux.org)"
    if (( ! DRY_RUN )); then
        info "sudo is used for pacman and the system steps; it may ask for your password now"
        sudo -v || die "sudo does not work for $(id -un); see the README (Requirements)"
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
