# shellcheck shell=bash
# What goes where. Sourced by install.sh. Sources: config/ (behavior), themes/<palette>/
# (generated colors), home/, bin/, assets/. See docs/knowledge-base/arch-install.md#deploy-map.

deploy_user_files() {
    step "Copying configuration into ${HOME} (changed files are backed up first)"
    local cfg="${XDG_CONFIG_HOME:-${HOME}/.config}" data="${XDG_DATA_HOME:-${HOME}/.local/share}"
    local theme="${REPO}/themes/${PALETTE}"

    # Hyprland, lock, idle, portal. env.lua gets the chosen cursor; monitors.lua keeps panels
    # already captured by rice-monitors; xdph.conf gets the absolute path of the share picker.
    local file rel
    while IFS= read -r -d '' file; do
        rel="${file#"${REPO}/config/hypr/"}"
        case "${rel}" in
            conf/env.lua) deploy_file "$(with_cursor "${file}")" "${cfg}/hypr/${rel}" 0644 ;;
            conf/monitors.lua) deploy_file "$(with_panels "${file}" "${cfg}/hypr/${rel}")" "${cfg}/hypr/${rel}" 0644 ;;
            xdph.conf) deploy_file "$(with_home "${file}")" "${cfg}/hypr/${rel}" 0644 ;;
            *) deploy_file "${file}" "${cfg}/hypr/${rel}" ;;
        esac
    done < <(find "${REPO}/config/hypr" -type f -print0 | sort -z)
    deploy_file "${theme}/hypr/colors.lua" "${cfg}/hypr/theme/colors.lua"
    deploy_file "${theme}/hypr/colors.conf" "${cfg}/hypr/theme/colors.conf"
    deploy_file "${theme}/hypr/hyprtoolkit.conf" "${cfg}/hypr/hyprtoolkit.conf"

    # Quickshell: bar, wallpaper, notifications, screensaver
    deploy_tree "${REPO}/config/quickshell" "${cfg}/quickshell"
    deploy_file "${theme}/quickshell/common/Theme.qml" "${cfg}/quickshell/common/Theme.qml"
    deploy_file "${REPO}/assets/earth/land-1024x512.png" "${cfg}/quickshell/sky/land.png"

    # Launcher and menus
    deploy_file "${REPO}/config/rofi/config.rasi" "${cfg}/rofi/config.rasi"
    local rasi
    for rasi in "${theme}"/rofi/*.rasi; do
        deploy_file "${rasi}" "${cfg}/rofi/$(basename -- "${rasi}")"
    done
    ensure_file "${cfg}/rofi/local.rasi"

    # Terminals and shell
    deploy_tree "${REPO}/config/kitty" "${cfg}/kitty"
    deploy_file "${theme}/kitty/theme.conf" "${cfg}/kitty/theme.conf"
    deploy_tree "${REPO}/config/foot" "${cfg}/foot"
    deploy_file "${theme}/foot/theme.ini" "${cfg}/foot/theme.ini"
    ensure_file "${cfg}/foot/local.ini"
    deploy_tree "${REPO}/config/zsh" "${cfg}/zsh"
    deploy_file "${theme}/zsh/theme.zsh" "${cfg}/zsh/theme.zsh"
    deploy_file "${REPO}/home/.zshenv" "${HOME}/.zshenv"
    deploy_file "${REPO}/home/.zshrc" "${HOME}/.zshrc"
    deploy_file "${theme}/starship/starship.toml" "${cfg}/starship.toml"

    # CLI tools
    deploy_once "${REPO}/config/btop/btop.conf" "${cfg}/btop/btop.conf"
    deploy_file "${theme}/btop/themes/rice.theme" "${cfg}/btop/themes/rice.theme"
    deploy_once "${REPO}/config/htop/htoprc" "${cfg}/htop/htoprc"
    deploy_file "${theme}/fastfetch/config.jsonc" "${cfg}/fastfetch/config.jsonc"

    # Editors
    deploy_tree "${REPO}/config/nvim" "${cfg}/nvim"
    deploy_file "${theme}/nvim/colors/rice.lua" "${cfg}/nvim/colors/rice.lua"
    deploy_tree "${REPO}/config/helix" "${cfg}/helix"
    deploy_file "${theme}/helix/themes/rice.toml" "${cfg}/helix/themes/rice.toml"
    deploy_tree "${REPO}/config/vis" "${cfg}/vis"
    deploy_file "${theme}/vis/themes/rice.lua" "${cfg}/vis/themes/rice.lua"
    deploy_file "${REPO}/config/code-oss/settings.json" "${data}/rice/code-oss/settings.json"
    deploy_file "${REPO}/config/code-oss/settings-defaults.json" "${data}/rice/code-oss/settings-defaults.json"
    deploy_tree "${theme}/code-oss/extension" "${data}/rice/code-oss/extension"

    # Office: LibreOffice theme extension (rice-libreoffice-setup installs it), TeXstudio
    deploy_tree "${theme}/libreoffice/extension" "${data}/rice/libreoffice/extension"
    deploy_once "${theme}/texstudio/texstudio.ini" "${cfg}/texstudio/texstudio.ini"

    # GTK, Qt/KDE, file managers
    deploy_file "${REPO}/config/gtk-3.0/settings.ini" "${cfg}/gtk-3.0/settings.ini"
    deploy_file "${theme}/gtk-3.0/gtk.css" "${cfg}/gtk-3.0/gtk.css"
    deploy_file "${REPO}/config/gtk-4.0/settings.ini" "${cfg}/gtk-4.0/settings.ini"
    deploy_file "${theme}/gtk-4.0/gtk.css" "${cfg}/gtk-4.0/gtk.css"
    deploy_file "${theme}/kde/scheme.colors" "${data}/color-schemes/Quasar.colors"
    deploy_once "${REPO}/config/qt6ct/qt6ct.conf" "${cfg}/qt6ct/qt6ct.conf"
    deploy_file "${theme}/qt6ct/colors/rice.conf" "${cfg}/qt6ct/colors/rice.conf"
    deploy_tree "${REPO}/config/xfce4" "${cfg}/xfce4"
    # XDG applications menu for KDE apps outside Plasma where the system has none (non-Arch)
    deploy_file "${REPO}/config/menus/applications.menu" "${cfg}/menus/applications.menu"

    # Viewers: images (imv), PDF (Zathura; ~/.config/zathura/local is yours)
    deploy_file "${theme}/imv/config" "${cfg}/imv/config"
    deploy_file "${theme}/zathura/zathurarc" "${cfg}/zathura/zathurarc"
    ensure_file "${cfg}/zathura/local"

    # Browsers (rice-browser-setup applies these to every profile)
    deploy_file "${REPO}/config/browsers/user.js" "${data}/rice/browsers/user.js"
    deploy_file "${REPO}/config/browsers/librewolf.overrides.cfg" "${data}/rice/browsers/librewolf.overrides.cfg"
    deploy_file "${theme}/firefox/userChrome.css" "${data}/rice/browsers/chrome/userChrome.css"
    deploy_file "${theme}/firefox/userContent.css" "${data}/rice/browsers/chrome/userContent.css"
    deploy_file "${REPO}/config/chromium-flags.conf" "${cfg}/chromium-flags.conf"
    deploy_file "${REPO}/config/thunderbird/user.js" "${data}/rice/browsers/thunderbird/user.js"
    deploy_file "${theme}/thunderbird/userChrome.css" "${data}/rice/browsers/thunderbird/chrome/userChrome.css"

    # Commands
    local cmd
    for cmd in "${REPO}"/bin/*; do
        deploy_file "${cmd}" "${HOME}/.local/bin/$(basename -- "${cmd}")" 0755
    done

    write_settings_json "${cfg}/rice/settings.json"
    info "${DEPLOYED} written, ${UNCHANGED} already current, ${BACKED_UP} backed up"
}

# After packages are installed: make sure the cursor theme exists, else fall back (the light
# Capitaine variant's directory name on Arch is unverified: docs/knowledge-base/theming.md).
resolve_cursor_theme() {
    (( DRY_RUN )) && return 0
    local candidate dir
    for candidate in "${CURSOR_THEME}" capitaine-cursors-light capitaine-cursors Adwaita; do
        # Same places as XCURSOR_PATH in hypr/conf/env.lua (source-built themes: /usr/local).
        for dir in "${HOME}/.local/share/icons" "${DATA_DIRS[@]/%//icons}"; do
            if [[ -d "${dir}/${candidate}/cursors" ]]; then
                [[ "${candidate}" != "${CURSOR_THEME}" ]] && warn "cursor theme ${CURSOR_THEME} not found; using ${candidate}"
                CURSOR_THEME="${candidate}"
                return 0
            fi
        done
    done
    warn "no cursor theme found; keeping ${CURSOR_THEME}"
}

# with_cursor FILE: path of a copy of FILE with the chosen cursor theme instead of the default.
with_cursor() {
    local out
    out="${WORK_DIR}/$(basename -- "$1").$RANDOM"
    # -e before --: BSD sed reads a positional script and then takes "--" for a file name.
    sed -e "s/capitaine-cursors-light/${CURSOR_THEME}/g" -- "$1" > "${out}"
    printf '%s' "${out}"
}

# with_home FILE: path of a copy of FILE with "= ~/" written as "= $HOME/" (for configs that
# need absolute paths and cannot expand "~" or environment variables themselves).
with_home() {
    local out
    out="${WORK_DIR}/$(basename -- "$1").$RANDOM"
    HOME_DIR="${HOME}" awk '{ i = index($0, "= ~/"); if (i) $0 = substr($0, 1, i + 1) ENVIRON["HOME_DIR"] substr($0, i + 3) } { print }' "$1" > "${out}"
    printf '%s' "${out}"
}

# with_panels NEW OLD: path of a copy of NEW keeping the DESC_LEFT/DESC_RIGHT lines from OLD
# when OLD already has real panel descriptions (captured by rice-monitors).
with_panels() {
    local new="$1" old="$2" out
    out="${WORK_DIR}/monitors.lua.$RANDOM"
    if [[ -f "${old}" ]] && grep -q '^local DESC_LEFT' "${old}" && ! grep -q 'REPLACE-WITH-' "${old}"; then
        awk 'NR == FNR { if ($1 == "local" && ($2 == "DESC_LEFT" || $2 == "DESC_RIGHT")) keep[$2] = $0; next }
             $1 == "local" && ($2 in keep) { print keep[$2]; next }
             { print }' "${old}" "${new}" > "${out}"
    else
        cp -- "${new}" "${out}"
    fi
    printf '%s' "${out}"
}

# Wallpaper answers. Written only if the file does not exist (it is the user's from then on).
write_settings_json() {
    local file="$1"
    [[ -e "${file}" ]] && { note "kept ${file}"; return 0; }
    if (( DRY_RUN )); then
        note "would write ${file}: skyMode=${SKY_MODE} skyLayout=${SKY_LAYOUT}"
        return 0
    fi
    mkdir -p -- "$(dirname -- "${file}")"
    jq -n --arg mode "${SKY_MODE}" --arg layout "${SKY_LAYOUT}" --arg image "${SKY_IMAGE}" \
        '{skyMode: $mode, skyLayout: $layout, skyImage: $image}' > "${file}"
}

# Generated binaries the shell needs: compiled shaders, glyph atlases, the still sky as PNG.
build_assets() {
    step "Building shaders and images"
    local cfg="${XDG_CONFIG_HOME:-${HOME}/.config}" data="${XDG_DATA_HOME:-${HOME}/.local/share}"
    local theme="${REPO}/themes/${PALETTE}" qsb name scale w h
    # qsb is a Qt tool outside PATH on most systems (Arch/Debian, Fedora, FreeBSD layouts).
    qsb="$(command -v qsb qsb-qt6 qsb6 2> /dev/null | head -n 1 || true)"
    local c
    for c in /usr/lib/qt6/bin/qsb /usr/lib/qt6/libexec/qsb /usr/lib/x86_64-linux-gnu/qt6/bin/qsb \
        /usr/lib64/qt6/bin/qsb /usr/local/lib/qt6/bin/qsb /usr/local/libexec/qt6/qsb; do
        [[ -n "${qsb}" ]] && break
        [[ -x "${c}" ]] && qsb="${c}"
    done
    [[ -n "${qsb}" ]] || qsb=/usr/lib/qt6/bin/qsb
    if [[ -x "${qsb}" ]] || (( DRY_RUN )); then
        run mkdir -p -- "${cfg}/quickshell/sky/shaders"
        for name in scene glyph; do
            # Same targets as tests/sky/render.py: GLSL ES 1.0 / 1.20 / 1.50, HLSL 5.0, MSL 1.2.
            run "${qsb}" --glsl "100es,120,150" --hlsl 50 --msl 12 \
                -o "${cfg}/quickshell/sky/shaders/${name}.frag.qsb" "${theme}/quickshell/sky/${name}.frag"
        done
    else
        warn "qsb not found (package qt6-shadertools); the animated wallpaper will not draw"
    fi
    # One glyph atlas per common scale (8x16 logical cells); Wallpaper.qml picks by the screen's.
    run mkdir -p -- "${data}/rice/quickshell"
    for scale in 1 1.25 1.5 2; do
        w=$(awk -v s="${scale}" 'BEGIN { printf "%d", 8 * s + 0.5 }')
        h=$(awk -v s="${scale}" 'BEGIN { printf "%d", 16 * s + 0.5 }')
        run "${REPO}/bin/rice-sky-atlas" "${w}" "${h}" "${data}/rice/quickshell/sky-atlas-${w}x${h}.png"
    done
    run rsvg-convert -o "${data}/rice/lock.png" "${REPO}/assets/sky/still-3840x2160.svg"
}
