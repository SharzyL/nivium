return function (vim)
  local utils = require "LuaMyNvim/utils" (vim)
  local d = utils.d
  local nmap = utils.nmap

  require('neo-tree').setup {
    window = {
      position = "left",
      width = 30,
    },
    source_selector = {
      winbar = true,
    }
  }
  nmap('gl', ':Neotree source=filesystem reveal<CR>', d('Neotree toggle reveal'))
  nmap('gtf', ':Neotree source=filesystem toggle<CR>', d("Neotree filesystem toggle"))
  nmap('gtb', ':Neotree source=buffers toggle<CR>', d("Neotree buffers toggle"))
  nmap('gtg', ':Neotree source=git toggle<CR>', d("Neotree git toggle"))
end
