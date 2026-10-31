#!/usr/bin/env bash
# tests/x11/smoke.sh [OUT_DIR]: start the installed i3 session in Xvfb and check that its parts
# come up: i3 with ~/.config/i3/config, the helpers of `rice-session x11` (picom, dunst, xss-lock,
# clipmenud), polybar (a dock window), a notification, the lock screen (i3lock-color with the
# rice's options; it must still be running after 2 s, i.e. it accepted them). Saves screenshots
# to OUT_DIR (default: a temporary directory). Run as the user who installed, after
# verify-install.sh. Needs Xvfb (FreeBSD: xorg-vfbserver) and the i3 desktop's packages.
set -Eeuo pipefail

out="${1:-$(mktemp -d)}"
mkdir -p -- "${out}"
export PATH="${HOME}/.local/bin:${PATH}"
cfg="${XDG_CONFIG_HOME:-${HOME}/.config}"
fails=0
pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }
running() { pgrep -u "$(id -u)" -x "$1" > /dev/null; }
# wait_for SECONDS CMD...: poll until CMD succeeds.
wait_for() {
    local n=$(( $1 * 5 ))
    shift
    while (( n-- > 0 )); do
        "$@" > /dev/null 2>&1 && return 0
        sleep 0.2
    done
    return 1
}

display=:57
Xvfb "${display}" -screen 0 2560x1440x24 -nolisten tcp > "${out}/xvfb.log" 2>&1 &
xvfb=$!
export DISPLAY="${display}"
unset WAYLAND_DISPLAY
cleanup() {
    pkill -u "$(id -u)" -x i3lock 2> /dev/null || true
    [[ -n "${i3pid:-}" ]] && kill "${i3pid}" 2> /dev/null
    for p in polybar picom dunst xss-lock clipmenud; do pkill -u "$(id -u)" -x "${p}" 2> /dev/null || true; done
    kill "${xvfb}" 2> /dev/null || true
}
trap cleanup EXIT
wait_for 10 xset q || { cat "${out}/xvfb.log"; echo "FAIL Xvfb did not start"; exit 1; }

# The session as LightDM starts it, minus the display manager: env.sh, a session bus, i3.
# shellcheck source=/dev/null
. "${cfg}/i3/env.sh"
dbus-run-session -- i3 -c "${cfg}/i3/config" > "${out}/i3.log" 2>&1 &
i3pid=$!
if wait_for 15 i3-msg -t get_version; then pass "i3 runs with ~/.config/i3/config"; else fail "i3 runs"; tail -n 30 "${out}/i3.log"; exit 1; fi
# The i3 config's exec lines run rice-session x11 and rice-bar launch.
for p in picom dunst xss-lock polybar; do
    if wait_for 15 running "${p}"; then
        pass "${p} running"
    else
        fail "${p} running"
        case "${p}" in   # run it in the foreground for its error message
            picom)   timeout 5 picom --config "${cfg}/picom/picom.conf" 2>&1 | tail -n 20 || true ;;
            dunst)   timeout 5 dunst 2>&1 | tail -n 20 || true ;;
            polybar) timeout 5 polybar main 2>&1 | tail -n 20 || true ;;
        esac
    fi
done
agent=""
for a in /usr/local/libexec/polkit-gnome-authentication-agent-1 /usr/libexec/polkit-gnome-authentication-agent-1 \
    /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 \
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1; do
    [[ -x "${a}" ]] && { agent="${a}"; break; }
done
if [[ -z "${agent}" ]]; then
    fail "polkit-gnome agent found where rice-session looks for it"
elif wait_for 10 pgrep -u "$(id -u)" -f polkit-gnome-authentication-agent-1; then
    pass "polkit agent running (${agent})"
else
    fail "polkit agent running (${agent})"
fi
if command -v clipmenud > /dev/null; then
    if wait_for 10 pgrep -u "$(id -u)" -f clipmenud; then pass "clipmenud running"; else fail "clipmenud running"; fi
fi
# The bar is override-redirect (it floats like the Quickshell bar): an X window i3 does not manage.
if wait_for 10 bash -c "xwininfo -root -tree | grep -q '\"Polybar\")'"; then
    pass "polybar draws a bar window"
else
    fail "polybar draws a bar window"
fi
# notify-send needs the session bus i3 runs under: run it through i3.
i3-msg 'exec notify-send -a rice "Quasar" "The i3 session is up."' > /dev/null
i3-msg 'exec rice-volume up' > /dev/null
sleep 2
for cmd in rice-bar\ cpu rice-bar\ mem rice-bar\ load rice-bar\ disk rice-bar\ net rice-bar\ vol; do
    if [[ "${cmd}" == "rice-bar cpu" ]]; then
        v="$(timeout 5 rice-bar cpu | head -n 1 || true)"
    else
        v="$(${cmd} 2> /dev/null || true)"
    fi
    if [[ -n "${v}" ]]; then pass "${cmd}: ${v}"; else fail "${cmd} prints a value"; fi
done
# A few windows for the screenshot (tiling, gaps, borders): RICE_SMOKE_WINDOWS=xterm, say.
if [[ -n "${RICE_SMOKE_WINDOWS:-}" ]]; then
    for _ in 1 2 3; do i3-msg "exec ${RICE_SMOKE_WINDOWS}" > /dev/null; done
    sleep 3
fi
maim -u "${out}/desktop.png" && pass "screenshot ${out}/desktop.png"

# Lock screen: i3lock-color must accept every option rice-session passes (else it exits at once).
i3-msg 'exec rice-session lock' > /dev/null
if wait_for 10 running i3lock && sleep 2 && running i3lock; then
    pass "i3lock stays up with the rice's options"
    maim -u "${out}/lock.png" || true
else
    fail "i3lock stays up with the rice's options"
fi

echo
if (( fails )); then
    printf '%d check(s) failed\n' "${fails}"
    exit 1
fi
echo "all X11 checks passed"
