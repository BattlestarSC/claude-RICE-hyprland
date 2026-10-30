-- File explorer on the left (nvim-tree) and buffer tabs on top (bufferline), the classic IDE
-- layout. Options: nvim-tree v1.19.0 lua/nvim-tree/config.lua, bufferline v4.9.1 doc; checked by
-- tests/nvim/check_explorer.lua. Colors: NvimTree* groups in colors/rice.lua; bufferline derives
-- its colors from the colorscheme.
local ok_tree, tree = pcall(require, 'nvim-tree')
local ok_tabs, tabs = pcall(require, 'bufferline')
if not ok_tree then return end   -- plugins not installed yet (first start without network)

tree.setup({
    hijack_cursor = true,               -- cursor stays on the file name
    sync_root_with_cwd = true,
    view = { width = 32 },
    renderer = {
        group_empty = true,             -- a/b/c on one line when the folders hold nothing else
        highlight_git = 'name',         -- modified files tinted, as well as marked
        root_folder_label = ':~:s?$?/..?',
        indent_markers = { enable = true },
        icons = { git_placement = 'after' },
    },
    update_focused_file = { enable = true },   -- the tree follows the file you are editing
    diagnostics = { enable = true, show_on_dirs = true },
    modified = { enable = true },
    filters = { dotfiles = false, git_ignored = false },
    actions = { open_file = { quit_on_open = false } },
})

if ok_tabs then
    tabs.setup({
        options = {
            numbers = function(o) return o.ordinal .. '.' end,   -- "1. file", "2. file"
            diagnostics = 'nvim_lsp',
            separator_style = 'thin',
            show_close_icon = false,
            always_show_bufferline = true,
            offsets = { { filetype = 'NvimTree', text = 'File Explorer', text_align = 'left', separator = true } },
        },
    })
end

local api = require('nvim-tree.api')

-- Startup: `nvim dir` opens the tree on its own (hijack_directories). `nvim` alone opens it with
-- focus; `nvim file` opens it beside the file, focus on the file, unless the window is narrow or
-- the file is a git message (EDITOR=nvim for commits should not show a sidebar).
vim.api.nvim_create_autocmd('VimEnter', {
    group = vim.api.nvim_create_augroup('rice-explorer', { clear = true }),
    callback = function(ev)
        local name = ev.file
        if vim.fn.isdirectory(name) == 1 then return end
        if name == '' and vim.bo[ev.buf].buftype == '' then
            api.tree.open()
        elseif vim.fn.filereadable(name) == 1 and vim.o.columns >= 120
            and not name:match('/%.git/') and not name:match('^%.git/') then
            api.tree.toggle({ focus = false, find_file = true })
        end
    end,
})

-- :q in the last editing window also closes the tree, instead of leaving it alone on screen.
vim.api.nvim_create_autocmd('QuitPre', {
    group = vim.api.nvim_create_augroup('rice-explorer-quit', { clear = true }),
    callback = function()
        local editing = 0
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local cfg = vim.api.nvim_win_get_config(win)
            if cfg.relative == '' and vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= 'NvimTree' then
                editing = editing + 1
            end
        end
        if editing == 1 then api.tree.close() end
    end,
})

local map = vim.keymap.set
map('n', '<leader>e', function() api.tree.toggle({ find_file = true }) end, { desc = 'File explorer' })
map('n', '<S-h>', '<cmd>bprevious<CR>', { desc = 'Previous buffer' })
map('n', '<S-l>', '<cmd>bnext<CR>', { desc = 'Next buffer' })
map('n', '<leader>x', '<cmd>bprevious | bdelete #<CR>', { desc = 'Close buffer, keep the window' })
if ok_tabs then
    for i = 1, 9 do
        map('n', '<leader>' .. i, function() tabs.go_to(i, true) end, { desc = 'Buffer ' .. i })
    end
end
