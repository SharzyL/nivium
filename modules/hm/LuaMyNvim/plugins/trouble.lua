return function(vim)
  local utils = require('LuaMyNvim/utils')(vim)
  local d = utils.d
  local map = utils.map

  require('trouble').setup({})
  map('n', '<leader>xx', function()
    require('trouble').toggle()
  end, d('trouble toggle'))

  map('n', '<leader>xw', function()
    require('trouble').toggle('workspace_diagnostics')
  end, d('trouble toggle workspace_diagnostics'))

  map('n', '<leader>xd', function()
    require('trouble').toggle('document_diagnostics')
  end, d('trouble toggle document_diagnostics'))

  map('n', '<leader>xq', function()
    require('trouble').toggle('quickfix')
  end, d('trouble toggle quickfix'))

  map('n', '<leader>xl', function()
    require('trouble').toggle('loclist')
  end, d('trouble toggle loclist'))

  map('n', 'gR', function()
    require('trouble').toggle('lsp_references')
  end, d('trouble toggle lsp_references'))

  map('n', '[x', function()
    require('trouble').previous({ skip_groups = true, jump = true })
  end, d('Next trouble'))

  map('n', ']x', function()
    require('trouble').next({ skip_groups = true, jump = true })
  end, d('Previous trouble'))
end
