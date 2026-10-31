-- Programs started once per session. hl.exec_cmd returns immediately (nothing here blocks).
-- Quickshell draws the bar, wallpaper, notifications and screensaver from
-- ~/.config/quickshell/shell.qml; hypridle needs ~/.config/hypr/hyprlock.conf and
-- theme/colors.conf in place (the installer deploys them first).
hl.on("hyprland.start", function()
    -- Polkit password prompts. Without a systemd user manager (OpenRC, FreeBSD) rice-session
    -- starts the agent through D-Bus activation, and PipeWire.
    hl.exec_cmd("systemctl --user start hyprpolkitagent 2>/dev/null || rice-session start")
    hl.exec_cmd("quickshell")
    hl.exec_cmd("hypridle")
    -- First login: record the two panels' EDID descriptions in conf/monitors.lua (once).
    hl.exec_cmd("rice-monitors --auto")
    -- Clipboard history for rice-menu clipboard (Super+Shift+V): text and images.
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
