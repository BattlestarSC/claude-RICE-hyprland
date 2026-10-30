-- rice: Neovim (>= 0.12). Modules in lua/rice/; your own additions in lua/local.lua (optional,
-- never touched by the installer). Colors: colors/rice.lua, generated from the palette.
-- Plugins are installed by Neovim's built-in vim.pack on first start (needs git and network);
-- tree-sitter parsers are then compiled once (needs tree-sitter-cli and a C compiler).
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- vim.pack, vim.lsp.config and nvim-treesitter's main branch need 0.12: on anything older load
-- only the colors and say why, instead of failing with a stack trace.
if vim.fn.has('nvim-0.12') == 0 then
    pcall(vim.cmd.colorscheme, 'rice')
    vim.schedule(function()
        vim.notify('rice: this config needs Neovim 0.12 or newer; loaded colors only', vim.log.levels.WARN)
    end)
    return
end

require('rice.options')
require('rice.keymaps')
require('rice.plugins')
require('rice.treesitter')
require('rice.lsp')
require('rice.statusline')

pcall(vim.cmd.colorscheme, 'rice')
pcall(require, 'local')
