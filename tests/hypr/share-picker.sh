#!/usr/bin/env bash
# tests/hypr/share-picker.sh: bin/rice-share-picker against stub rofi, hyprctl and slurp.
# Checks the stdout lines XDPH parses (src/shared/ScreencopyShared.cpp; the stock picker's
# formatSelection in hyprland-share-picker/PickerData.cpp prints the same shapes):
#   [SELECTION]<r?>/screen:NAME | window:HANDLE | region:OUTPUT@X,Y,W,H, nothing on cancel.
# Needs bash and jq.
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
picker="${repo}/bin/rice-share-picker"
stubs="$(mktemp -d)"
trap 'rm -rf -- "${stubs}"' EXIT
fails=0

cat > "${stubs}/hyprctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' '[{"name":"DP-1","width":3840,"height":2160,"description":"Some Panel 0x1"},
                {"name":"HDMI-A-1","width":1920,"height":1080,"description":"Other"}]'
EOF
# rofi: records what it was shown, answers with $ROFI_INDEX and exits with $ROFI_RC.
cat > "${stubs}/rofi" <<'EOF'
#!/usr/bin/env bash
cat > "${STUBS}/rows"
printf '%s\n' "$*" > "${STUBS}/args"
[[ -n "${ROFI_INDEX:-}" ]] && printf '%s\n' "${ROFI_INDEX}"
exit "${ROFI_RC:-0}"
EOF
cat > "${stubs}/slurp" <<'EOF'
#!/usr/bin/env bash
[[ "$*" == "-f %o %X %Y %W %H" ]] || { echo "slurp: unexpected args: $*" >&2; exit 2; }
[[ -n "${SLURP_OUT:-}" ]] || exit 1
printf '%s\n' "${SLURP_OUT}"
EOF
chmod +x "${stubs}"/*

# Two windows plus one malformed entry; the second title has a newline and a tab.
windows=$'101[HC>]kitty[HT>]~/src[HE>]94372[HA>]'
windows+=$'4294967295[HC>]org.mozilla.firefox[HT>]Meet\n- call\tnow[HE>]0[HA>]'
windows+='garbage[HA>]'

run() { # run EXPECTED [env...] -- [picker args...]
    local expected="$1" got
    shift
    local envs=()
    while [[ "$1" != -- ]]; do envs+=("$1"); shift; done
    shift
    got="$(env PATH="${stubs}:${PATH}" STUBS="${stubs}" XDPH_WINDOW_SHARING_LIST="${windows}" \
        "${envs[@]}" "${picker}" "$@")" || { echo "FAIL picker exited non-zero (${envs[*]})"; fails=$((fails + 1)); return 0; }
    if [[ "${got}" == "${expected}" ]]; then
        echo "ok   ${expected:-<nothing>}  (${envs[*]} $*)"
    else
        echo "FAIL expected '${expected}', got '${got}'  (${envs[*]} $*)"
        fails=$((fails + 1))
    fi
}

run '[SELECTION]/screen:DP-1'              ROFI_INDEX=0 --
run '[SELECTION]/screen:HDMI-A-1'          ROFI_INDEX=1 --
run '[SELECTION]/window:101'               ROFI_INDEX=2 --
run '[SELECTION]/window:4294967295'        ROFI_INDEX=3 --
run '[SELECTION]r/window:101'              ROFI_INDEX=2 ROFI_RC=10 --
run '[SELECTION]r/screen:DP-1'             ROFI_INDEX=0 -- --allow-token
run '[SELECTION]/region:HDMI-A-1@10,20,300,200' ROFI_INDEX=4 'SLURP_OUT=HDMI-A-1 10 20 300 200' --
run ''                                     ROFI_INDEX=4 --                       # slurp cancelled
run ''                                     ROFI_INDEX=4 'SLURP_OUT=DP-1 5 5 0 9' --   # empty region
run ''                                     ROFI_RC=1 --                          # Escape
run ''                                     ROFI_INDEX=9 --                       # out of range

# One row per screen and window (newline flattened, malformed entry dropped) plus region.
env PATH="${stubs}:${PATH}" STUBS="${stubs}" XDPH_WINDOW_SHARING_LIST="${windows}" ROFI_RC=1 "${picker}" || true
rows="$(wc -l < "${stubs}/rows")"
if [[ "${rows}" -eq 5 ]] && grep -q 'Meet - call now' "${stubs}/rows" && grep -q -- '-format i' "${stubs}/args"; then
    echo "ok   5 rows, titles flattened, rofi returns the index"
else
    echo "FAIL rows:"; cat "${stubs}/rows"; fails=$((fails + 1))
fi

# Every success line must match what XDPH's parser accepts.
re='^\[SELECTION\]r?/(screen:[^[:space:]]+|window:[0-9]+|region:[^@[:space:]]+@[0-9]+,[0-9]+,[1-9][0-9]*,[1-9][0-9]*)$'
for line in '[SELECTION]/screen:DP-1' '[SELECTION]r/window:101' '[SELECTION]/region:HDMI-A-1@10,20,300,200'; do
    [[ "${line}" =~ ${re} ]] || { echo "FAIL format ${line}"; fails=$((fails + 1)); }
done

if (( fails )); then
    echo "${fails} failure(s)"
    exit 1
fi
echo OK
