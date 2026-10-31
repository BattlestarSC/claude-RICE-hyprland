# shellcheck shell=bash
# System-wide steps (sudo): login screen, services, login shell, browser policies.
# Sourced by install.sh. Every file replaced under /etc is backed up first (deploy.sh).

system_setup() {
    step "System setup (sudo)"
    local theme="${REPO}/themes/${PALETTE}" g="${GREETD_DIR}"

    if (( WANT_GREETER )) && [[ "${PLAT_GREETER}" == tty ]]; then
        # No greetd on this system: log in on the first console and the session starts there
        # (config/zsh/session.zsh reads this file; deleting it turns the autostart off).
        info "session: Hyprland after a console login on ${PLAT_FIRST_TTY#/dev/}"
        printf '%s\n' "${PLAT_FIRST_TTY}" > "${WORK_DIR}/tty-autostart"
        deploy_file "${WORK_DIR}/tty-autostart" "${XDG_CONFIG_HOME:-${HOME}/.config}/rice/tty-autostart"
        plat_set_display_manager "" "${DISPLAY_MANAGER}"
    elif (( WANT_GREETER )) && [[ "${PLAT_GREETER}" == lightdm ]]; then
        setup_lightdm
    elif (( WANT_GREETER )); then
        info "login screen: greetd + ReGreet"
        deploy_system_file "$(with_system_paths "${REPO}/config/greetd/config.toml")" "${g}/config.toml"
        deploy_system_file "$(with_system_paths "$(with_cursor "${REPO}/config/greetd/hyprland.lua")")" "${g}/hyprland.lua"
        deploy_system_file "$(with_system_paths "$(with_cursor "${REPO}/config/greetd/regreet.toml")")" "${g}/regreet.toml"
        deploy_system_file "${theme}/greetd/regreet.css" "${g}/regreet.css"
        deploy_system_file "${theme}/hypr/colors.lua" "${g}/colors.lua"
        if [[ "${PLAT_INIT}" != systemd ]]; then
            # No systemd user manager, so no session bus unless the session starts one.
            deploy_system_file "${REPO}/config/greetd/sessions/wayland-sessions/hyprland.desktop" \
                "${g}/sessions/wayland-sessions/hyprland.desktop"
        fi
        # The login screen uses the desktop's monitor layout (the greeter cannot read ~/.config).
        local monitors="${XDG_CONFIG_HOME:-${HOME}/.config}/hypr/conf/monitors.lua"
        [[ -f "${monitors}" ]] || monitors="${REPO}/config/hypr/conf/monitors.lua"   # dry run
        deploy_system_file "${monitors}" "${g}/monitors.lua"
        if (( DRY_RUN )); then
            note "would render ${g}/background.png from assets/sky/still-3840x2160.svg"
        else
            rsvg-convert -o "${WORK_DIR}/background.png" "${REPO}/assets/sky/still-3840x2160.svg"
            deploy_system_file "${WORK_DIR}/background.png" "${g}/background.png"
        fi
        # ReGreet keeps its last user/session and a log; the greeter user must own the dirs.
        as_root install -d -o "${GREETER_USER}" -g "${GREETER_USER}" -m 0755 /var/lib/regreet /var/log/regreet
        plat_set_display_manager greetd "${DISPLAY_MANAGER}"
        # Keyring: unlock gnome-keyring with the login password (greetd authenticates user
        # sessions through the PAM service "greetd").
        if [[ -f "${PAM_DIR}/greetd" ]]; then
            deploy_system_file "$(with_keyring_pam "${PAM_DIR}/greetd")" "${PAM_DIR}/greetd"
        else
            note "would add pam_gnome_keyring to ${PAM_DIR}/greetd (installed by the greetd package)"
        fi
    fi

    if (( WANT_SHELL )) && [[ "$(getent passwd "$(id -un)" | cut -d: -f7)" != "${ZSH_BIN}" ]]; then
        info "login shell: zsh"
        as_root chsh -s "${ZSH_BIN}" "$(id -un)"
    fi

    plat_set_java

    info "services"
    plat_service_enable bluetooth
    if [[ -z "${NET_MANAGER}" && -f "${PKG_DIR}/network.txt" ]]; then
        plat_service_enable NetworkManager
    fi

    info "browser policies"
    deploy_system_file "${REPO}/config/browsers/firefox-policies.json" "${FIREFOX_POLICY_DIR}/policies.json"
    if (( WANT_AUR_BROWSER )); then
        deploy_system_file "${theme}/chromium/policies.json" /etc/chromium/policies/managed/rice.json
    fi
}

