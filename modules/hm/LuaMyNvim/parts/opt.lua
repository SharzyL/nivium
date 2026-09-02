return function(vim)
  -- Enables the experimental Lua module loader
  vim.loader.enable()

  vim.opt.termguicolors = true

  -- The TUI asks the terminal for its background itself, but the answer only
  -- arrives after the first redraw: the colorscheme is then loaded a second
  -- time and the whole window visibly flips. Both of these are set before any
  -- drawing happens, so the right colorscheme is loaded the first time:
  --   $TERM_THEME_OVERRIDE  what was asked for, where the terminal cannot answer
  --   $TERM_THEME_DETECTED  what the shell found out (see light-mode.nix)
  -- Setting 'background' here also stops the TUI from setting it later, so a
  -- hint that has gone stale stays until the shell refreshes it (`retheme`).
  local hint = os.getenv('TERM_THEME_OVERRIDE')
  if hint ~= 'light' and hint ~= 'dark' then
    hint = os.getenv('TERM_THEME_DETECTED')
  end
  if hint == 'light' or hint == 'dark' then
    vim.opt.background = hint
  end

  vim.opt.number = true
  vim.opt.cursorline = true

  -- Use 2 spaces forcibly. But vim-sleuth will handle the indent gracefully.
  -- Use the appropriate number of spaces to insert a <Tab>.
  vim.opt.expandtab = true
  vim.opt.tabstop = 2
  vim.opt.shiftwidth = 2
  vim.opt.softtabstop = 2

  vim.opt.textwidth = 100
  vim.opt.colorcolumn = '+1'

  vim.opt.cindent = true
  vim.opt.cinkeys:remove({ '0#' }) -- default but no 0#

  -- A List is an ordered sequence of items.
  vim.opt.list = true
  vim.opt.listchars = { trail = '·', tab = '>~' }

  -- Minimal number of screen lines to keep above and below the cursor.
  vim.opt.scrolloff = 5

  -- 200 is more appropriate for which-keys. You can quickly input keys without prompting up
  -- the which-keys panel, or wait 200ms if you forget keymappings.
  vim.opt.timeoutlen = 200
  -- Time in milliseconds to wait for a key code sequence to complete
  vim.opt.ttimeoutlen = 200
  -- use timeout for showing which-keys
  vim.opt.timeout = true

  -- wrap line
  vim.opt.wrap = true

  -- set text width to zero to use the wrap functionality
  vim.opt.tw = 0

  -- set windows split at bottom-right by default
  vim.opt.splitright = true
  vim.opt.splitbelow = true

  -- don't show the '--VISUAL--' '--INSERT--' text
  vim.opt.showmode = false

  -- show chars, selected block in visual mode
  vim.opt.showcmd = true

  -- auto completion on command
  vim.opt.wildmenu = true

  -- ignore case when searching and only on searching
  vim.opt.smartcase = true

  vim.opt.inccommand = 'split'
  vim.opt.completeopt = { 'menuone', 'noselect', 'menu' }
  vim.opt.visualbell = true
  vim.opt.updatetime = 100
  vim.opt.virtualedit = 'block'

  -- screen will not redraw when exec marcro, register
  -- vim.opt.lazyredraw = true

  -- always draw signcolumn, with 1 fixed space to show 2 icon at the same time
  vim.opt.signcolumn = 'yes:1'

  -- enable all the mouse functionality
  vim.opt.mouse = 'a'

  -- use indent as the fold method
  vim.opt.foldmethod = 'indent'
  vim.opt.foldlevel = 99
  vim.opt.foldenable = true

  -- persist undofile
  vim.opt.undofile = true
end
