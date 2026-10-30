-- Language servers through Neovim's built-in client (vim.lsp.config / vim.lsp.enable, 0.11+),
-- with server definitions from nvim-lspconfig. A server is enabled only if its executable is on
-- PATH, so a missing one never produces errors; install them with `rice-lsp-setup`.
local servers = {
    'hls',        -- Haskell: haskell-language-server (pacman)
    'prolog_ls',  -- SWI-Prolog: swipl + the lsp_server pack
    'metals',     -- Scala: Metals (Coursier)
    'ocamllsp',   -- OCaml: ocaml-lsp-server (opam)
    'fortls',     -- Fortran: fortls (pipx)
    'elixirls',   -- Elixir: ElixirLS (release in ~/.local); falls back to Expert below
    'texlab',     -- LaTeX and BibTeX: texlab (pacman, office group)
}

local function available(name)
    local cfg = vim.lsp.config[name]
    local cmd = cfg and cfg.cmd
    return type(cmd) == 'table' and vim.fn.executable(cmd[1]) == 1
end

for _, name in ipairs(servers) do
    if available(name) then vim.lsp.enable(name) end
end
-- Expert is the Elixir team's official server (pre-1.0 in 2026); used only without ElixirLS.
if not available('elixirls') and available('expert') then vim.lsp.enable('expert') end

vim.diagnostic.config({
    severity_sort = true,
    underline = true,
    update_in_insert = false,
    virtual_text = { spacing = 2, prefix = '●' },
    float = { source = 'if_many' },
    signs = { text = {
        [vim.diagnostic.severity.ERROR] = '󰅚',
        [vim.diagnostic.severity.WARN] = '󰀪',
        [vim.diagnostic.severity.INFO] = '󰋽',
        [vim.diagnostic.severity.HINT] = '󰌶',
    } },
})

vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('rice-lsp', { clear = true }),
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then return end
        -- Built-in completion menu, opening as you type (server trigger characters).
        if client:supports_method('textDocument/completion') then
            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
        end
        if client:supports_method('textDocument/inlayHint') then
            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
        end
        -- Highlight other uses of the symbol under the cursor.
        if client:supports_method('textDocument/documentHighlight') then
            local group = vim.api.nvim_create_augroup('rice-lsp-highlight-' .. ev.buf, { clear = true })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                group = group, buffer = ev.buf, callback = vim.lsp.buf.document_highlight })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                group = group, buffer = ev.buf, callback = vim.lsp.buf.clear_references })
        end
    end,
})
