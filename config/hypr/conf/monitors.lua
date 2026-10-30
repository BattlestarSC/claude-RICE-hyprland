-- Monitors: two 27" 4K ASUS ProArt panels behind a Level1Techs dual-DP KVM.
-- See docs/knowledge-base/hardware.md (EDID matching, scale, 10-bit, KVM hot-unplug).
--
-- The installer replaces the two DESC_* strings with the real EDID descriptions from
-- `hyprctl monitors all` (they include the serial, so identical panels stay distinct and keep
-- their positions even if the cables swap). Positions are in logical px: 3840 / 1.5 = 2560.

local DESC_LEFT  = "desc:REPLACE-WITH-LEFT-PANEL-DESCRIPTION"
local DESC_RIGHT = "desc:REPLACE-WITH-RIGHT-PANEL-DESCRIPTION"

-- Color depth: Hyprland supports 8 or 10 bits per channel (12 is not an option in 0.57).
-- 10-bit removes banding in gradients; two known costs: some apps cannot screen-capture a
-- 10-bit output, and Hyprland's own border colors stay 8-bit. Set to 8 if sharing breaks.
-- cm = "srgb": the desktop is sRGB content; treating the wide-gamut panels as sRGB keeps colors
-- accurate. For color-managed work, load an ICC profile with `icc = "/abs/path.icm"` instead.
local panel = { mode = "3840x2160@60", scale = 1.5, bitdepth = 10, cm = "srgb" }

local function with(extra)
    local t = {}
    for k, v in pairs(panel) do t[k] = v end
    for k, v in pairs(extra) do t[k] = v end
    return t
end

hl.monitor(with({ output = DESC_LEFT,  position = "0x0" }))
hl.monitor(with({ output = DESC_RIGHT, position = "2560x0" }))
-- Anything else (a laptop panel, a TV, the KVM showing a different screen): sensible defaults.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Workspaces live on a fixed monitor, so the config (not just Hyprland's runtime memory)
-- says where they go back to after a KVM switch. Left: 1-5, right: 6-10 (matches the bar).
for i = 1, 10 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor = i <= 5 and DESC_LEFT or DESC_RIGHT,
        default = (i == 1 or i == 6),
        persistent = (i == 1 or i == 6),
    })
end
