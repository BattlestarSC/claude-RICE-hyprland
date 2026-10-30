# shellcheck shell=bash
# Package lists (packages/*.txt) and installation. Sourced by install.sh.
# The package manager itself is the platform module's (lib/platform/<id>.sh).

PKG_LISTS=()      # list files chosen in the plan, relative to packages/
PKG_REQUIRED=()   # names to install
PKG_SKIPPED=()    # optional names (?name) the repositories do not have

# Print the names in a list, one per line; optional ones keep their "?" prefix. A list the
# platform does not have (e.g. network.txt on FreeBSD) is empty.
list_names() {
    [[ -f "${PKG_DIR}/$1" ]] || return 0
    sed -e 's/#.*//' -e 's/[[:space:]]//g' -e '/^$/d' -- "${PKG_DIR}/$1"
}

# Check every name against the platform's repositories (plat_available, one query for all).
resolve_packages() {
    step "Checking package names"
    local list name missing=() wanted=() optional=()
    declare -A have=()
    PKG_REQUIRED=()
    PKG_SKIPPED=()
    for list in "${PKG_LISTS[@]}"; do
        while IFS= read -r name; do
            if [[ "${name}" == \?* ]]; then
                optional+=("${name#\?}")
            else
                wanted+=("${name}|${list}")
            fi
        done < <(list_names "${list}")
    done
    while IFS= read -r name; do
        have["${name}"]=1
    done < <(plat_available "${optional[@]}" "${wanted[@]%%|*}")
    for name in "${wanted[@]}"; do
        if [[ -n "${have[${name%%|*}]:-}" ]]; then
            PKG_REQUIRED+=("${name%%|*}")
        else
            missing+=("${name%%|*} (${name#*|})")
        fi
    done
    for name in "${optional[@]}"; do
        if [[ -n "${have[${name}]:-}" ]]; then PKG_REQUIRED+=("${name}"); else PKG_SKIPPED+=("${name}"); fi
    done
    if (( ${#missing[@]} )); then
        printf '    %s\n' "${missing[@]}" >&2
        die "these packages are not in your repositories. If your system was not updated recently, update it and re-run; otherwise please report it"
    fi
    (( ${#PKG_SKIPPED[@]} )) && warn "not in the repositories, skipped: ${PKG_SKIPPED[*]}"
    info "${#PKG_REQUIRED[@]} packages from: ${PKG_LISTS[*]}"
}

install_packages() {
    step "Installing packages"
    plat_install "${PKG_REQUIRED[@]}"
}

# Build an AUR package as the user (makepkg refuses root), install it with pacman via makepkg -si.
install_aur() {
    local pkg="$1" dir="${XDG_CACHE_HOME:-${HOME}/.cache}/rice/aur/$1"
    step "Building ${pkg} from the AUR"
    warn "AUR packages are maintained by users, not Arch; review ${dir}/PKGBUILD if unsure"
    if [[ -d "${dir}/.git" ]]; then
        run git -C "${dir}" pull --ff-only --quiet
    else
        run mkdir -p -- "$(dirname -- "${dir}")"
        run git clone --quiet "https://aur.archlinux.org/${pkg}.git" "${dir}"
    fi
    local flags=(-si --needed)
    (( ASSUME_YES )) && flags+=(--noconfirm)
    if (( DRY_RUN )); then
        run makepkg "${flags[@]}"
    else
        (cd -- "${dir}" && makepkg "${flags[@]}")
    fi
}

# The config is Lua-only, which needs Hyprland 0.57+ (hyprland.md#version-gate). Arch ships what
# it ships, so this warns instead of stopping: the rest of the rice is still useful.
check_hyprland_version() {
    (( DRY_RUN )) && return 0
    local version
    version="$(Hyprland --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)"
    if [[ -z "${version}" ]]; then
        warn "could not read the Hyprland version (Hyprland --version)"
    elif [[ "$(printf '%s\n' 0.57.0 "${version}" | sort -V | head -n 1)" != 0.57.0 ]]; then
        warn "Hyprland ${version} is older than 0.57: it may not load this Lua config; update when Arch ships 0.57"
    else
        info "Hyprland ${version}"
    fi
}
