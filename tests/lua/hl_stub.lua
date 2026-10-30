-- A recording stand-in for Hyprland's `hl` Lua API, for testing config modules without
-- a compositor. Dispatcher names are the exact set registered by Hyprland v0.57.0
-- (src/config/lua/bindings/LuaBindingsDispatchers.cpp); a typo or a removed dispatcher
-- raises an error. Update the lists when the target Hyprland version changes.
--
-- Usage: lua5.4 tests/lua/run.lua <module.lua>...

local M = { binds = {}, submaps = {}, errors = {} }

-- Valid option paths for hl.config, generated from the wiki (tests/lua/gen_options.py).
local options = require("options")
-- Window/layer rule keys and event names, generated from the wiki (tests/lua/gen_rules.py).
local rules = require("rules")
M.events = {}

local function check_rule(kind, props, effects, t)
    assert(type(t) == "table", kind .. ": expects a table")
    for k, v in pairs(t) do
        if k == "match" then
            assert(type(v) == "table", kind .. ": match must be a table")
            for prop in pairs(v) do
                if not props[prop] then
                    M.errors[#M.errors + 1] = ("unknown %s match prop '%s' (rule %s)"):format(kind, prop, tostring(t.name))
                end
            end
        elseif k ~= "name" and k ~= "enabled" and not effects[k] then
            M.errors[#M.errors + 1] = ("unknown %s effect '%s' (rule %s)"):format(kind, k, tostring(t.name))
        end
    end
    return { set_enabled = function() end }
end

-- Walks nested and dotted keys; a known option is a leaf (gradients are tables too).
local function check_config(prefix, t)
    for k, v in pairs(t) do
        local path = prefix .. k
        if options[path] then
            -- ok
        elseif type(v) == "table" then
            check_config(path .. ".", v)
        else
            M.errors[#M.errors + 1] = ("unknown option '%s' in hl.config"):format(path)
        end
    end
end

local DSP = {
    _top     = { "exec_cmd", "exec_raw", "exit", "reload_config", "submap", "pass", "send_shortcut",
                 "send_key_state", "layout", "dpms", "event", "global", "force_renderer_reload",
                 "force_idle", "release_input_capture", "focus", "no_op" },
    window   = { "close", "kill", "signal", "float", "fullscreen", "fullscreen_state", "pseudo", "move",
                 "swap", "center", "cycle_next", "tag", "clear_tags", "toggle_swallow", "pin",
                 "bring_to_top", "alter_zorder", "set_prop", "deny_from_group", "drag", "resize" },
    workspace = { "rename", "change_id", "move", "swap_monitors", "toggle_special" },
    group    = { "toggle", "next", "prev", "active", "move_window", "lock", "lock_active" },
    cursor   = { "move_to_corner", "move" },
}

local MODS = { SUPER = true, SHIFT = true, CTRL = true, CONTROL = true, ALT = true, MOD5 = true }

local function strict(name, fields)
    return setmetatable(fields, {
        __index = function(_, k) error(("hl.%s.%s does not exist in Hyprland 0.57"):format(name, tostring(k)), 2) end,
    })
end

local function make_dsp()
    local t = {}
    for _, n in ipairs(DSP._top) do
        t[n] = function(arg) return { dsp = n, arg = arg } end
    end
    for ns, list in pairs(DSP) do
        if ns ~= "_top" then
            local sub = {}
            for _, n in ipairs(list) do
                sub[n] = function(arg) return { dsp = ns .. "." .. n, arg = arg } end
            end
            t[ns] = strict("dsp." .. ns, sub)
        end
    end
    return strict("dsp", t)
end

local current_submap = "global"

local function check_keys(keys)
    local parts = {}
    for p in keys:gmatch("[^+]+") do parts[#parts + 1] = p:match("^%s*(.-)%s*$") end
    for i = 1, #parts - 1 do
        if not MODS[parts[i]:upper()] then
            M.errors[#M.errors + 1] = ("unknown modifier '%s' in '%s'"):format(parts[i], keys)
        end
    end
    return table.concat(parts, "+"):lower()
end

local hl = {
    dsp = make_dsp(),
    bind = function(keys, action, flags)
        assert(type(keys) == "string", "hl.bind: keys must be a string")
        assert(type(action) == "table" or type(action) == "function", "hl.bind: action must be a dispatcher or function")
        local norm = check_keys(keys)
        local slot = current_submap .. ":" .. norm
        if M.binds[slot] then
            M.errors[#M.errors + 1] = ("duplicate bind '%s' in submap '%s'"):format(keys, current_submap)
        end
        M.binds[slot] = { keys = keys, action = action, flags = flags or {}, submap = current_submap }
        return { set_enabled = function() end, unbind = function() end, remove = function() end }
    end,
    define_submap = function(name, fn)
        local prev = current_submap
        current_submap = name
        M.submaps[name] = true
        fn()
        current_submap = prev
    end,
    dispatch = function(d) assert(type(d) == "table" and d.dsp, "hl.dispatch: expects a dispatcher table") end,
    get_active_window = function() return M.active_window end,
    config = function(t) check_config("", t) end, monitor = function() end,
    env = function(k, v) assert(type(k) == "string" and type(v) == "string", "hl.env: expects two strings") end,
    on = function(event, fn)
        if not rules.events[event] then M.errors[#M.errors + 1] = ("unknown event '%s' in hl.on"):format(tostring(event)) end
        assert(type(fn) == "function", "hl.on: expects a function")
        M.events[#M.events + 1] = { name = event, fn = fn }
    end,
    window_rule = function(t) return check_rule("window_rule", rules.window_props, rules.window_effects, t) end,
    layer_rule = function(t) return check_rule("layer_rule", rules.layer_props, rules.layer_effects, t) end,
    workspace_rule = function() return {} end, curve = function() end, animation = function() end,
    gesture = function() end, device = function() end, exec_cmd = function() end,
}
M.hl = strict("", hl)
return M
