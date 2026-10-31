#!/usr/bin/env bash
# tests/platforms/probe-gentoo-2.sh: follow-up facts for the Gentoo installer (run after the sync
# done by probe-gentoo.sh in the same container): Lua 5.5 for Hyprland 0.57, alternative names,
# OpenJDK slots, profiles.
set -Eeuo pipefail
echo "== hyprland-0.57.0.ebuild dependencies"
sed -n '/^RDEPEND=\|^DEPEND=\|^BDEPEND=\|^COMMON_DEPEND=/,/^"/p' /var/db/repos/hyproverlay/gui-wm/hyprland/hyprland-0.57.0.ebuild | head -n 60
grep -n 'lua\|LUA' /var/db/repos/hyproverlay/gui-wm/hyprland/hyprland-0.57.0.ebuild | head
echo "== lua anywhere"
find /var/db/repos -path '*/dev-lang/lua/*.ebuild' -printf '%h %f\n' | sort
echo "== names"
for n in qt6ct regreet hyprpolkitagent capitaine pipx texlab nwg-look haskell-language-server ghcup scala-cli; do
    printf '%-26s %s\n' "${n}" "$(find /var/db/repos -mindepth 3 -maxdepth 3 -type d -iname "*${n}*" -printf '%P ' 2> /dev/null)"
done
echo "== openjdk / openjdk-bin / ghc versions"
for a in dev-java/openjdk dev-java/openjdk-bin dev-lang/ghc dev-haskell/cabal-install dev-lang/swi-prolog; do
    printf '%-26s %s\n' "${a}" "$(find /var/db/repos/gentoo/${a} -name '*.ebuild' -printf '%f ' | sed "s|${a##*/}-||g; s|\.ebuild||g")"
done
echo "== desktop profiles"
eselect profile list | grep -E 'amd64/23.0/(desktop|systemd)' | head
