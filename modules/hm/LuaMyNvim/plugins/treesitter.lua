return function(vim)
  require('nvim-treesitter.configs').setup({
    highlight = { enable = true },
    incremental_selection = { enable = true },
    indent = { enable = true },
    matchup = { enable = true },
  })

  vim.opt.foldmethod = 'expr'
  vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'
end
