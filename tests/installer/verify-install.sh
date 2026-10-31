#!/usr/bin/env bash
# tests/installer/verify-install.sh: after a real ./install.sh, check that the target environment
# is there: packages, commands, language toolchains that compile and run a program, language
# servers, deployed and generated files, desktop defaults, system changes. Run as the user who
# installed. Prints every failure and exits 1 if there was any. Used by full-install.sh.
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
REPO="${repo}"
# shellcheck source=lib/log.sh
source "${repo}/lib/log.sh"
# shellcheck source=lib/platform.sh
source "${repo}/lib/platform.sh"
detect_platform
echo "platform: ${PLAT_NAME} (${PLAT_INIT}), desktop: ${RICE_DESKTOP} (RICE_DESKTOP picks it where offered)"
cfg="${XDG_CONFIG_HOME:-${HOME}/.config}"
data="${XDG_DATA_HOME:-${HOME}/.local/share}"
export PATH="${HOME}/.local/bin:${PATH}"
work="$(mktemp -d)"
trap 'rm -rf -- "${work}"' EXIT
fails=0

pass() { printf 'ok   %s\n' "$1"; }
failed=()
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); failed+=("$1"); }
# check NAME CMD...: CMD must succeed (its output is shown only on failure).
check() {
    local name="$1" out
    shift
    if out="$("$@" 2>&1)"; then pass "${name}"; else fail "${name}"; printf '%s\n' "${out}" | tail -n 15 | sed 's/^/     /'; fi
}
# expect NAME WANT CMD...: CMD's output must contain WANT.
expect() {
    local name="$1" want="$2" out
    shift 2
    out="$("$@" 2>&1 || true)"
    if [[ "${out}" == *"${want}"* ]]; then pass "${name}"; else fail "${name} (wanted '${want}')"; printf '%s\n' "${out}" | tail -n 15 | sed 's/^/     /'; fi
}

echo "== packages"
missing=()
for list in desktop shell apps editors languages office network "${PLAT_EXTRA_LISTS[@]%.txt}"; do
    [[ -f "${PKG_DIR}/${list}.txt" ]] || continue
    while IFS= read -r name; do
        optional=0
        [[ "${name}" == \?* ]] && { optional=1; name="${name#\?}"; }
        plat_installed "${name}" && continue
        # An optional name the repositories lack was skipped on purpose.
        if (( optional )) && ! plat_available "${name}" | grep -qFx -- "${name}"; then continue; fi
        missing+=("${name}")
    done < <(sed -e 's/#.*//' -e 's/[[:space:]]//g' -e '/^$/d' "${PKG_DIR}/${list}.txt")
