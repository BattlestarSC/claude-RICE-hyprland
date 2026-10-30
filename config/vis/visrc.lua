-- vis settings for the rice. Deployed to ~/.config/vis/visrc.lua (the installer backs up an
-- existing file). Your own settings go in ~/.config/vis/local.lua, loaded last if it exists.
-- Option names: vis 0.9 (sam.c option table); also valid on newer snapshots.
require('vis')

-- .pl is SWI-Prolog here, not Perl (vis maps it to both; which one wins is table order).
-- vis 0.9: drop the pattern from perl's list. Newer vis: extension table consulted first.
local ft = vis.ftdetect
if ft and ft.filetypes and ft.filetypes.perl and ft.filetypes.perl.ext then
    for i = #ft.filetypes.perl.ext, 1, -1 do
        if ft.filetypes.perl.ext[i] == '%.pl$' then table.remove(ft.filetypes.perl.ext, i) end
    end
end
if ft and ft.extensions then ft.extensions.pl = 'prolog' end

vis.events.subscribe(vis.events.INIT, function()
    vis:command('set theme rice')
    vis:command('set autoindent on')
    vis:command('set escdelay 20')
end)

vis.events.subscribe(vis.events.WIN_OPEN, function(win) -- luacheck: no unused args
    vis:command('set numbers on')
    vis:command('set relativenumbers on')
    vis:command('set cursorline on')
    vis:command('set colorcolumn 100')
    vis:command('set expandtab on')
    vis:command('set tabwidth 4')
    vis:command('set show-tabs on')
end)

-- ---- Language servers: vis-lspc ---------------------------------------------------------
-- Needs vis >= 0.9 (its communicate API) and the plugin in ~/.config/vis/plugins/vis-lspc
-- (rice-lsp-setup --vis-lspc clones it). Keys: F2 start a server, gd definition, gr references,
-- K hover, Ctrl+Space completion, Space e/n/N diagnostics (see the plugin's README).
local function on_path(bin)
    for dir in (os.getenv('PATH') or ''):gmatch('[^:]+') do
        local f = io.open(dir .. '/' .. bin, 'r')
        if f then f:close(); return true end
    end
    return false
end

local ok, lspc = pcall(require, 'plugins/vis-lspc')
if ok and type(lspc) == 'table' and lspc.ls_map then
    -- haskell (haskell-language-server-wrapper) and caml (ocamllsp) are preconfigured upstream.
    lspc.ls_map.elixir = { name = 'elixir-ls', cmd = 'elixir-ls', roots = { 'mix.exs' } }
    lspc.ls_map.prolog = {
        name = 'swipl',
        cmd = "swipl -g 'use_module(library(lsp_server))' -g 'lsp_server:main' -t halt -- stdio",
    }
    lspc.ls_map.scala = {
        name = 'metals', cmd = 'metals',
        roots = { 'build.sbt', 'build.sc', 'build.mill', '.scala-build' },
    }
    lspc.ls_map.fortran = {
        name = 'fortls', cmd = 'fortls --lowercase_intrinsics', roots = { '.fortls', 'fpm.toml' },
    }
    -- Autostart only what is installed, so opening a file never reports a failed server. (The
    -- Prolog server also needs `swipl pack install lsp_server`; without it, starting fails.)
    for syntax, conf in pairs(lspc.ls_map) do
        if not on_path(conf.cmd:match('^%S+')) then lspc.ls_map[syntax] = nil end
    end
    lspc.highlight_diagnostics = 'range'
    -- Diagnostic colors come from the theme (STYLE_DIAGNOSTIC_*), set once it has loaded.
    vis.events.subscribe(vis.events.INIT, function()
        local L = vis.lexers
        for _, level in ipairs({ 'error', 'warning', 'information', 'hint' }) do
            local style = L['STYLE_DIAGNOSTIC_' .. level:upper()]
            if style then lspc.diagnostic_styles[level] = style end
        end
    end)
end

pcall(require, 'local')
