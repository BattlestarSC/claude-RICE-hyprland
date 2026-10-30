-- Check config/nvim/lua/rice/explorer.lua against the pinned nvim-tree and bufferline sources.
-- Dev-only; needs lua5.4 and checkouts at the commits pinned in lua/rice/plugins.lua:
--
--   git clone https://github.com/nvim-tree/nvim-tree.lua /tmp/nvim-tree
--   git -C /tmp/nvim-tree checkout 9a2e0006d42f292eb3ade7dfdff201a7429a780c
--   git clone https://github.com/akinsho/bufferline.nvim /tmp/bufferline
--   git -C /tmp/bufferline checkout 655133c3b4c3e5e05ec549b9f8cc2894ac6f51b3
--   lua5.4 tests/nvim/check_explorer.lua /tmp/nvim-tree /tmp/bufferline
--
-- Runs explorer.lua with a stub `vim` and stub plugins that record what setup() receives, then
-- checks every option path exists in the plugin's own defaults table (nvim-tree M.d in
-- lua/nvim-tree/config.lua; bufferline's `opts` in lua/bufferline/config.lua), and that the
-- nvim-tree API calls it makes exist.
local tree_dir, tabs_dir = arg[1], arg[2]
assert(tree_dir and tabs_dir, 'usage: lua5.4 tests/nvim/check_explorer.lua <nvim-tree> <bufferline>')

local function read(path)
    local f = assert(io.open(path, 'r'))
    local s = f:read('a')
    f:close()
    return s
end

-- A permissive stub: any field is a callable table, so plugin defaults that call vim.* evaluate.
local function any()
    return setmetatable({}, { __index = function(t, k) local v = any(); rawset(t, k, v); return v end,
                              __call = function() return any() end })
end
local autocmds, keymaps = {}, {}
vim = any()
vim.diagnostic = { severity = { ERROR = 1, WARN = 2, INFO = 3, HINT = 4 } }
vim.api = setmetatable({
    nvim_create_autocmd = function(ev, o) autocmds[#autocmds + 1] = ev end,
    nvim_create_augroup = function() return 1 end,
}, { __index = function() return function() end end })
vim.keymap = { set = function(_, lhs) keymaps[#keymaps + 1] = lhs end }

-- Defaults tables, cut out of the plugin sources.
local function defaults(src, start_pat, end_pat, env)
    local s, e = src:find(start_pat)
    assert(s, 'start of defaults not found: ' .. start_pat)
    local stop = assert(src:find(end_pat, e), 'end of defaults not found')
    local body = 'return {' .. src:sub(e + 1, stop) .. '}'
    local chunk = assert(load(body, 'defaults', 't', setmetatable(env or {}, {
        __index = function(_, k) if _G[k] ~= nil then return _G[k] end return any() end })))
    return chunk()
end
local tree_defaults = defaults(read(tree_dir .. '/lua/nvim-tree/config.lua'),
    'M%.d = {[^\n]*\n', '\n} %-%- config%-default%-end')
local tabs_defaults = defaults(read(tabs_dir .. '/lua/bufferline/config.lua'),
    'local opts = {[^\n]*\n', '\n  }\n', { preset = nil })

-- Stub plugins record their setup() argument.
local got = {}
package.preload['nvim-tree'] = function() return { setup = function(o) got.tree = o end } end
package.preload['bufferline'] = function() return { setup = function(o) got.tabs = o end, go_to = function() end } end
package.preload['nvim-tree.api'] = function()
    return { tree = setmetatable({}, { __index = function() return function() end end }) }
end

dofile('config/nvim/lua/rice/explorer.lua')

local errors = {}
local function check(user, def, path)
    for k, v in pairs(user) do
        local p = path .. '.' .. k
        if def[k] == nil then
            errors[#errors + 1] = 'unknown option ' .. p
        elseif type(v) == 'table' and type(def[k]) == 'table' and #v == 0 and next(def[k]) ~= nil then
            check(v, def[k], p)
        end
    end
end
assert(got.tree, 'explorer.lua did not call nvim-tree setup()')
check(got.tree, tree_defaults, 'nvim-tree')
assert(got.tabs and got.tabs.options, 'explorer.lua did not call bufferline setup({ options = ... })')
check(got.tabs.options, tabs_defaults, 'bufferline.options')

-- Every api.tree.<fn> explorer.lua calls must be defined in nvim-tree's api/impl.lua.
local impl = read(tree_dir .. '/lua/nvim-tree/api/impl.lua')
local used = 0
for name in read('config/nvim/lua/rice/explorer.lua'):gmatch('api%.tree%.([%w_]+)') do
    used = used + 1
    if not impl:find('api%.tree%.' .. name .. '%s*=') then
        errors[#errors + 1] = 'nvim-tree api has no tree.' .. name
    end
end

for _, e in ipairs(errors) do print('FAIL ' .. e) end
if #errors > 0 then os.exit(1) end
print(('ok: nvim-tree and bufferline options valid; %d api calls, %d autocmds, %d keymaps'):format(used, #autocmds, #keymaps))
