-- Load Hyprland config modules against tests/lua/hl_stub.lua and exercise every bind.
-- Usage: lua5.4 tests/lua/run.lua config/hypr/conf/binds.lua [...]
-- Exit status 1 on any error. (Hyprland embeds Lua 5.5; 5.4 is syntax-compatible for this code.)

package.path = "tests/lua/?.lua;" .. package.path
local stub = require("hl_stub")
hl = stub.hl

local failed = false
for _, file in ipairs(arg) do
    local ok, err = pcall(dofile, file)
    if not ok then
        print("FAIL load " .. file .. ": " .. tostring(err))
        failed = true
    end
end

-- Call every function bind under several window states so per-keypress logic runs too.
local states = {
    { name = "no window" },
    { name = "tiled", window = { floating = false } },
    { name = "floating", window = { floating = true } },
    { name = "group 1/3", window = { floating = false, group = { size = 3, current_index = 1 } } },
    { name = "group 3/3", window = { floating = false, group = { size = 3, current_index = 3 } } },
}
local count = 0
for _, b in pairs(stub.binds) do
    count = count + 1
    if type(b.action) == "function" then
        for _, s in ipairs(states) do
            stub.active_window = s.window
            local ok, err = pcall(b.action)
            if not ok then
                print(("FAIL bind '%s' (%s): %s"):format(b.keys, s.name, err))
                failed = true
            end
        end
    end
end

for _, e in ipairs(stub.errors) do
    print("FAIL " .. e)
    failed = true
end

if failed then os.exit(1) end
print(("OK: %d binds, submaps: %s"):format(count, table.concat((function()
    local t = {} for k in pairs(stub.submaps) do t[#t + 1] = k end table.sort(t) return t end)(), ", ")))
