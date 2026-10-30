-- Window rules. Static effects (float, size, move, center, pin) apply once, when the window
-- opens, against its initial class and title; dynamic ones (idle_inhibit, dim_around, ...) are
-- re-evaluated. Class names: `hyprctl clients` (or `rice-menu windows`) on the running desktop.
-- Effect and prop names are checked by tests/lua/run.lua against the wiki (tests/lua/rules.lua).

-- From Hyprland's example config: apps may not maximize themselves (tiling decides), and
-- XWayland drag-and-drop helper windows must not steal focus.
hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({
    name = "xwayland-drag-fix",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Never blank or lock while something is fullscreen (video, game, presentation).
hl.window_rule({ name = "idle-inhibit-fullscreen", match = { class = ".*" }, idle_inhibit = "fullscreen" })

-- Small utility windows float, centered, instead of taking half a 27" screen.
local floating = {
    "^(org\\.pulseaudio\\.pavucontrol)$",   -- volume mixer (the bar's output picker opens it)
    "^(nm-connection-editor)$",             -- NetworkManager connections
    "^(blueman-manager)$",                  -- Bluetooth devices
    "^(xdg-desktop-portal-gtk)$",           -- file chooser dialogs (portal)
    "^(org\\.gnome\\.FileRoller|xarchiver)$",
    "^(com\\.gabm\\.satty)$",               -- screenshot annotation
    "^(qt6ct|nwg-look)$",
}
for i, class in ipairs(floating) do
    hl.window_rule({ name = "float-utility-" .. i, match = { class = class }, float = true, center = true,
                     size = "monitor_w*0.45 monitor_h*0.55" })
end

-- Thunar's copy/move progress and Firefox-family "Library" (downloads) windows.
hl.window_rule({ name = "float-file-progress", match = { title = "^(File Operation Progress)$" },
                 float = true, center = true })
hl.window_rule({ name = "float-browser-library", match = { title = "^(Library)$" }, float = true, center = true })

-- Polkit password prompt: float, centered, dim the rest so it is obvious what is asking.
hl.window_rule({ name = "polkit-prompt", match = { class = "^(hyprpolkitagent)$" },
                 float = true, center = true, pin = true, dim_around = true })

-- Picture-in-picture video (Firefox, LibreWolf): small, on every workspace, bottom right.
hl.window_rule({
    name = "pip",
    match = { title = "^(Picture-in-Picture)$" },
    float = true, pin = true, keep_aspect_ratio = true,
    size = "monitor_w*0.25 monitor_h*0.25",
    move = "monitor_w*0.74 monitor_h*0.73",
})