# The i3 desktop's login: LightDM with its GTK greeter. Drop-in files only (lightdm.conf.d,
# lightdm-gtk-greeter.conf.d: read before the package's own files, so those still win); the
# greeter's look is a GTK theme of its own; the session entry runs rice-session i3.
setup_lightdm() {
    local theme="${REPO}/themes/${PALETTE}" l="${LIGHTDM_ETC}"
    info "login screen: LightDM + GTK greeter, session Rice (i3)"
    deploy_system_file "${REPO}/config/lightdm/lightdm.conf" "${l}/lightdm.conf.d/50-rice.conf"
    deploy_system_file "$(with_cursor "${REPO}/config/lightdm/lightdm-gtk-greeter.conf")" \
        "${l}/lightdm-gtk-greeter.conf.d/50-rice.conf"
    deploy_system_file "${theme}/lightdm/gtk.css" "${DATA_DIRS[0]}/themes/Quasar-greeter/gtk-3.0/gtk.css"
    deploy_system_file "${REPO}/config/lightdm/rice-i3.desktop" "${XSESSIONS_DIR}/rice-i3.desktop"
    deploy_system_file "${REPO}/config/lightdm/rice-i3-session" "${RICE_LIBEXEC}/rice-i3-session" 0755
    # The greeter runs as user lightdm: its background is copied out of ~ (like greetd's).
    if (( DRY_RUN )); then
        note "would render ${l}/rice/background.png from assets/sky/still-3840x2160.svg"
    else
        rsvg-convert -o "${WORK_DIR}/background.png" "${REPO}/assets/sky/still-3840x2160.svg"
        deploy_system_file "${WORK_DIR}/background.png" "${l}/rice/background.png"
    fi
    plat_set_display_manager lightdm "${DISPLAY_MANAGER}"
    # Keyring: the PAM service of user sessions is "lightdm" (pkg installs it from .sample).
    if [[ -f "${PAM_DIR}/lightdm" ]]; then
        deploy_system_file "$(with_keyring_pam "${PAM_DIR}/lightdm")" "${PAM_DIR}/lightdm"
    else
        note "would add pam_gnome_keyring to ${PAM_DIR}/lightdm (installed by the lightdm package)"
    fi
}

# with_system_paths FILE: path of a copy of FILE with this system's greetd directory, greeter
# user, power command and VT in place of the repository's defaults (/etc/greetd, "greeter",
# systemctl, 1).
with_system_paths() {
    local out
    out="${WORK_DIR}/$(basename -- "$1").sys.$RANDOM"
    GREETD="${GREETD_DIR}" GUSER="${GREETER_USER}" PCTL="${POWER_CTL}" GVT="${GREETD_VT}" awk '
        { gsub("/etc/greetd/", ENVIRON["GREETD"] "/") }
        /^user = "greeter"$/ { $0 = "user = \"" ENVIRON["GUSER"] "\"" }
        /^vt = 1$/ { $0 = "vt = " ENVIRON["GVT"] }
        /^(reboot|poweroff) = \["systemctl", / { sub(/"systemctl"/, "\"" ENVIRON["PCTL"] "\"") }
        { print }' "$1" > "${out}"
    printf '%s' "${out}"
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
        awk -v module="${PAM_KEYRING_MODULE:-pam_gnome_keyring.so}" -f "${REPO}/lib/pam-keyring.awk" "$1" "$1" > "${out}"
    fi
    printf '%s' "${out}"
}
