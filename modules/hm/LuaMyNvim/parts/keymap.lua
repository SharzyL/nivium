return function(vim)
  local utils = require('LuaMyNvim/utils')(vim)
  local d = utils.d
  local nmap = utils.nmap
  local map = utils.map

  ------------------------
  -- keymaps
  ------------------------

  vim.g.mapleader = ' '
  vim.g.maplocalleader = '\\'

  -- save quickly
  nmap('<leader>w', ':w<CR>', d('Save buffer'))
  nmap('<leader>q', ':q<CR>', d('Quit'))

  -- shut down the search high light
  nmap('<leader> ', ':nohlsearch<CR>', d('Close search highlight'))

  nmap('<leader>i', ':Inspect<CR>', d('Inspect node'))

  --- move around the window
  nmap('<leader>k', '<C-w>k', d('Jump to window above'))
  nmap('<leader>j', '<C-w>j', d('Jump to window below'))
  nmap('<leader>l', '<C-w>l', d('Jump to the left window'))
  nmap('<leader>h', '<C-w>h', d('Jump to the right window'))
  nmap('<leader>p', '<C-w>p', d('Jump to the previous window'))

  -- resize the window
  nmap('<C-S-up>', ':res +5<CR>', d('Extend the upper boundary of the current window'))
  nmap('<C-S-down>', ':res -5<CR>', d('Extend the lower boundary of the current window'))
  nmap('<C-S-right>', ':vertical resize-5<CR>', d('Extend the right boundary of the current window'))
  nmap('<C-S-left>', ':vertical resize+5<CR>', d('Extend the right boundary of the current window'))

  -- text object of entire buffer
  map({ 'x', 'o' }, 'A', ':<C-U>normal! ggVG<CR>', d('Entire buffer'))
end
