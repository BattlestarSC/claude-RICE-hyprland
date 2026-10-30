# shellcheck shell=bash
# Output, logging, prompts and the dry-run wrapper. Sourced by install.sh.

DRY_RUN=0
ASSUME_YES=0
RICE_STATE="${XDG_STATE_HOME:-${HOME}/.local/state}/rice"
RICE_STAMP="$(date +%Y%m%d-%H%M%S)"
RICE_LOG=""

if [[ -t 1 ]]; then
    C_DIM=$'\e[2m' C_STEP=$'\e[1;35m' C_WARN=$'\e[33m' C_ERR=$'\e[1;31m' C_OFF=$'\e[0m'
else
    C_DIM='' C_STEP='' C_WARN='' C_ERR='' C_OFF=''
fi

step() { printf '\n%s==> %s%s\n' "${C_STEP}" "$*" "${C_OFF}"; }
info() { printf '    %s\n' "$*"; }
note() { printf '    %s%s%s\n' "${C_DIM}" "$*" "${C_OFF}"; }
warn() { printf '%s  ! %s%s\n' "${C_WARN}" "$*" "${C_OFF}" >&2; }
die() {
    printf '%s  x %s%s\n' "${C_ERR}" "$*" "${C_OFF}" >&2
    [[ -n "${RICE_LOG}" ]] && printf '    log: %s\n' "${RICE_LOG}" >&2
    exit 1
}

# Everything after this goes to the terminal and to the log file.
start_log() {
    (( DRY_RUN )) && return 0
    mkdir -p -- "${RICE_STATE}"
    RICE_LOG="${RICE_STATE}/install-${RICE_STAMP}.log"
    exec > >(tee -a -- "${RICE_LOG}") 2>&1
    info "log: ${RICE_LOG}"
}

# run CMD...: execute, or print it in dry-run mode.
run() {
    if (( DRY_RUN )); then
        printf '    %swould run:%s' "${C_DIM}" "${C_OFF}"
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

# as_root CMD...: run with sudo (the only way the installer gains root).
as_root() { run sudo "$@"; }

# Keep sudo's credential cache warm for the whole run: the package step alone can take longer
# than sudo's timeout (5 min by default), and an unattended --yes run must not stop at a second
# password prompt. A background loop refreshes it every minute and ends with the installer.
SUDO_KEEPALIVE=""
keep_sudo_alive() {
    (( DRY_RUN )) && return 0
    (
        while sleep 60; do
            kill -0 "$$" 2> /dev/null || exit 0
            sudo -n -v 2> /dev/null || exit 0
        done
    ) &
    SUDO_KEEPALIVE=$!
}
stop_sudo_keepalive() {
    [[ -n "${SUDO_KEEPALIVE}" ]] && kill "${SUDO_KEEPALIVE}" 2> /dev/null
    return 0
}

# ask_yn QUESTION DEFAULT(y|n): 0 for yes. --yes or a non-interactive stdin takes the default.
ask_yn() {
    local question="$1" default="$2" reply hint
    [[ "${default}" == y ]] && hint='[Y/n]' || hint='[y/N]'
    if (( ASSUME_YES )) || [[ ! -t 0 ]]; then
        printf '    %s %s %s\n' "${question}" "${hint}" "${default}"
        [[ "${default}" == y ]]
        return
    fi
    while true; do
        read -r -p "    ${question} ${hint} " reply
        reply="${reply:-${default}}"
        case "${reply,,}" in
            y | yes) return 0 ;;
            n | no) return 1 ;;
            *) printf '    please answer y or n\n' ;;
        esac
    done
}

# ask_choice VAR QUESTION DEFAULT OPTION...: sets VAR to one of the options.
ask_choice() {
    local -n out="$1"
    local question="$2" default="$3" reply
    shift 3
    if (( ASSUME_YES )) || [[ ! -t 0 ]]; then
        out="${default}"
        printf '    %s (%s): %s\n' "${question}" "$*" "${out}"
        return 0
    fi
    while true; do
        read -r -p "    ${question} ($*) [${default}] " reply
        reply="${reply:-${default}}"
        local option
        for option in "$@"; do
            if [[ "${reply}" == "${option}" ]]; then
                out="${reply}"
                return 0
            fi
        done
        printf '    choose one of: %s\n' "$*"
    done
}
