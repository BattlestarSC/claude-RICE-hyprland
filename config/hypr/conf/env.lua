-- Session environment for everything Hyprland starts. Hyprland also exports these to systemd's
-- and D-Bus's activation environments, so user services (hyprpolkitagent, portals) see them.
-- Variable names: hyprland-wiki configuring/core/environment-variables.md.

-- ~/.local/bin (rice-menu, rice-monitors, language servers) on PATH for everything Hyprland
-- starts. greetd launches the session through /bin/sh with /etc/profile and ~/.profile only
-- (greetd session/worker.rs), so zsh's .zshenv never runs there. Added once, also on reloads.
do
    local bin = (os.getenv("HOME") or "") .. "/.local/bin"
    local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
    if not (":" .. path .. ":"):find(":" .. bin .. ":", 1, true) then
        hl.env("PATH", bin .. ":" .. path)
    end
end

-- Toolkits: Wayland first, X11 (XWayland) as fallback.
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
-- Qt 6 apps take style, palette (generated from the colors), icons and fonts from qt6ct
-- (~/.config/qt6ct/). KDE apps (Dolphin, Kasts) still apply their own Quasar scheme on top.
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- Dolphin's "Open with" list needs Arch's XDG menu outside Plasma (theming.md).
hl.env("XDG_MENU_PREFIX", "arch-")

-- Cursor theme. install.sh writes the chosen name here (RICE_CURSOR, default Capitaine light from
-- the official repos; alternatives: docs/knowledge-base/theming.md#cursor-themes). If that theme
-- is not installed, Adwaita (always present with GTK) is used. Checked once, at load time.
local cursor_theme = "capitaine-cursors-light"
local cursor_size = "24"

local function installed(theme)
    for _, dir in ipairs({ (os.getenv("HOME") or "") .. "/.local/share/icons/", "/usr/share/icons/" }) do
        local f = io.open(dir .. theme .. "/cursors/left_ptr", "r")
        if f then
            f:close()
            return true
        end
    end
    return false
end

if not installed(cursor_theme) then cursor_theme = "Adwaita" end
hl.env("XCURSOR_THEME", cursor_theme)
hl.env("XCURSOR_SIZE", cursor_size)
hl.env("HYPRCURSOR_SIZE", cursor_size)
