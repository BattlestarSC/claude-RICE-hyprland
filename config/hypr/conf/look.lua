-- Window look: gaps, borders, rounded corners, shadow, blur, background.
-- Kept deliberately mild: on a 2560x1440 logical screen (4K at scale 1.5) two side-by-side
-- windows lose 26 logical px of width to gaps and borders (~1%). Colors: theme/colors.lua.
local c = require("theme.colors")

hl.config({
    general = {
        gaps_in = 3,              -- between windows: 2 x 3 = 6 logical px (9 physical)
        gaps_out = 6,             -- to the screen edge and the bar; = Theme.screenGap in Quickshell
        border_size = 2,
        resize_on_border = true,  -- drag a border or gap to resize, as in i3
        col = {
            -- Active: the launcher's red -> purple frame. Inactive: barely there.
            active_border = { colors = { c.red, c.purple }, angle = 45 },
            inactive_border = c.surface2,
        },
    },
    decoration = {
        rounding = 6,             -- logical px; the bar pills and rofi use larger radii on purpose
        rounding_power = 2.0,     -- circular arcs
        shadow = {
            enabled = true,
            range = 8,
            render_power = 3,
            color = c.shadow,
            color_inactive = c.shadow_soft,
        },
        -- Windows stay opaque (readability first); blur only applies to the layers that ask for
        -- it in layers.lua (bar, rofi). Two small passes: frosted, not smeared.
        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            new_optimizations = true,
        },
        dim_inactive = false,
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        background_color = c.crust,   -- shown before the wallpaper starts and on a FALLBACK output
    },
})

-- Optional "smart gaps": no gaps or border when a workspace has a single tiled window.
-- Off by default because the bar floats with its own gap; uncomment in local.lua to use.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
