-- Hyprland config for the login screen (user "greeter"). Installed to /etc/greetd/ with
-- monitors.lua and colors.lua next to it: the greeter cannot read anything under /home.
-- Same monitor layout and scale as the desktop; no binds except the VT switch Hyprland always
-- keeps; ReGreet starts once Hyprland is up and Hyprland exits when ReGreet does.

local ok, c = pcall(require, "colors")
pcall(require, "monitors")   -- the desktop's conf/monitors.lua, copied by install.sh / rice-monitors

hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        disable_hyprland_guiutils_check = true,
        background_color = ok and c.crust or nil,   -- the second monitor shows only this
    },
    animations = { enabled = false },
})

-- ReGreet README: skip slow portal start-up in the greeter.
hl.env("GTK_USE_PORTAL", "0")
hl.env("GDK_DEBUG", "no-portals")
hl.env("XCURSOR_THEME", "capitaine-cursors-light")
hl.env("XCURSOR_SIZE", "24")

hl.on("hyprland.start", function()
    hl.exec_cmd("regreet; hyprctl dispatch 'hl.dsp.exit()'")
end)
