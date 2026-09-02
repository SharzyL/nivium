return function(vim)
  local utils = require('LuaMyNvim/utils')(vim)
  local map = utils.map

  vim.g.barbar_auto_setup = false
  require('barbar').setup({
    icons = {
      filetype = { enabled = false },
      pinned = { filename = true },
    },
  })

  local buffer_kb_opts = { noremap = true, silent = true }
  -- Move to previous/next
  map('n', '<C-,>', '<Cmd>BufferPrevious<CR>', buffer_kb_opts)
  map('n', '<C-.>', '<Cmd>BufferNext<CR>', buffer_kb_opts)
  map('n', '<A-,>', '<Cmd>BufferPrevious<CR>', buffer_kb_opts)
  map('n', '<A-.>', '<Cmd>BufferNext<CR>', buffer_kb_opts)
  -- Re-order to previous/next
  map('n', '<C-<>', '<Cmd>BufferMovePrevious<CR>', buffer_kb_opts)
  map('n', '<C->>', '<Cmd>BufferMoveNext<CR>', buffer_kb_opts)
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
  map('n', '<C-q>', '<Cmd>BufferClose<CR>', buffer_kb_opts)
end
