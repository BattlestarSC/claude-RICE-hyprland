-- A small statusline without plugins: mode, file and flags, diagnostic counts, attached LSP
-- servers, filetype, position.
local modes = {
    n = 'NORMAL', i = 'INSERT', v = 'VISUAL', V = 'V-LINE', ['\22'] = 'V-BLOCK', c = 'COMMAND',
    R = 'REPLACE', t = 'TERMINAL', s = 'SELECT', S = 'S-LINE',
}

function _G.rice_statusline()
    local mode = modes[vim.api.nvim_get_mode().mode:sub(1, 1)] or vim.api.nvim_get_mode().mode
    local counts = vim.diagnostic.count(0)
    local diag = {}
    for sev, icon in pairs({ [1] = '󰅚 ', [2] = '󰀪 ', [3] = '󰋽 ', [4] = '󰌶 ' }) do
        if (counts[sev] or 0) > 0 then table.insert(diag, icon .. counts[sev]) end
    end
    local clients = vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({ bufnr = 0 }))
    return table.concat({
        ' ', mode, '  %f%m%r',
        '%=',
        table.concat(diag, ' '),
        #clients > 0 and ('  󰒋 ' .. table.concat(clients, ',')) or '',
        '  %y  %l:%c ',
    })
end

vim.o.statusline = '%!v:lua.rice_statusline()'
