return function(vim)
  local utils = require('LuaMyNvim/utils')(vim)
  local d = utils.d
  local map = utils.map

  require('nvim-autopairs').setup({
    enable_check_bracket_line = true,
  })

  require('smartyank').setup({
    highlight = {
      timeout = 400,
    },
  })

  map({ 'n', 'x' }, 's', '<Plug>(leap-forward)')
  map({ 'n', 'x' }, 'S', '<Plug>(leap-backward)')
  map('n', 'gs', '<Plug>(leap-from-window)')
  map({ 'o' }, 'z', '<Plug>(leap-forward)')
  map({ 'o' }, 'Z', '<Plug>(leap-backward)')

  require('nvim-navic').setup({
    highlight = true,
    lsp = {
      auto_attach = true,
    },
  })

  require('nvim-navbuddy').setup({
    lsp = {
      auto_attach = true,
    },
  })
  map('n', '<leader>a', require('nvim-navbuddy').open, d('open navbuddy'))

  -- indent blank line
  require('ibl').setup({})

  require('Comment').setup({})

  require('fidget').setup({})

  require('nvim-lastplace').setup({
    lastplace_ignore_buftype = { 'quickfix', 'nofile', 'help' },
    lastplace_ignore_filetype = { 'gitcommit', 'gitrebase', 'svn', 'hgcommit' },
    lastplace_open_folds = true,
  })

  require('scrollbar').setup({
    excluded_buftypes = {
      'terminal',
    },
    excluded_filetypes = {
      'prompt',
      'TelescopePrompt',
      'noice',
      'Git',
    },
    handlers = {
      cursor = false,
    },
  })
end
