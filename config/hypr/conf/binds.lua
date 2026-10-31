-- Keybindings: i3's default keymap on Hyprland 0.57.
-- i3 → Hyprland mapping and the reasoning for each non-obvious bind: docs/keybindings.md.
--
-- Callbacks run on the compositor thread: never block in them (no io.popen, no sleep).
-- External work always goes through hl.dsp.exec_cmd.

local mod      = "SUPER"     -- i3-config-wizard's "Win" choice. Use "ALT" for i3's literal Mod1.
local terminal = "kitty"
local launcher = "rofi -show drun"   -- Orbit theme (i3: dmenu_run)
local runner   = "rofi -show run -theme orbit"
local menu     = "rice-menu"         -- scripted menus, Flight Deck theme (bin/rice-menu)

-- i3 default movement keys are j k l ; (shifted one right of vim's hjkl).
local dirs = {
    { key = "j",         arrow = "Left",  dir = "left"  },
    { key = "k",         arrow = "Down",  dir = "down"  },
    { key = "l",         arrow = "Up",    dir = "up"    },
    { key = "semicolon", arrow = "Right", dir = "right" },
}

local function key(...) return table.concat({ ... }, " + ") end

-------------------------------------------------------------------------------
-- i3 defaults
-------------------------------------------------------------------------------

hl.bind(key(mod, "Return"),        hl.dsp.exec_cmd(terminal),  { description = "Terminal" })
hl.bind(key(mod, "SHIFT", "q"),    hl.dsp.window.close(),      { description = "Close window" })
hl.bind(key(mod, "d"),             hl.dsp.exec_cmd(launcher),  { description = "App launcher" })

-- Focus. Inside a group (i3 "tabbed"), left/right walk the tabs first and leave the
-- group at either end, like i3. Evaluated per keypress, hence the functions.
for _, d in ipairs(dirs) do
    local function focus()
        local w = hl.get_active_window()
        local g = w and w.group
        if g and g.size > 1 then
            if d.dir == "left" and g.current_index > 1 then
                return hl.dispatch(hl.dsp.group.prev())
            elseif d.dir == "right" and g.current_index < g.size then
                return hl.dispatch(hl.dsp.group.next())
            end
        end
        hl.dispatch(hl.dsp.focus({ direction = d.dir }))
    end
    hl.bind(key(mod, d.key),   focus, { description = "Focus " .. d.dir })
    hl.bind(key(mod, d.arrow), focus)

    local move = hl.dsp.window.move({ direction = d.dir, group_aware = true })
    hl.bind(key(mod, "SHIFT", d.key),   move, { description = "Move window " .. d.dir })
    hl.bind(key(mod, "SHIFT", d.arrow), move)
end

-- i3 "split h" / "split v": choose where the NEXT window opens (dwindle preselect).
hl.bind(key(mod, "h"), hl.dsp.layout("preselect r"), { description = "Next window opens right (split h)" })
hl.bind(key(mod, "v"), hl.dsp.layout("preselect d"), { description = "Next window opens below (split v)" })
-- i3 "layout toggle split". Needs dwindle.preserve_split = true (set in look.lua).
hl.bind(key(mod, "e"), hl.dsp.layout("togglesplit"), { description = "Toggle split direction" })

hl.bind(key(mod, "f"), hl.dsp.window.fullscreen({ action = "toggle" }), { description = "Fullscreen" })

-- i3 "layout stacking" / "layout tabbed": Hyprland's equivalent is a group (tabbed only).
hl.bind(key(mod, "w"), hl.dsp.group.toggle(), { description = "Tabbed (toggle group)" })
hl.bind(key(mod, "s"), hl.dsp.group.toggle(), { description = "Stacking (toggle group; Hyprland has tabs only)" })

hl.bind(key(mod, "SHIFT", "space"), hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating" })
-- i3 "focus mode_toggle": jump between the tiled and floating layers.
hl.bind(key(mod, "space"), function()
    local w = hl.get_active_window()
    if w and w.floating then
        hl.dispatch(hl.dsp.window.cycle_next({ tiled = true }))
    else
        hl.dispatch(hl.dsp.window.cycle_next({ floating = true }))
    end
end, { description = "Focus tiled / floating" })
-- i3 "focus parent" ($mod+a) has no Hyprland equivalent (no container tree); left unbound.

-- Scratchpad.
hl.bind(key(mod, "SHIFT", "minus"), hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }),
        { description = "Move to scratchpad" })
