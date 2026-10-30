#!/usr/bin/env bash
# tests/installer/verify-install.sh: after a real ./install.sh, check that the target environment
# is there: packages, commands, language toolchains that compile and run a program, language
# servers, deployed and generated files, desktop defaults, system changes. Run as the user who
# installed. Prints every failure and exits 1 if there was any. Used by full-install.sh.
set -Eeuo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cfg="${XDG_CONFIG_HOME:-${HOME}/.config}"
data="${XDG_DATA_HOME:-${HOME}/.local/share}"
export PATH="${HOME}/.local/bin:${PATH}"
work="$(mktemp -d)"
trap 'rm -rf -- "${work}"' EXIT
fails=0

pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }
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
for list in desktop shell apps editors languages office network; do
    while IFS= read -r name; do
        optional=0
        [[ "${name}" == \?* ]] && { optional=1; name="${name#\?}"; }
        pacman -Q -- "${name}" > /dev/null 2>&1 && continue
        # An optional name the repositories lack was skipped on purpose.
        (( optional )) && ! pacman -Si -- "${name}" > /dev/null 2>&1 && continue
        missing+=("${name}")
    done < <(sed -e 's/#.*//' -e 's/[[:space:]]//g' -e '/^$/d' "${repo}/packages/${list}.txt")
done
if (( ${#missing[@]} )); then fail "packages installed (missing: ${missing[*]})"; else pass "every listed package is installed"; fi

echo "== desktop commands"
for cmd in Hyprland hyprlock hypridle quickshell rofi kitty foot zsh starship nvim helix vis code \
    librewolf firefox thunderbird thunar dolphin imv zathura strawberry amberol kasts qt6ct \
    greetd regreet gnome-keyring-daemon seahorse btop htop fastfetch slurp grim wl-copy jq; do
    if command -v "${cmd}" > /dev/null; then pass "command ${cmd}"; else fail "command ${cmd}"; fi
done
version="$(Hyprland --version 2> /dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)"
if [[ -n "${version}" && "$(printf '%s\n' 0.57.0 "${version}" | sort -V | head -n 1)" == 0.57.0 ]]; then
    pass "Hyprland ${version} >= 0.57"
else
    fail "Hyprland ${version:-?} >= 0.57"
fi

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
expect "LibreOffice theme extension registered" "rice" /usr/lib/libreoffice/program/unopkg list

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
printf 'public class Hello { public static void main(String[] a) { System.out.println(6 * 7); } }\n' > "${work}/Hello.java"
check "javac compiles and java runs" bash -c "cd '${work}' && javac Hello.java && java -cp . Hello | grep -qx 42"
check "Scala runs a program" bash -c "cd '${work}' && printf '@main def hi(): Unit = println(6 * 7)\n' > hi.scala && scala run hi.scala | grep -qx 42"
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
for f in hypr/hyprland.lua hypr/conf/env.lua hypr/hyprlock.conf hypr/hypridle.conf hypr/xdph.conf \
    hypr/hyprtoolkit.conf hypr/theme/colors.conf quickshell/shell.qml quickshell/common/Theme.qml \
    quickshell/sky/shaders/scene.frag.qsb quickshell/sky/shaders/glyph.frag.qsb rofi/deck.rasi \
    kitty/theme.conf foot/theme.ini zsh/theme.zsh starship.toml nvim/colors/rice.lua \
    helix/themes/rice.toml imv/config zathura/zathurarc qt6ct/qt6ct.conf qt6ct/colors/rice.conf \
    rice/settings.json; do
    if [[ -s "${cfg}/${f}" ]]; then pass "config/${f}"; else fail "config/${f}"; fi
done
for f in rice/quickshell/sky-atlas-12x24.png rice/lock.png color-schemes/Quasar.colors; do
    if [[ -s "${data}/${f}" ]]; then pass "data/${f}"; else fail "data/${f}"; fi
done
expect "xdph.conf points at the picker" "${HOME}/.local/bin/rice-share-picker" cat "${cfg}/hypr/xdph.conf"
expect "Code - OSS theme installed" "rice" code --list-extensions
expect "Code - OSS uses the keyring" "gnome-libsecret" cat "${HOME}/.vscode-oss/argv.json"

echo "== shell"
# Under a pseudo-terminal (script, util-linux), as in a real terminal: without one zle cannot start.
zsh_out="$(script -qec "zsh -i -c 'print -r -- ok'" /dev/null 2>&1 | tr -d '\r' || true)"
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
expect "greetd is the display manager" "greetd.service" readlink /etc/systemd/system/display-manager.service
expect "login shell is zsh" "/usr/bin/zsh" getent passwd "$(id -un)"
expect "keyring unlocked at login" "pam_gnome_keyring.so auto_start" cat /etc/pam.d/greetd
check "greeter config deployed" test -s /etc/greetd/hyprland.lua
check "login background rendered" test -s /etc/greetd/background.png
check "Firefox policies" test -s /etc/firefox/policies/policies.json
check "bluetooth enabled" test -e /etc/systemd/system/bluetooth.target.wants/bluetooth.service

echo
if (( fails )); then
    printf '%d check(s) failed\n' "${fails}"
    exit 1
fi
echo "all checks passed"
