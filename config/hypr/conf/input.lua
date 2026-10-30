-- Keyboard, mouse and touchpad. Layout "us" is the default; set yours in local.lua, e.g.
--   hl.config({ input = { kb_layout = "de", kb_variant = "nodeadkeys" } })
hl.config({
    input = {
        kb_layout = "us",
        numlock_by_default = true,
        follow_mouse = 1,           -- focus follows the mouse, as in i3
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
            disable_while_typing = true,
        },
    },
    cursor = {
        inactive_timeout = 10,      -- hide the pointer after 10 s without movement
    },
})
