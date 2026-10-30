-- Plugins via Neovim's built-in vim.pack (0.12), pinned to exact commits so every machine gets
-- the same code. Update deliberately: bump the hashes here (vim.pack.update() would move past
-- them only until the next start). Lockfile: ~/.config/nvim/nvim-pack-lock.json (written by vim.pack).
vim.pack.add({
    -- Parser installer + highlight/fold/indent queries for 300+ languages (main branch).
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter',
      version = 'a2f694478be07f89c2d03cc17858a8745a400c4b' },
    -- Server definitions (lsp/<name>.lua) consumed by vim.lsp.enable().
    { src = 'https://github.com/neovim/nvim-lspconfig',
      version = '7d120778543b876b5a1e216e4ae9f1cb0b88a01b' },
    -- File explorer sidebar (v1.19.0, needs Nvim >= 0.10) and its Nerd Font file icons.
    { src = 'https://github.com/nvim-tree/nvim-tree.lua',
      version = '9a2e0006d42f292eb3ade7dfdff201a7429a780c' },
    { src = 'https://github.com/nvim-tree/nvim-web-devicons',
      version = 'ec309a0eaff6ea967e58c275996155ab5c16938d' },
    -- Buffer tabs across the top, offset over the explorer (v4.9.1).
    { src = 'https://github.com/akinsho/bufferline.nvim',
      version = '655133c3b4c3e5e05ec549b9f8cc2894ac6f51b3' },
}, { confirm = false })
