-- Tree-sitter: parsers for the target languages, highlighting for every filetype that has one.
-- Prolog has no parser in nvim-treesitter; Neovim's built-in regex syntax (syntax/prolog.vim)
-- highlights it instead, automatically.
local languages = {
    'elixir', 'heex', 'eex', 'haskell', 'scala', 'ocaml', 'ocaml_interface', 'fortran',
    -- everyday files
    'bash', 'lua', 'vim', 'vimdoc', 'query', 'markdown', 'markdown_inline', 'json', 'toml',
    'yaml', 'diff', 'gitcommit', 'regex',
}

-- Compiling parsers needs tree-sitter-cli and a C compiler; without them, skip quietly
-- (regex highlighting still works) and say why once.
local ok, ts = pcall(require, 'nvim-treesitter')
if ok then
    if vim.fn.executable('tree-sitter') == 1 and (vim.fn.executable('cc') == 1 or vim.fn.executable('gcc') == 1) then
        ts.install(languages)   -- asynchronous; a no-op for parsers already installed
    else
        vim.schedule(function()
            vim.notify('rice: install tree-sitter-cli and gcc to build tree-sitter parsers', vim.log.levels.WARN)
        end)
    end
end

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('rice-treesitter', { clear = true }),
    callback = function(ev)
        local lang = vim.treesitter.language.get_lang(ev.match)
        if not lang or not pcall(vim.treesitter.language.add, lang) then return end
        if pcall(vim.treesitter.start, ev.buf, lang) then
            vim.wo[0][0].foldmethod = 'expr'
            vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        end
    end,
})
