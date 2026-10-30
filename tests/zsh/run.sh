#!/usr/bin/env bash
# Load the rice's zsh config in a throwaway HOME and check that it is complete and silent.
#   tests/zsh/run.sh
# Needs zsh; plugins are checked if their Arch paths exist (/usr/share/zsh/plugins/...).
# Fails on any output to stderr while loading, a missing option, style or key binding.
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -r -- "${tmp}"' EXIT

mkdir -p "${tmp}/.config/zsh"
cp -- "${repo}/home/.zshenv" "${repo}/home/.zshrc" "${tmp}/"
cp -- "${repo}"/config/zsh/*.zsh "${tmp}/.config/zsh/"
cp -- "${repo}/themes/quasar/zsh/theme.zsh" "${tmp}/.config/zsh/"

out="$(HOME="${tmp}" TERM=xterm-256color zsh -i -c "source '${repo}/tests/zsh/probe.zsh'" 2> "${tmp}/stderr")"
printf '%s\n' "${out}"
if [[ -s "${tmp}/stderr" ]]; then
    printf 'FAIL: zsh wrote to stderr while loading:\n' >&2
    cat -- "${tmp}/stderr" >&2
    exit 1
fi
if grep -q '^FAIL' <<< "${out}"; then exit 1; fi
printf 'OK\n'
