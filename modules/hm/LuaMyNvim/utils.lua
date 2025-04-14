return function(vim)
  local function d(text)
    return { desc = text }
  end

  -- map create a new mapping
  -- @param mode specify vim mode
  -- @param lhs specify the new keymap
  -- @param rhs specify the keymap or commands
  -- @param opts setting options. Default: { noremap = true, silent = true, expr = false }
  local function map(mode, lhs, rhs, opts)
    local options = {
      noremap = true,
      silent = true,
      expr = false,
    }
    if opts then
      options = vim.tbl_extend('force', options, opts)
    end
    if type(rhs) == 'function' then
      options.callback = rhs
      rhs = ''
    end
    local stat, error = pcall(vim.keymap.set, mode, lhs, rhs, options)
    if not stat then
      vim.notify(error, vim.log.levels.ERROR, {
        title = 'keymap',
      })
    end
  end

  -- nmap create a new mapping in normal mode
  -- @param lhs specify the new keymap
  -- @param rhs specify the keymap or commands
  -- @param opts setting options. Default: { noremap = true, silent = true, eval = false }
  local function nmap(lhs, rhs, opts)
    map('n', lhs, rhs, opts)
  end

  return { d = d, map = map, nmap = nmap }
end
