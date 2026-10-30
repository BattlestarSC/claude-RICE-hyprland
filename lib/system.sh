# shellcheck shell=bash
# System-wide steps (sudo): login screen, services, login shell, browser policies.
# Sourced by install.sh. Every file replaced under /etc is backed up first (deploy.sh).

system_setup() {
    step "System setup (sudo)"
    local theme="${REPO}/themes/${PALETTE}"

    if (( WANT_GREETER )); then
        info "login screen: greetd + ReGreet"
        deploy_system_file "${REPO}/config/greetd/config.toml" /etc/greetd/config.toml
        deploy_system_file "$(with_cursor "${REPO}/config/greetd/hyprland.lua")" /etc/greetd/hyprland.lua
        deploy_system_file "$(with_cursor "${REPO}/config/greetd/regreet.toml")" /etc/greetd/regreet.toml
        deploy_system_file "${theme}/greetd/regreet.css" /etc/greetd/regreet.css
        deploy_system_file "${theme}/hypr/colors.lua" /etc/greetd/colors.lua
        # The login screen uses the desktop's monitor layout (the greeter cannot read ~/.config).
        local monitors="${XDG_CONFIG_HOME:-${HOME}/.config}/hypr/conf/monitors.lua"
        [[ -f "${monitors}" ]] || monitors="${REPO}/config/hypr/conf/monitors.lua"   # dry run
        deploy_system_file "${monitors}" /etc/greetd/monitors.lua
        if (( DRY_RUN )); then
            note "would render /etc/greetd/background.png from assets/sky/still-3840x2160.svg"
        else
            rsvg-convert -o "${WORK_DIR}/background.png" "${REPO}/assets/sky/still-3840x2160.svg"
            deploy_system_file "${WORK_DIR}/background.png" /etc/greetd/background.png
        fi
        # ReGreet keeps its last user/session and a log; the greeter user must own the dirs.
        as_root install -d -o greeter -g greeter -m 0755 /var/lib/regreet /var/log/regreet
        if [[ -n "${DISPLAY_MANAGER}" && "${DISPLAY_MANAGER}" != greetd ]]; then
            info "replacing ${DISPLAY_MANAGER} as the display manager"
            as_root systemctl disable "${DISPLAY_MANAGER}.service"
        fi
        as_root systemctl enable greetd.service
        # Keyring: unlock gnome-keyring with the login password (greetd authenticates user
        # sessions through the PAM service "greetd").
        if [[ -f /etc/pam.d/greetd ]]; then
            deploy_system_file "$(with_keyring_pam /etc/pam.d/greetd)" /etc/pam.d/greetd
        else
            note "would add pam_gnome_keyring to /etc/pam.d/greetd (installed by the greetd package)"
        fi
    fi

    if (( WANT_SHELL )) && [[ "$(getent passwd "$(id -un)" | cut -d: -f7)" != /usr/bin/zsh ]]; then
        info "login shell: zsh"
        as_root chsh -s /usr/bin/zsh "$(id -un)"
    fi

    # Java: the JDK the Scala toolchain supports (D42) must be the default when others exist.
    if command -v archlinux-java > /dev/null || (( DRY_RUN )); then
        local current
        current="$(archlinux-java get 2> /dev/null || true)"
        if [[ "${current}" != "${JDK_ENV}" ]]; then
            info "default Java: ${JDK_ENV}${current:+ (was ${current})}"
            as_root archlinux-java set "${JDK_ENV}"
        fi
    fi

    info "services"
    as_root systemctl enable bluetooth.service
    if [[ -z "${NET_MANAGER}" ]]; then
        as_root systemctl enable NetworkManager.service
    fi

    info "browser policies"
    deploy_system_file "${REPO}/config/browsers/firefox-policies.json" /etc/firefox/policies/policies.json
    if (( WANT_AUR_BROWSER )); then
        deploy_system_file "${theme}/chromium/policies.json" /etc/chromium/policies/managed/rice.json
    fi
}

# with_keyring_pam FILE: path of a copy of the PAM file FILE that also unlocks gnome-keyring with
# the login password: "auth optional pam_gnome_keyring.so" after the last auth line and
# "session optional pam_gnome_keyring.so auto_start" after the last session line (the module's
# documented placement). A file that already mentions the module is copied unchanged, so
# re-runs compare equal and make no backup.
with_keyring_pam() {
    local out
    out="${WORK_DIR}/pam-greetd.$RANDOM"
    if grep -q 'pam_gnome_keyring\.so' -- "$1"; then
        cp -- "$1" "${out}"
    else
        awk -f "${REPO}/lib/pam-keyring.awk" "$1" "$1" > "${out}"
    fi
    printf '%s' "${out}"
}
