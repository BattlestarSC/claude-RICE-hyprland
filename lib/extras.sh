# shellcheck shell=bash
# What a system's packages cannot provide: components built from source at pinned versions
# (lib/pins.sh) and upstream release files checked against a SHA-256. Everything goes under
# /usr/local, never over files the package manager owns. Sourced by install.sh; a platform module
# calls these from plat_extras. Docs: docs/knowledge-base/platforms.md#source-builds.
#
# Re-runs are cheap: each component leaves a stamp (/usr/local/share/rice/built/<name>) holding the
# version it was built from, and is skipped while the stamp matches the pin.

EXTRAS_PREFIX=/usr/local
EXTRAS_SRC="${XDG_CACHE_HOME:-${HOME}/.cache}/rice/src"
EXTRAS_STAMPS="${EXTRAS_PREFIX}/share/rice/built"
EXTRAS_JOBS="$(nproc 2> /dev/null || sysctl -n hw.ncpu 2> /dev/null || echo 2)"

# Built libraries must be found by the next build in the chain and by the dynamic linker.
extras_env() {
    export PKG_CONFIG_PATH="${EXTRAS_PREFIX}/lib/pkgconfig:${EXTRAS_PREFIX}/lib64/pkgconfig:${EXTRAS_PREFIX}/share/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
    export CMAKE_PREFIX_PATH="${EXTRAS_PREFIX}${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"
    export PATH="${EXTRAS_PREFIX}/bin:${PATH}"
}

extras_stamp_ok() { [[ "$(cat "${EXTRAS_STAMPS}/$1" 2> /dev/null)" == "$2" ]]; }
extras_stamp() {
    (( DRY_RUN )) && return 0
    sudo mkdir -p -- "${EXTRAS_STAMPS}"
    printf '%s\n' "$2" | sudo tee -- "${EXTRAS_STAMPS}/$1" > /dev/null
}

# extras_fetch NAME URL REF: a clean checkout of REF (tag or commit) in the source cache.
extras_fetch() {
    local name="$1" url="$2" ref="$3" dir="${EXTRAS_SRC}/$1"
    if (( DRY_RUN )); then
        note "would fetch ${url} @ ${ref}"
        return 0
    fi
    mkdir -p -- "${dir}"
    git -C "${dir}" init -q
    git -C "${dir}" fetch -q --depth 1 "${url}" "${ref}"
    git -C "${dir}" -c advice.detachedHead=false checkout -q --force FETCH_HEAD
    git -C "${dir}" clean -qfdx
    git -C "${dir}" submodule -q update --init --recursive --depth 1
}

