-- Editor options (:h option-list). Values checked against Neovim 0.12's options.txt.
local o = vim.opt

o.number = true
o.relativenumber = true
o.cursorline = true
o.signcolumn = 'yes'          -- diagnostics never shift the text sideways
o.scrolloff = 8
o.sidescrolloff = 8
o.wrap = false
o.mouse = 'a'
o.clipboard = 'unnamedplus'   -- system clipboard (wl-clipboard on Wayland)
o.undofile = true
o.updatetime = 250
o.timeoutlen = 400
o.splitright = true
o.splitbelow = true
o.ignorecase = true
o.smartcase = true
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.softtabstop = 4
o.list = true
o.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
o.showmode = false            -- the statusline shows the mode
o.laststatus = 3              -- one statusline for all windows
o.winborder = 'rounded'       -- borders for hover, signature, diagnostics floats
o.pumborder = 'rounded'
o.completeopt = { 'menuone', 'noselect', 'popup', 'fuzzy' }
o.foldlevelstart = 99         -- folds (tree-sitter based where a parser exists) start open
o.termguicolors = true

-- .pl is Prolog here (Neovim would otherwise guess Perl unless the file looks like Prolog).
vim.g.filetype_pl = 'prolog'
