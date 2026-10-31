# shellcheck shell=bash
# Environment of the i3 (X11) session, the counterpart of hypr/conf/env.lua. Sourced by
# `rice-session i3` before it starts i3, so every program i3 launches inherits it.
# The installer writes the chosen cursor theme in place of capitaine-cursors-light.

# Commands the binds call (rice-menu, rice-volume, rice-bar) live in ~/.local/bin.
case ":${PATH}:" in
    *":${HOME}/.local/bin:"*) ;;
    *) PATH="${HOME}/.local/bin:${PATH}" ;;
esac
export PATH

export XDG_CURRENT_DESKTOP=i3 XDG_SESSION_TYPE=x11 XDG_SESSION_DESKTOP=i3
# Qt 6 apps: the palette through qt6ct (D41), as under Hyprland.
export QT_QPA_PLATFORMTHEME=qt6ct
# KDE apps outside Plasma find their menu here (config/menus/applications.menu).
export XDG_MENU_PREFIX=arch-

# Cursor: the same search path and fallback as env.lua.
rice_cursor_theme=capitaine-cursors-light
XCURSOR_PATH="${HOME}/.local/share/icons:${HOME}/.icons:/usr/local/share/icons:/usr/share/icons:/usr/share/pixmaps"
rice_cursor_found=0
for rice_dir in ${XCURSOR_PATH//:/ }; do
    [[ -f "${rice_dir}/${rice_cursor_theme}/cursors/left_ptr" ]] && rice_cursor_found=1
done
(( rice_cursor_found )) || rice_cursor_theme=Adwaita
export XCURSOR_PATH XCURSOR_THEME="${rice_cursor_theme}" XCURSOR_SIZE=24
unset rice_cursor_theme rice_cursor_found rice_dir