# extras_build "name|url|ref|system|args": fetch, configure, build, install (sudo), stamp.
extras_build() {
    local name url ref system args dir
    IFS='|' read -r name url ref system args <<< "$1"
    if extras_stamp_ok "${name}" "${ref}"; then
        note "${name} ${ref}: already built"
        return 0
    fi
    info "building ${name} (${ref})"
    extras_fetch "${name}" "${url}" "${ref}"
    dir="${EXTRAS_SRC}/${name}"
    # patches/<name>/*.patch: small portability fixes on top of upstream (see each file's header).
    local patch
    for patch in "${REPO}/patches/${name}"/*.patch; do
        [[ -f "${patch}" ]] || continue
        note "patch: ${patch#"${REPO}/"}"
        run git -C "${dir}" apply -- "${patch}"
    done
    local extra=()
    [[ -n "${args}" ]] && read -r -a extra <<< "${args}"
    case "${system}" in
        cmake)
            run cmake -S "${dir}" -B "${dir}/build" -G Ninja -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_INSTALL_PREFIX="${EXTRAS_PREFIX}" -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_TESTING=OFF "${extra[@]}"
            # -k 0: on a compile error, finish every other unit first, so one log shows all errors.
            run cmake --build "${dir}/build" -j "${EXTRAS_JOBS}" -- -k 0
            as_root cmake --install "${dir}/build"
            ;;
        meson)
            run meson setup "${dir}/build" "${dir}" --prefix="${EXTRAS_PREFIX}" --libdir=lib \
                --buildtype=release "${extra[@]}"
            run meson compile -C "${dir}/build" -j "${EXTRAS_JOBS}"
            as_root meson install -C "${dir}/build"
            ;;
        cargo)
            # ReGreet reads GREETD_CONFIG_DIR at compile time (FreeBSD: /usr/local/etc/greetd).
            run env GREETD_CONFIG_DIR="${GREETD_DIR}" cargo build --release --locked --manifest-path "${dir}/Cargo.toml" "${extra[@]}"
            as_root mkdir -p -- "${EXTRAS_PREFIX}/bin"
            as_root install -m 0755 "${dir}/target/release/${name}" "${EXTRAS_PREFIX}/bin/${name}"
            ;;
        copy)
            as_root install -d "${EXTRAS_PREFIX}/share/${name}"
            as_root cp -r "${dir}/." "${EXTRAS_PREFIX}/share/${name}/"
            as_root rm -rf "${EXTRAS_PREFIX}/share/${name}/.git"
            ;;
        cursors) extras_capitaine "${dir}" ;;
        *) die "unknown build system '${system}' for ${name}" ;;
    esac
    (( DRY_RUN )) || as_root ldconfig 2> /dev/null || true
    extras_stamp "${name}" "${ref}"
}

# extras_download "url|sha256" OUT: download and verify, or stop.
extras_download() {
    local url="${1%|*}" sum="${1#*|}" out="$2"
    if (( DRY_RUN )); then
        note "would download ${url}"
        return 0
    fi
    curl -fsSL --proto '=https' --tlsv1.2 -o "${out}" "${url}"
    [[ "$(sha256sum < "${out}" | cut -d' ' -f1)" == "${sum}" ]] \
        || die "checksum mismatch for ${url}; not installing it"
}

# Upstream Neovim release (when the packaged one is older than the 0.12 the config needs).
extras_neovim() {
    local url="${NEOVIM_URL%|*}" version
    version="$(basename -- "$(dirname -- "${url}")")"
    extras_stamp_ok neovim "${version}" && { note "Neovim ${version}: already installed"; return 0; }
    info "Neovim ${version} (upstream release)"
    extras_download "${NEOVIM_URL}" "${WORK_DIR}/nvim.tar.gz"
    as_root rm -rf "/opt/nvim-${version}"
    as_root install -d "/opt/nvim-${version}"
    as_root tar -xzf "${WORK_DIR}/nvim.tar.gz" -C "/opt/nvim-${version}" --strip-components=1
    as_root ln -sfn "/opt/nvim-${version}/bin/nvim" "${EXTRAS_PREFIX}/bin/nvim"
    extras_stamp neovim "${version}"
}

# tree-sitter CLI >= 0.26.1 for nvim-treesitter's main branch.
extras_tree_sitter() {
    local version
    version="$(basename -- "$(dirname -- "${TREESITTER_URL%|*}")")"
    extras_stamp_ok tree-sitter "${version}" && { note "tree-sitter ${version}: already installed"; return 0; }
    info "tree-sitter CLI ${version} (upstream release)"
    extras_download "${TREESITTER_URL}" "${WORK_DIR}/tree-sitter.gz"
    (( DRY_RUN )) || gzip -dc "${WORK_DIR}/tree-sitter.gz" > "${WORK_DIR}/tree-sitter"
    as_root install -m 0755 "${WORK_DIR}/tree-sitter" "${EXTRAS_PREFIX}/bin/tree-sitter"
    extras_stamp tree-sitter "${version}"
}

# Symbols Nerd Font (bar and terminal icons) and the adw-gtk3 theme, from their releases.
extras_nerd_symbols() {
    extras_stamp_ok nerd-symbols "${NERD_SYMBOLS_URL#*|}" && return 0
    info "Symbols Nerd Font (upstream release)"
    extras_download "${NERD_SYMBOLS_URL}" "${WORK_DIR}/nerd.tar.xz"
    as_root install -d "${EXTRAS_PREFIX}/share/fonts/nerd-symbols"
    as_root tar -xJf "${WORK_DIR}/nerd.tar.xz" -C "${EXTRAS_PREFIX}/share/fonts/nerd-symbols" \
        SymbolsNerdFont-Regular.ttf SymbolsNerdFontMono-Regular.ttf
    (( DRY_RUN )) || as_root fc-cache -f "${EXTRAS_PREFIX}/share/fonts/nerd-symbols" > /dev/null
    extras_stamp nerd-symbols "${NERD_SYMBOLS_URL#*|}"
}

extras_adw_gtk3() {
    extras_stamp_ok adw-gtk3 "${ADW_GTK3_URL#*|}" && return 0
    info "adw-gtk3 theme (upstream release)"
    extras_download "${ADW_GTK3_URL}" "${WORK_DIR}/adw.tar.xz"
    as_root install -d "${EXTRAS_PREFIX}/share/themes"
    as_root tar -xJf "${WORK_DIR}/adw.tar.xz" -C "${EXTRAS_PREFIX}/share/themes"
    extras_stamp adw-gtk3 "${ADW_GTK3_URL#*|}"
}

# Capitaine cursors from SVG: the repository's own build.sh needs the Inkscape 0.x command line,
# so this follows its recipe (src/config specs, sizes up to "xhd", aliases) with rsvg-convert and
# xcursorgen. Installs capitaine-cursors (dark) and capitaine-cursors-light.
extras_capitaine() {
    local src="$1/src" build="${WORK_DIR}/capitaine" variant theme spec name size dim x y xh yh frames delay i
    local sizes=(1 1.5 2 2.5 3)
    (( DRY_RUN )) && { note "would render Capitaine cursors (rsvg-convert, xcursorgen)"; return 0; }
    for variant in dark light; do
        rm -rf -- "${build}"
        mkdir -p -- "${build}/out"
        for size in "${sizes[@]}"; do
            dim="$(awk -v s="${size}" 'BEGIN { printf "%d", 24 * s }')"
            mkdir -p -- "${build}/x${size}"
            for spec in "${src}/svg/${variant}"/*.svg; do
                rsvg-convert -w "${dim}" -h "${dim}" -o "${build}/x${size}/$(basename -- "${spec%.svg}").png" "${spec}"
            done
        done
        for spec in "${src}/config/static"/*.spec; do
            name="$(basename -- "${spec%.spec}")"
            read -r x y < "${spec}"
            for size in "${sizes[@]}"; do
                read -r dim xh yh < <(awk -v s="${size}" -v x="${x}" -v y="${y}" 'BEGIN { printf "%d %d %d", 24 * s, x * s, y * s }')
                printf '%s %s %s %s\n' "${dim}" "${xh}" "${yh}" "x${size}/${name}.png"
            done > "${build}/${name}.in"
            (cd -- "${build}" && xcursorgen "${name}.in" "out/${name}")
        done
        for spec in "${src}/config/animated"/*.spec; do
            name="$(basename -- "${spec%.spec}")"
            read -r x y frames delay < "${spec}"
            for size in "${sizes[@]}"; do
                read -r dim xh yh < <(awk -v s="${size}" -v x="${x}" -v y="${y}" 'BEGIN { printf "%d %d %d", 24 * s, x * s, y * s }')
                for (( i = 0; i < frames; i++ )); do
                    printf '%s %s %s %s %s\n' "${dim}" "${xh}" "${yh}" "x${size}/${name}-$(printf '%02d' "${i}").png" "${delay}"
                done
            done > "${build}/${name}.in"
            (cd -- "${build}" && xcursorgen "${name}.in" "out/${name}")
        done
        while read -r alias target; do
            [[ -n "${alias}" && ! -e "${build}/out/${alias}" ]] && ln -s "${target}" "${build}/out/${alias}"
        done < "${src}/cursor-aliases"
        theme=capitaine-cursors
        [[ "${variant}" == light ]] && theme=capitaine-cursors-light
        as_root rm -rf "${EXTRAS_PREFIX}/share/icons/${theme}"
        as_root install -d "${EXTRAS_PREFIX}/share/icons/${theme}/cursors"
        as_root cp -RP "${build}/out/." "${EXTRAS_PREFIX}/share/icons/${theme}/cursors/"
        printf '[Icon Theme]\nName=Capitaine Cursors%s\nComment=A stylish cursor for humans\n' \
            "$([[ "${variant}" == light ]] && printf ' - White')" \
            | as_root install -m 0644 /dev/stdin "${EXTRAS_PREFIX}/share/icons/${theme}/index.theme"
    done
}

# Programs started by the session or the portal must be found where the system looks (for
# files under /usr/local that a /usr-only search would miss): the Hyprland session entry for the
# login screen and XDPH's portal description.
extras_link_into_usr() {
    local f
    for f in share/wayland-sessions/hyprland.desktop share/xdg-desktop-portal/portals/hyprland.portal; do
        [[ -e "${EXTRAS_PREFIX}/${f}" || "${DRY_RUN}" == 1 ]] || continue
        deploy_system_file "${EXTRAS_PREFIX}/${f}" "/usr/${f}"
    done
    return 0
}

# The whole Hyprland 0.57 stack in dependency order (lib/pins.sh).
extras_hypr_stack() {
    local entry
    for entry in "${HYPR_STACK[@]}"; do
        extras_build "${entry}"
    done
    extras_link_into_usr
}
