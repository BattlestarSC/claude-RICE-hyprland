# shellcheck shell=bash
# Per-user desktop defaults: GTK/KDE settings, default applications, app setup helpers.
# Sourced by install.sh. Everything here writes only inside $HOME.

desktop_defaults() {
    step "Setting desktop defaults for $(id -un)"

    # GTK reads these through gsettings before settings.ini under Wayland (theming.md). No session
    # bus exists on a TTY, so dconf is written through a private one.
    if command -v gsettings > /dev/null || (( DRY_RUN )); then
        # shellcheck disable=SC2016  # $1 is expanded by the inner sh (the cursor theme argument)
        run dbus-run-session -- sh -c '
            gsettings set org.gnome.desktop.interface color-scheme prefer-dark
            gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
            gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
            gsettings set org.gnome.desktop.interface font-name "IBM Plex Sans 11"
            gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono 11"
            gsettings set org.gnome.desktop.interface cursor-theme "$1"
            gsettings set org.gnome.desktop.interface cursor-size 24' sh "${CURSOR_THEME}"
    fi

    # Dolphin and other KDE apps: the generated Quasar scheme, Papirus icons, Arch's XDG menu.
    if command -v kwriteconfig6 > /dev/null || (( DRY_RUN )); then
        run kwriteconfig6 --file dolphinrc --group UiSettings --key ColorScheme Quasar
        run kwriteconfig6 --file kdeglobals --group Icons --key Theme Papirus-Dark
    fi
    if command -v kbuildsycoca6 > /dev/null; then
        run env XDG_MENU_PREFIX=arch- kbuildsycoca6 --noincremental > /dev/null 2>&1 || true
    fi

    # Default applications.
    if command -v xdg-mime > /dev/null || (( DRY_RUN )); then
        run xdg-mime default thunar.desktop inode/directory
        run xdg-mime default librewolf.desktop x-scheme-handler/http x-scheme-handler/https text/html
        run xdg-mime default nvim.desktop text/plain
    fi
    command -v xdg-user-dirs-update > /dev/null && run xdg-user-dirs-update

    # Browser profiles and Code - OSS (each prints what it did; a browser that was never started
    # has no profile yet: rice-browser-setup again after its first start).
    run "${HOME}/.local/bin/rice-browser-setup" || warn "rice-browser-setup failed (see above); re-run it later"
    if command -v code > /dev/null || (( DRY_RUN )); then
        run "${HOME}/.local/bin/rice-code-setup" || warn "rice-code-setup failed (see above); re-run it later"
    fi

    # Language servers that are not in Arch's repositories (opt-in list, D27).
    if (( WANT_LANGUAGES )); then
        run "${HOME}/.local/bin/rice-lsp-setup" elixir haskell prolog scala fortran vis-lspc \
            || warn "some language servers were not installed; run rice-lsp-setup to see which"
        if [[ -d "${OPAMROOT:-${HOME}/.opam}" ]]; then
            run "${HOME}/.local/bin/rice-lsp-setup" ocaml || warn "OCaml server not installed"
        else
            note "OCaml: run 'opam init', then 'rice-lsp-setup ocaml' (opam init asks before editing your shell files)"
        fi
    fi
}
