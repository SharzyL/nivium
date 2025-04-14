return function (vim)
  local utils = require "LuaMyNvim/utils" (vim)
  local map = utils.map

  vim.g.barbar_auto_setup = false
  require('barbar').setup {
    icons = { filetype = { enabled = false } },
  }

  local buffer_kb_opts = { noremap = true, silent = true }
  -- Move to previous/next
  map('n', '<A-,>', '<Cmd>BufferPrevious<CR>', buffer_kb_opts)
  map('n', '<A-.>', '<Cmd>BufferNext<CR>', buffer_kb_opts)
  -- Re-order to previous/next
  map('n', '<A-<>', '<Cmd>BufferMovePrevious<CR>', buffer_kb_opts)
  map('n', '<A->>', '<Cmd>BufferMoveNext<CR>', buffer_kb_opts)
  -- Goto buffer in position...
  map('n', '<A-1>', '<Cmd>BufferGoto 1<CR>', buffer_kb_opts)
  map('n', '<A-2>', '<Cmd>BufferGoto 2<CR>', buffer_kb_opts)
  map('n', '<A-3>', '<Cmd>BufferGoto 3<CR>', buffer_kb_opts)
  map('n', '<A-4>', '<Cmd>BufferGoto 4<CR>', buffer_kb_opts)
  map('n', '<A-5>', '<Cmd>BufferGoto 5<CR>', buffer_kb_opts)
  map('n', '<A-6>', '<Cmd>BufferGoto 6<CR>', buffer_kb_opts)
  map('n', '<A-7>', '<Cmd>BufferGoto 7<CR>', buffer_kb_opts)
  map('n', '<A-8>', '<Cmd>BufferGoto 8<CR>', buffer_kb_opts)
  map('n', '<A-9>', '<Cmd>BufferGoto 9<CR>', buffer_kb_opts)
  map('n', '<A-0>', '<Cmd>BufferLast<CR>', buffer_kb_opts)
  -- Pin/unpin buffer
  map('n', '<A-p>', '<Cmd>BufferPin<CR>', buffer_kb_opts)
  -- Close buffer
  map('n', '<A-w>', '<Cmd>BufferClose<CR>', buffer_kb_opts)
  -- Magic buffer-picking mode
  map('n', '<C-p>', '<Cmd>BufferPick<CR>', buffer_kb_opts)
  -- Sort automatically by...
  map('n', '<leader>bb', '<Cmd>BufferOrderByBufferNumber<CR>', buffer_kb_opts)
  map('n', '<leader>bd', '<Cmd>BufferOrderByDirectory<CR>', buffer_kb_opts)
  map('n', '<leader>bl', '<Cmd>BufferOrderByLanguage<CR>', buffer_kb_opts)
  map('n', '<leader>bw', '<Cmd>BufferOrderByWindowNumber<CR>', buffer_kb_opts)

  require('which-key').setup()
  -- workaround for https://github.com/folke/which-key.nvim/issues/476
  map("n", "<localleader>", function() require("which-key").show "\\" end, { buffer = true })
end
