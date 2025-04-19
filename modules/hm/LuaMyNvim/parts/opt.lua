return function(vim)
  -- Enables the experimental Lua module loader
  vim.loader.enable()

  -- Enables 24-bit RGB color in the TUI, and set background to dark
  vim.opt.termguicolors = true
  vim.opt.background = 'dark'

  vim.opt.number = true
  vim.opt.cursorline = true

  -- Use 2 spaces forcibly. But vim-sleuth will handle the indent gracefully.
  -- Use the appropriate number of spaces to insert a <Tab>.
  vim.opt.expandtab = true
  vim.opt.tabstop = 2
  vim.opt.shiftwidth = 2
  vim.opt.softtabstop = 2

  vim.opt.textwidth = 80
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

  -- allow formatting of comments with gq
  -- move a comment leader when joining lines
  vim.opt.formatoptions = 'qj'

  -- persist undofile
  vim.opt.undofile = true
end
