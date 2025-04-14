return function (vim)
  local utils = require "LuaMyNvim/utils" (vim)
  local d = utils.d
  local nmap = utils.nmap
  local map = utils.map

  require('toggleterm').setup {}
  -- float terminal
  map('t', '<C-\\>', [[<C-\><C-n>:ToggleTerm<CR>]], d("ToggleTerm"))
  -- horizontal terminal
  nmap('<C-\\>', ':ToggleTerm direction=horizontal<CR>', d("ToggleTerm horizontal"))
  nmap('|', ':ToggleTerm direction=float<CR>', d("ToggleTerm float"))
  map('t', '<A-;>', [[<C-\><C-n>]])
  -- terminal windows movement
  map('t', '<C-k>', [[<C-\><C-n><C-w>k]])
  map('t', '<C-l>', [[<C-\><C-n><C-w>l]])
  map('t', '<C-h>', [[<C-\><C-n><C-w>h]])
end
