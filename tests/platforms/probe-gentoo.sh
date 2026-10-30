#!/usr/bin/env bash
# tests/platforms/probe-gentoo.sh: which candidate atoms exist in the Gentoo tree, GURU and the
# overlays the installer would enable, with versions and keywords. Run as root in gentoo/stage3.
# One line per atom: ATOM REPO VERSIONS (newest last) KEYWORDS-of-newest, or ATOM MISSING.
set -Eeuo pipefail
emerge-webrsync -q > /dev/null 2>&1
emerge -q --oneshot app-eselect/eselect-repository dev-vcs/git > /dev/null 2>&1
for repo in guru hyproverlay librewolf; do
    eselect repository enable "${repo}" > /dev/null 2>&1 && echo "enabled overlay ${repo}" || echo "overlay ${repo}: not in the list"
done
emaint sync -r guru > /dev/null 2>&1 || true
emaint sync -r hyproverlay > /dev/null 2>&1 || true
emaint sync -r librewolf > /dev/null 2>&1 || true
echo "profile: $(readlink /etc/portage/make.profile)"
atoms=(
  gui-wm/hyprland gui-apps/hyprlock gui-apps/hypridle gui-libs/xdg-desktop-portal-hyprland gui-apps/hyprpolkitagent
  gui-libs/hyprland-guiutils gui-apps/hyprshutdown gui-libs/hyprtoolkit gui-apps/quickshell gui-libs/greetd gui-apps/regreet
  dev-lang/lua gui-libs/aquamarine dev-libs/hyprlang dev-libs/wayland-protocols dev-util/wayland-scanner
  sys-apps/xdg-desktop-portal-gtk x11-misc/xdg-utils x11-misc/xdg-user-dirs gnome-base/dconf gnome-base/gnome-keyring
  app-crypt/seahorse x11-misc/qt6ct dev-qt/qtwayland dev-qt/qtshadertools gnome-base/librsvg x11-misc/rofi gui-apps/rofi-wayland
  app-misc/jq x11-libs/libnotify gui-apps/wl-clipboard app-misc/cliphist gui-apps/grim gui-apps/slurp media-video/pipewire
  media-video/wireplumber media-sound/pavucontrol media-sound/playerctl app-misc/brightnessctl net-wireless/bluez
  media-fonts/jetbrains-mono media-fonts/ibm-plex media-fonts/noto media-fonts/noto-emoji media-fonts/nerdfonts
  media-fonts/symbols-nerd-font x11-themes/papirus-icon-theme x11-themes/capitaine-cursors x11-themes/adw-gtk3 gui-apps/nwg-look
  x11-terms/kitty gui-apps/foot app-shells/zsh app-shells/zsh-autosuggestions app-shells/zsh-syntax-highlighting
  app-shells/zsh-history-substring-search app-shells/starship app-shells/fzf app-shells/zoxide sys-apps/eza sys-apps/bat
  sys-apps/man-db sys-apps/man-pages sys-apps/less sys-process/htop sys-process/btop app-misc/fastfetch sys-apps/lm-sensors
  xfce-base/thunar xfce-base/thunar-volman xfce-extra/thunar-archive-plugin app-arch/xarchiver xfce-base/tumbler
  media-video/ffmpegthumbnailer gnome-base/gvfs sys-fs/udisks kde-apps/dolphin kde-apps/kio-extras kde-apps/ffmpegthumbs
  kde-plasma/breeze www-client/librewolf www-client/librewolf-bin www-client/firefox mail-client/thunderbird
  app-editors/vscodium app-editors/vscode media-gfx/imv app-text/zathura app-text/zathura-pdf-mupdf media-sound/strawberry
  media-sound/amberol media-sound/kasts kde-apps/kasts media-libs/gst-plugins-base media-libs/gst-plugins-good
  media-libs/gst-plugins-bad media-libs/gst-plugins-ugly media-plugins/gst-plugins-libav app-editors/neovim app-editors/vis
  app-editors/helix dev-util/tree-sitter-cli dev-lang/erlang dev-lang/elixir dev-lang/ghc dev-haskell/cabal-install
  dev-haskell/haskell-language-server dev-lang/swi-prolog dev-java/openjdk dev-java/openjdk-bin dev-java/sbt dev-lang/scala
  dev-lang/ocaml dev-ml/opam sys-apps/bubblewrap dev-python/pipx app-text/texlive app-office/texstudio dev-tex/biber
  dev-tex/texlab app-office/libreoffice app-office/libreoffice-bin app-dicts/myspell-en net-misc/networkmanager
  gnome-extra/nm-applet x11-apps/xcursorgen
)
for atom in "${atoms[@]}"; do
    found=""
    for dir in /var/db/repos/*/"${atom}"; do
        [[ -d "${dir}" ]] || continue
        repo="$(basename "$(dirname "$(dirname "${dir}")")")"
        mapfile -t ebuilds < <(find "${dir}" -maxdepth 1 -name '*.ebuild' -printf '%f\n' | sed 's/\.ebuild$//' | sort -V)
        (( ${#ebuilds[@]} )) || continue
        newest="${ebuilds[-1]}"
        kw="$(sed -n 's/^KEYWORDS="\(.*\)"/\1/p' "${dir}/${newest}.ebuild" | tr ' ' '\n' | grep -E '^~?amd64$' | head -n 1 || true)"
        printf '%-40s %-12s %s [%s]\n' "${atom}" "${repo}" "$(printf '%s ' "${ebuilds[@]: -3}" | sed "s|${atom##*/}-||g")" "${kw:-no-amd64-kw}"
        found=1
    done
    [[ -n "${found}" ]] || printf '%-40s MISSING\n' "${atom}"
done