done
if (( ${#missing[@]} )); then fail "packages installed (missing: ${missing[*]})"; else pass "every listed package is installed"; fi

echo "== desktop commands"
# Same program, different names: Helix is hx outside Arch, Code - OSS is VSCodium's codium.
helix_cmd="$(command -v helix || command -v hx || echo helix)"
code_cmd="$(command -v code || command -v codium || echo code)"
# Platform differences: FreeBSD has no Code - OSS package and no greetd (console autostart).
optional_cmds=()
[[ "${PLAT_ID}" == freebsd ]] || optional_cmds+=("${code_cmd##*/}")
[[ "${PLAT_GREETER}" == greetd ]] && optional_cmds+=(greetd regreet)
if [[ "${RICE_DESKTOP}" == i3 ]]; then
    desktop_cmds=(i3 i3-msg picom polybar dunst i3lock xss-lock feh maim slop xclip clipmenu clipmenud)
else
    desktop_cmds=(Hyprland hyprlock hypridle quickshell slurp grim wl-copy)
fi
for cmd in "${desktop_cmds[@]}" rofi kitty foot zsh starship nvim "${helix_cmd##*/}" vis \
    librewolf firefox thunderbird thunar dolphin imv zathura strawberry amberol kasts qt6ct \
    gnome-keyring-daemon seahorse btop htop fastfetch jq "${optional_cmds[@]}"; do
    if command -v "${cmd}" > /dev/null; then
        pass "command ${cmd}"
    elif [[ "${cmd}" == amberol ]] && flatpak info io.bassi.Amberol > /dev/null 2>&1; then
        pass "Amberol (Flatpak)"   # Fedora: Flathub, no command on PATH
    else
        fail "command ${cmd}"
    fi
done
if [[ "${RICE_DESKTOP}" == hyprland ]]; then
    version="$(Hyprland --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)"
    if [[ -n "${version}" && "$(printf '%s\n' 0.57.0 "${version}" | sort -V | head -n 1)" == 0.57.0 ]]; then
        pass "Hyprland ${version} >= 0.57"
    else
        fail "Hyprland ${version:-?} >= 0.57"
    fi
else
    expect "i3lock is i3lock-color" ".c." i3lock -v
fi

echo "== configs in the real programs"
if [[ "${RICE_DESKTOP}" == hyprland ]]; then
    # Hyprland parses the Lua config without starting a compositor (src/Compositor.cpp
    # initServer); it still wants a runtime directory.
    rt="$(mktemp -d)"; chmod 0700 "${rt}"
    check "Hyprland accepts ~/.config/hypr/hyprland.lua" env XDG_RUNTIME_DIR="${rt}" Hyprland --verify-config -c "${cfg}/hypr/hyprland.lua"
    if [[ "${PLAT_GREETER}" == greetd ]]; then   # FreeBSD: no greeter, Hyprland after a console login
        check "Hyprland accepts the login screen's ${GREETD_DIR}/hyprland.lua" env XDG_RUNTIME_DIR="${rt}" Hyprland --verify-config -c "${GREETD_DIR}/hyprland.lua"
    fi
else
    # i3 -C parses the config (and its includes) and exits; 1 on any error (no X needed).
    check "i3 accepts ~/.config/i3/config" i3 -C -c "${cfg}/i3/config"
    check "the X session environment loads" bash -c ". '${cfg}/i3/env.sh' && [[ -n \${XCURSOR_THEME} ]]"
    # picom, polybar and dunst need an X server: tests/x11/smoke.sh runs them under Xvfb.
fi
# Neovim: the installer pre-built plugins and parsers (lib/desktop.sh nvim_prepare), so the first
# start is an ordinary one and must load the config and quit.
parsers="$(find "${data}/nvim/site/parser" -name '*.so' 2> /dev/null | wc -l)"
if (( parsers >= 23 )); then pass "tree-sitter parsers built (${parsers})"; else fail "tree-sitter parsers built (${parsers} of 23)"; fi
nvim_rc=0
nvim_out="$(timeout 60 nvim --headless '+lua print("RICE-LOADED")' +qa < /dev/null 2>&1)" || nvim_rc=$?
if (( nvim_rc == 0 )) && [[ "${nvim_out}" == *RICE-LOADED* ]]; then pass "Neovim starts, loads the config and quits"; else fail "Neovim starts, loads the config and quits (exit ${nvim_rc})"; printf '%s\n' "${nvim_out}" | tail -n 15 | sed 's/^/     /'; fi
check "Neovim plugins present" test -d "${data}/nvim/site/pack/core/opt/nvim-tree.lua"
check "Helix config loads" bash -c "'${helix_cmd}' --health 2>&1 | grep -q 'Config file'"

echo "== office"
for cmd in pdflatex lualatex xelatex biber texstudio texlab libreoffice; do
    if command -v "${cmd}" > /dev/null; then pass "command ${cmd}"; else fail "command ${cmd}"; fi
done
cat > "${work}/doc.tex" <<'EOF'
\documentclass{article}
\usepackage{amsmath}
\begin{document}
Hello, rice. $e^{i\pi} + 1 = 0$
\end{document}
EOF
check "pdflatex builds a document" bash -c "cd '${work}' && pdflatex -interaction=nonstopmode doc.tex && test -s doc.pdf"
unopkg=unopkg
for c in /usr/lib/libreoffice/program/unopkg /usr/lib64/libreoffice/program/unopkg /usr/local/lib/libreoffice/program/unopkg; do
    [[ -x "${c}" ]] && { unopkg="${c}"; break; }
done
expect "LibreOffice theme extension registered" "rice" "${unopkg}" list

echo "== languages (compile and run)"
check "Elixir runs" elixir -e 'IO.puts(Enum.sum(1..10))'
expect "Erlang/OTP present" "OTP" erl -noshell -eval 'io:format("OTP ~s~n", [erlang:system_info(otp_release)]), halt().'
check "full Erlang/OTP (observer, dialyzer)" erl -noshell -eval 'ok = application:load(observer), ok = application:load(dialyzer), halt().'
printf 'main :: IO ()\nmain = print (sum [1..10 :: Int])\n' > "${work}/hello.hs"
check "GHC compiles and runs" bash -c "cd '${work}' && ghc -O0 -o hello-hs hello.hs && ./hello-hs | grep -qx 55"
check "cabal" cabal --version
check "SWI-Prolog runs" swipl -g 'X is 6*7, X == 42' -t halt
printf 'program hello\n  print *, sum([1,2,3,4,5,6,7,8,9,10])\nend program hello\n' > "${work}/hello.f90"
check "gfortran compiles and runs" bash -c "cd '${work}' && gfortran -o hello-f hello.f90 && ./hello-f | grep -q 55"
expect "Java is OpenJDK 25" 'version "25' java -version
expect "javac is 25" "javac 25" javac -version
if [[ "${PLAT_ID}" == arch ]]; then
    expect "archlinux-java default is java-25-openjdk" "java-25-openjdk" archlinux-java get
fi
printf 'public class Hello { public static void main(String[] a) { System.out.println(6 * 7); } }\n' > "${work}/Hello.java"
check "javac compiles and java runs" bash -c "cd '${work}' && javac Hello.java && java -cp . Hello | grep -qx 42"
# scala run: the scala-cli based runner (Scala >= 3.5, Coursier); FreeBSD keeps its packaged 3.3
# runner (Coursier has no FreeBSD launcher), which compiles with scalac and runs a class.
check "Scala runs a program" bash -c "cd '${work}' && printf '@main def hi(): Unit = println(6 * 7)\n' > hi.scala &&
    { scala run hi.scala 2> /dev/null | grep -qx 42 || { mkdir -p sc && scalac -d sc hi.scala && scala -classpath sc hi | grep -qx 42; }; }"
check "sbt launcher" sbt --script-version
check "OCaml" ocaml -version

echo "== language servers"
check "elixir-ls" test -x "${HOME}/.local/bin/elixir-ls"
check "haskell-language-server" haskell-language-server-wrapper --version
check "SWI-Prolog lsp_server pack" swipl -g 'use_module(library(lsp_server))' -t halt
check "metals" test -x "${HOME}/.local/bin/metals"
check "fortls" fortls --version
check "texlab" texlab --version
check "vis-lspc" test -f "${cfg}/vis/plugins/vis-lspc/init.lua"

echo "== files"
if [[ "${RICE_DESKTOP}" == hyprland ]]; then
    desktop_files=(hypr/hyprland.lua hypr/conf/env.lua hypr/hyprlock.conf hypr/hypridle.conf
        hypr/xdph.conf hypr/hyprtoolkit.conf hypr/theme/colors.conf quickshell/shell.qml
        quickshell/common/Theme.qml quickshell/sky/shaders/scene.frag.qsb
        quickshell/sky/shaders/glyph.frag.qsb)
    desktop_data=(rice/quickshell/sky-atlas-12x24.png)
else
    desktop_files=(i3/config i3/colors.conf i3/env.sh i3/lock.sh picom/picom.conf
        polybar/config.ini polybar/colors.ini dunst/dunstrc)
    desktop_data=()
fi
for f in "${desktop_files[@]}" rofi/deck.rasi \
    kitty/theme.conf foot/theme.ini zsh/theme.zsh starship.toml nvim/colors/rice.lua \
    helix/themes/rice.toml imv/config zathura/zathurarc qt6ct/qt6ct.conf qt6ct/colors/rice.conf \
    rice/settings.json; do
    if [[ -s "${cfg}/${f}" ]]; then pass "config/${f}"; else fail "config/${f}"; fi
done
for f in "${desktop_data[@]}" rice/lock.png color-schemes/Quasar.colors; do
    if [[ -s "${data}/${f}" ]]; then pass "data/${f}"; else fail "data/${f}"; fi
done
if [[ "${RICE_DESKTOP}" == hyprland ]]; then
    expect "xdph.conf points at the picker" "${HOME}/.local/bin/rice-share-picker" cat "${cfg}/hypr/xdph.conf"
else
    check "polybar local.ini exists (polybar stops without it)" test -e "${cfg}/polybar/local.ini"
fi
if [[ "${PLAT_ID}" != freebsd ]]; then
    expect "Code - OSS theme installed" "rice" "${code_cmd}" --list-extensions
    expect "Code - OSS uses the keyring" "gnome-libsecret" cat "${HOME}/.vscode-oss/argv.json"
fi

echo "== shell"
# Under a pseudo-terminal (script, util-linux), as in a real terminal: without one zle cannot start.
if [[ "${PLAT_ID}" == freebsd ]]; then   # BSD script(1): file first, then the command
    # BSD script echoes the EOF it sends (^D and backspaces) before the output.
    zsh_out="$(script -q /dev/null zsh -i -c 'print -r -- ok' < /dev/null 2>&1 | tr -d '\r\b' | sed 's/^^D//' || true)"
else
    zsh_out="$(script -qec "zsh -i -c 'print -r -- ok'" /dev/null 2>&1 | tr -d '\r' || true)"
fi
if [[ "${zsh_out}" == ok ]]; then pass "zsh loads the config without errors"; else fail "zsh loads the config without errors"; printf '%s\n' "${zsh_out}" | tail -n 15 | sed 's/^/     /'; fi

echo "== desktop defaults"
expect "images open in imv" "imv" xdg-mime query default image/png
expect "PDF opens in Zathura" "zathura" xdg-mime query default application/pdf
expect "audio opens in Amberol" "Amberol" xdg-mime query default audio/mpeg
expect "folders open in Thunar" "thunar" xdg-mime query default inode/directory
expect "web pages open in LibreWolf" "librewolf" xdg-mime query default text/html
expect "mail links open in Thunderbird" "hunderbird" xdg-mime query default x-scheme-handler/mailto   # org.mozilla.Thunderbird.desktop

expect "GTK prefers dark (dconf persisted)" "prefer-dark" dbus-run-session -- gsettings get org.gnome.desktop.interface color-scheme
expect "Dolphin uses the Quasar scheme" "Quasar" kreadconfig6 --file dolphinrc --group UiSettings --key ColorScheme

echo "== system"
expect "login shell is zsh" "${ZSH_BIN}" getent passwd "$(id -un)"
check "Firefox policies" test -s "${FIREFOX_POLICY_DIR}/policies.json"
if [[ "${PLAT_GREETER}" == greetd ]]; then
    expect "greetd is the display manager" "greetd.service" readlink /etc/systemd/system/display-manager.service
    expect "keyring unlocked at login" "pam_gnome_keyring.so auto_start" cat "${PAM_DIR}/greetd"
    check "greeter config deployed" test -s "${GREETD_DIR}/hyprland.lua"
    check "login background rendered" test -s "${GREETD_DIR}/background.png"
    check "bluetooth enabled" test -e /etc/systemd/system/bluetooth.target.wants/bluetooth.service
elif [[ "${PLAT_GREETER}" == lightdm ]]; then
    expect "lightdm enabled" "YES" sysrc -n lightdm_enable
    expect "dbus enabled" "YES" sysrc -n dbus_enable
    expect "LightDM starts the rice's session" "user-session=rice-i3" cat "${LIGHTDM_ETC}/lightdm.conf.d/50-rice.conf"
    expect "greeter theme" "theme-name=Quasar-greeter" cat "${LIGHTDM_ETC}/lightdm-gtk-greeter.conf.d/50-rice.conf"
    check "greeter theme CSS" test -s "${DATA_DIRS[0]}/themes/Quasar-greeter/gtk-3.0/gtk.css"
    check "greeter background" test -s "${LIGHTDM_ETC}/rice/background.png"
    check "session entry" test -s "${XSESSIONS_DIR}/rice-i3.desktop"
    check "session launcher" test -x "${RICE_LIBEXEC}/rice-i3-session"
    expect "keyring unlocked at login" "pam_gnome_keyring.so auto_start" cat "${PAM_DIR}/lightdm"
    check "the PAM module named there exists" test -f "${PAM_KEYRING_MODULE}"
    check "lightdm" test -x /usr/local/sbin/lightdm
else
    expect "Hyprland starts after a console login" "${PLAT_FIRST_TTY}" cat "${cfg}/rice/tty-autostart"
    expect "seatd enabled" "YES" sysrc -n seatd_enable
    expect "dbus enabled" "YES" sysrc -n dbus_enable
    expect "user in group video (seatd)" "video" id -Gn
fi

echo
if (( fails )); then
    printf 'FAILED: %s\n' "${failed[@]}"
    printf '%d check(s) failed\n' "${fails}"
    exit 1
fi
echo "all checks passed"
