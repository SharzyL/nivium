return function(vim)
  local utils = require('LuaMyNvim/utils')(vim)
  local d = utils.d
  local nmap = utils.nmap

  -- better quickfix
  require('bqf').setup({
    auto_resize_height = true,
    preview = {
      win_height = 5,
    },
  })

  nmap('[q', ':cprevious<CR>', d('previous quicifix'))
  nmap(']q', ':cnext<CR>', d('next quickfix'))
end
