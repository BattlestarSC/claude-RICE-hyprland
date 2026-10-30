# shellcheck shell=bash
# Copying files into place, with backups. Sourced by install.sh.
#
# Rule (D29): copy, never symlink. A target that already exists with different content is first
# copied to ~/.local/state/rice/backups/<timestamp>/<same path> and listed in the manifest there;
# identical targets are left alone, so re-running changes nothing that is already current.
# Files named local.* are the user's: created empty if missing, never overwritten.

BACKUP_DIR="${RICE_STATE}/backups/${RICE_STAMP}"
DEPLOYED=0
UNCHANGED=0
BACKED_UP=0

# Backup path for an absolute target: <backups>/home/... or <backups>/system/etc/...
backup_path() {
    local target="$1"
    if [[ "${target}" == "${HOME}"/* ]]; then
        printf '%s/home/%s' "${BACKUP_DIR}" "${target#"${HOME}"/}"
    else
        printf '%s/system%s' "${BACKUP_DIR}" "${target}"
    fi
}

record_backup() {
    printf '%s\t%s\n' "$1" "$2" >> "${BACKUP_DIR}/manifest.tsv"
    BACKED_UP=$((BACKED_UP + 1))
}

# deploy_file SRC DEST [MODE]: copy one file into the user's home.
deploy_file() {
    local src="$1" dest="$2" mode="${3:-}" backup
    [[ -f "${src}" ]] || die "missing source file ${src}"
    if [[ -z "${mode}" ]]; then
        if [[ -x "${src}" ]]; then mode=0755; else mode=0644; fi
    fi
    if [[ -d "${dest}" && ! -L "${dest}" ]]; then
        die "${dest} is a directory, expected a file; move it away and re-run"
    fi
    if [[ -f "${dest}" && ! -L "${dest}" ]] && cmp -s -- "${src}" "${dest}"; then
        UNCHANGED=$((UNCHANGED + 1))
        return 0
    fi
    if [[ -e "${dest}" || -L "${dest}" ]]; then
        backup="$(backup_path "${dest}")"
        if (( DRY_RUN )); then
            note "would back up ${dest}"
        else
            mkdir -p -- "$(dirname -- "${backup}")"
            cp -P -p -- "${dest}" "${backup}"
            rm -f -- "${dest}"
            record_backup "${dest}" "${backup}"
        fi
    fi
    run install -D -m "${mode}" -- "${src}" "${dest}"
    DEPLOYED=$((DEPLOYED + 1))
}

# deploy_tree SRCDIR DESTDIR: every file below SRCDIR, same relative paths.
deploy_tree() {
    local src="$1" dest="$2" file
    while IFS= read -r -d '' file; do
        deploy_file "${file}" "${dest}/${file#"${src}"/}"
    done < <(find "${src}" -type f -print0 | sort -z)
}

# ensure_file DEST: the user's override hook; create it empty, never touch an existing one.
ensure_file() {
    [[ -e "$1" ]] && return 0
    run install -D -m 0644 /dev/null "$1"
}

# deploy_system_file SRC DEST [MODE]: same as deploy_file, for paths outside $HOME (sudo).
deploy_system_file() {
    local src="$1" dest="$2" mode="${3:-0644}" backup
    [[ -f "${src}" ]] || die "missing source file ${src}"
    if [[ -f "${dest}" ]] && cmp -s -- "${src}" "${dest}"; then
        UNCHANGED=$((UNCHANGED + 1))
        return 0
    fi
    if [[ -e "${dest}" ]]; then
        backup="$(backup_path "${dest}")"
        if (( DRY_RUN )); then
            note "would back up ${dest}"
        else
            mkdir -p -- "$(dirname -- "${backup}")"
            sudo cat -- "${dest}" | tee -- "${backup}" > /dev/null
            record_backup "${dest}" "${backup}"
        fi
    fi
    as_root install -D -m "${mode}" -- "${src}" "${dest}"
    DEPLOYED=$((DEPLOYED + 1))
}

start_backups() {
    (( DRY_RUN )) && return 0
    mkdir -p -- "${BACKUP_DIR}"
    : >> "${BACKUP_DIR}/manifest.tsv"
}

# Remove an empty backup directory at the end (nothing was replaced).
finish_backups() {
    (( DRY_RUN )) && return 0
    if [[ ! -s "${BACKUP_DIR}/manifest.tsv" ]]; then
        rm -f -- "${BACKUP_DIR}/manifest.tsv"
        rmdir -- "${BACKUP_DIR}" 2> /dev/null || true
    fi
}
