return function(vim)
  local utils = require('LuaMyNvim/utils')(vim)
  local d = utils.d
  local map = utils.map

  require('gitsigns').setup({
    on_attach = function(_)
      local gs = package.loaded.gitsigns

      -- Navigation
      map('n', ']h', function()
        if vim.wo.diff then
          return ']c'
        end
        vim.schedule(function()
          gs.next_hunk()
        end)
        return '<Ignore>'
      end, { expr = true, desc = 'next hunk' })

      map('n', '[h', function()
        if vim.wo.diff then
          return '[c'
        end
        vim.schedule(function()
          gs.prev_hunk()
        end)
        return '<Ignore>'
      end, { expr = true, desc = 'prev hunk' })

      -- Actions
      map('n', '<leader>gs', gs.stage_hunk, d('stage hunk'))
      map('n', '<leader>gr', gs.reset_hunk, d('reset hunk'))
      map('n', '<leader>gu', gs.undo_stage_hunk, d('undo stage hunk'))
      map('v', '<leader>gs', function()
        gs.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
      end, d('stage hunk'))
      map('v', '<leader>gr', function()
        gs.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
      end, d('reset hunk'))
      map('n', '<leader>gS', gs.stage_buffer, d('stage buffer'))
      map('n', '<leader>gR', gs.reset_buffer, d('reset buffer'))
      map('n', '<leader>gp', gs.preview_hunk, d('preview hunk'))
      map('n', '<leader>gb', function()
        gs.blame_line({ full = true })
      end, d('blame line'))
      map('n', '<leader>gB', gs.toggle_current_line_blame, d('toggle blame cur line'))
      map('n', '<leader>gd', gs.diffthis, d('diff this'))
      map('n', '<leader>gt', gs.toggle_deleted, d('toggle deleted'))

      -- Text object
      map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', d('select hunk'))
    end,
  })
end