hl.bind(key(mod, "minus"), hl.dsp.workspace.toggle_special("scratchpad"), { description = "Show scratchpad" })

-- Workspaces 1-10 ($mod+0 is 10). i3 moves without following; so do we.
for i = 1, 10 do
    local k = tostring(i % 10)
    hl.bind(key(mod, k),          hl.dsp.focus({ workspace = i }), { description = "Workspace " .. i })
    hl.bind(key(mod, "SHIFT", k), hl.dsp.window.move({ workspace = i, follow = false }),
            { description = "Move window to workspace " .. i })
end

-- i3 reload / restart. Hyprland has no in-place restart; both reload the config.
hl.bind(key(mod, "SHIFT", "c"), hl.dsp.reload_config(), { description = "Reload config" })
hl.bind(key(mod, "SHIFT", "r"), hl.dsp.reload_config(), { description = "Reload config (i3 restart)" })
-- i3 shows i3-nagbar to exit; here: the session menu (lock, log out, suspend, reboot, shut down).
hl.bind(key(mod, "SHIFT", "e"), hl.dsp.exec_cmd(menu .. " session"), { description = "Session menu" })

-- Resize mode, i3 semantics: left/up shrink, right/down grow. 40 logical px per step.
local step = 40
local grow = { left = { -step, 0 }, down = { 0, step }, up = { 0, -step }, right = { step, 0 } }
hl.bind(key(mod, "r"), hl.dsp.submap("resize"), { description = "Resize mode" })
hl.define_submap("resize", function()
    for _, d in ipairs(dirs) do
        local r = hl.dsp.window.resize({ x = grow[d.dir][1], y = grow[d.dir][2], relative = true })
        hl.bind(d.key,   r, { repeating = true })
        hl.bind(d.arrow, r, { repeating = true })
    end
    hl.bind("Return",        hl.dsp.submap("reset"))
    hl.bind("Escape",        hl.dsp.submap("reset"))
    hl.bind(key(mod, "r"),   hl.dsp.submap("reset"))
end)

-- i3 floating_modifier: drag with $mod + left button, resize with $mod + right button.
hl.bind(key(mod, "mouse:272"), hl.dsp.window.drag(),   { mouse = true })
hl.bind(key(mod, "mouse:273"), hl.dsp.window.resize(), { mouse = true })

-- Media keys (i3 uses pactl and 10% steps; PipeWire's wpctl here, same steps).
local media = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 10%+"), media)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"),      media)
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })

-------------------------------------------------------------------------------
-- Additions (no i3 default uses these keys)
-------------------------------------------------------------------------------

hl.bind(key(mod, "SHIFT", "d"), hl.dsp.exec_cmd(runner), { description = "Run a command" })
hl.bind(key(mod, "SHIFT", "x"), hl.dsp.exec_cmd("rice-session lock"), { description = "Lock" })
hl.bind(key(mod, "SHIFT", "v"), hl.dsp.exec_cmd(menu .. " clipboard"), { description = "Clipboard history" })
hl.bind(key(mod, "Tab"),        hl.dsp.exec_cmd(menu .. " windows"),   { description = "Switch window" })
hl.bind(key(mod, "SHIFT", "m"), hl.dsp.exec_cmd(menu .. " monitors"),  { description = "Monitors (KVM)" })
hl.bind(key(mod, "F1"),         hl.dsp.exec_cmd(menu .. " keys"),      { description = "Keybinding cheat sheet" })
hl.bind("Print",                hl.dsp.exec_cmd(menu .. " screenshot"), { description = "Screenshot" })

-- Two monitors: send the current workspace to the other screen.
hl.bind(key(mod, "CTRL", "SHIFT", "Left"),  hl.dsp.workspace.move({ monitor = "l" }), { description = "Workspace to left monitor" })
hl.bind(key(mod, "CTRL", "SHIFT", "Right"), hl.dsp.workspace.move({ monitor = "r" }), { description = "Workspace to right monitor" })

hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
