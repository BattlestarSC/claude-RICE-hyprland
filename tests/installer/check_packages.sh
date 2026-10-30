#!/usr/bin/env bash
# Check every name in packages/*.txt (except aur.txt) against the Arch repositories.
# Run inside Arch (CI uses the archlinux:latest container) after `pacman -Sy`:
#
#   tests/installer/check_packages.sh
#
# A missing required name fails; a missing optional (?name) one is reported as a warning, and a
# present optional one is reported so its "?" can be dropped.
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
missing=0
for list in "${repo}"/packages/*.txt; do
    [[ "$(basename -- "${list}")" == aur.txt ]] && continue
    while IFS= read -r name; do
        optional=0
        if [[ "${name}" == \?* ]]; then
            optional=1
            name="${name#\?}"
        fi
        if pacman -Si -- "${name}" > /dev/null 2>&1; then
            (( optional )) && printf 'optional but present (drop the ?): %s in %s\n' "${name}" "$(basename -- "${list}")"
        elif (( optional )); then
            printf '::warning::optional package not in the repositories: %s (%s)\n' "${name}" "$(basename -- "${list}")"
        else
            printf '::error::package not in the repositories: %s (%s)\n' "${name}" "$(basename -- "${list}")"
            missing=$((missing + 1))
        fi
    done < <(sed -e 's/#.*//' -e 's/[[:space:]]//g' -e '/^$/d' -- "${list}")
done
(( missing == 0 )) || { printf '%d required package(s) missing\n' "${missing}"; exit 1; }
printf 'all required packages exist\n'
