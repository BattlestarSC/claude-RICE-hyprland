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
    fi

    if (( WANT_SHELL )) && [[ "$(getent passwd "$(id -un)" | cut -d: -f7)" != /usr/bin/zsh ]]; then
        info "login shell: zsh"
        as_root chsh -s /usr/bin/zsh "$(id -un)"
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
