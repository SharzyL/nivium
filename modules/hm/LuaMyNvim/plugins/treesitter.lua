return function(vim)
  require('nvim-treesitter').setup({
    highlight = { enable = true },
    incremental_selection = { enable = true },
    indent = { enable = true },
    matchup = { enable = true },
  })

  vim.opt.foldmethod = 'expr'
  vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
end
