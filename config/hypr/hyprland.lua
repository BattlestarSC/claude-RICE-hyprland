-- rice: Hyprland 0.57 entry point. Only require() calls, in a fixed order; every setting lives in
-- conf/<concern>.lua (docs/knowledge-base/hyprland.md#splitting-the-config-require).
--
-- Each required file is its own error scope: an error in one file is reported and the others
-- still load. binds.lua comes first so a terminal (Super+Return) and the session menu exist even
-- if a later file breaks. Your own changes go in ~/.config/hypr/local.lua (optional, loaded last,
-- never written by the installer); the last hl.config write to an option wins.

require("conf.binds")
require("conf.env")
require("conf.monitors")
require("conf.input")
require("conf.look")
require("conf.layers")
require("conf.rules")
require("conf.session")
require("conf.autostart")

pcall(require, "local")
