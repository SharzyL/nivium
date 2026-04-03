return function(vim)
  local utils = require('LuaMyNvim/utils')(vim)

  -- vimtex config
  vim.g.vimtex_view_method = 'zathura'
  vim.g.vimtex_format_enabled = 1
  vim.g.vimtex_quickfix_mode = 0
  vim.g.vimtex_quickfix_ignore_filters = {
    'Overfull',
    'Underfull',
    'Missing character',
  }

  local vimtex_trouble_group = vim.api.nvim_create_augroup('VimtexTroubleIntegration', { clear = true })

  vim.api.nvim_create_autocmd('User', {
    group = vimtex_trouble_group,
    pattern = 'VimtexEventCompileFailed',
    callback = function()
      require('trouble').open('qflist')
    end,
    desc = 'Open Trouble on Vimtex compile failure',
  })

  vim.api.nvim_create_autocmd('User', {
    group = vimtex_trouble_group,
    pattern = 'VimtexEventCompileSuccess',
    callback = function()
      require('trouble').close('qflist')
    end,
    desc = 'Close Trouble on Vimtex compile success',
  })

  local vimtex_fidget_group = vim.api.nvim_create_augroup('VimtexFidget', { clear = true })
  local compile_handle = nil

  -- Create or update the Fidget progress handle
  local function show_progress(msg)
    local ok, progress = pcall(require, 'fidget.progress')
    if not ok then
      return
    end

    if compile_handle then
      -- Update existing handle message without creating a new one
      compile_handle.message = msg
    else
      -- Create a new handle
      compile_handle = progress.handle.create({
        title = 'Vimtex',
        message = msg,
        lsp_client = { name = 'LaTeX' },
      })
    end
  end

  -- Finish the progress handle (Fidget will show the message briefly then fade out)
  local function finish_progress(msg)
    if compile_handle then
      compile_handle.message = msg
      compile_handle:finish()
      compile_handle = nil
    end
  end

  -- ==========================================
  -- 2. Vimtex Events Integration
  -- ==========================================
  vim.api.nvim_create_autocmd('User', {
    group = vimtex_fidget_group,
    pattern = 'VimtexEventCompileStarted',
    callback = function()
      show_progress('Starting compiler...')
    end,
  })

  vim.api.nvim_create_autocmd('User', {
    group = vimtex_fidget_group,
    pattern = 'VimtexEventCompileSuccess',
    callback = function()
      finish_progress('✅ Success')
    end,
  })

  vim.api.nvim_create_autocmd('User', {
    group = vimtex_fidget_group,
    pattern = 'VimtexEventCompileFailed',
    callback = function()
      finish_progress('❌ Failed')
    end,
  })
end
