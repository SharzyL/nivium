return function(vim)
  local utils = require('LuaMyNvim/utils')(vim)
  local d = utils.d
  local nmap = utils.nmap
  local map = utils.map

  -- spectre
  require('spectre').setup({})
  map('n', '<leader>S', '<cmd>lua require("spectre").open()<CR>', { desc = 'Open Spectre' })
  map(
    'n',
    '<leader>sw',
    '<cmd>lua require("spectre").open_visual({select_word=true})<CR>',
    { desc = 'Search current word' }
  )
  map('v', '<leader>sw', '<esc><cmd>lua require("spectre").open_visual()<CR>', { desc = 'Search current word' })
  map(
    'n',
    '<leader>sp',
    '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>',
    { desc = 'Search on current file' }
  )
end
