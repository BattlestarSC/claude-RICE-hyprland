-- Keymaps beyond Neovim's defaults. Built in since 0.11 (:h lsp-defaults): K hover, grn rename,
-- gra code action, grr references, gri implementation, grt type definition, gO symbols,
-- Ctrl+S signature help (insert), [d / ]d previous/next diagnostic.
local map = vim.keymap.set

map('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })
map('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
map('n', '<leader>f', function() vim.lsp.buf.format({ async = true }) end, { desc = 'Format buffer' })
map('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Diagnostics at cursor' })
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostics list' })
map('n', '<leader>h', function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, { desc = 'Toggle inlay hints' })
map('n', '<C-h>', '<C-w>h', { desc = 'Window left' })
map('n', '<C-j>', '<C-w>j', { desc = 'Window down' })
map('n', '<C-k>', '<C-w>k', { desc = 'Window up' })
map('n', '<C-l>', '<C-w>l', { desc = 'Window right' })
