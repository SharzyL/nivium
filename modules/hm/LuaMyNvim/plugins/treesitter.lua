return function(vim)
  local utils = require('LuaMyNvim/utils')(vim)
  local d = utils.d
  local nmap = utils.nmap

  require('nvim-treesitter').setup({
    highlight = { enable = true },
    incremental_selection = { enable = true },
    indent = { enable = true },
    matchup = { enable = true },
  })

  vim.opt.foldmethod = 'expr'
  vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'python', 'latex', 'cmake', 'era', 'hocon' },
    callback = function(args)
      -- era, hocon and latex parsers are only installed with nivium.nvim.extraLangs.<lang>.enable
      if vim.treesitter.language.add(vim.treesitter.language.get_lang(args.match) or args.match) then
        vim.treesitter.start()
      end
    end,
  })

  require('treesitter-context').setup({
    enable = true,
  })

  nmap('[c', function()
    require('treesitter-context').go_to_context(vim.v.count1)
  end, d('Jump to context start'))
end
