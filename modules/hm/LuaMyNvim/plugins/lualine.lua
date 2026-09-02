return function(vim)
  -- The iceberg theme comes in a light and a dark variant. Naming the variant
  -- explicitly (rather than letting 'iceberg' choose) matters because the theme
  -- is resolved when setup() runs, while the terminal's answer about its
  -- background only arrives just after startup: re-running setup with a cached
  -- 'iceberg' module would keep handing back the variant picked the first time.
  local function configure()
    require('lualine').setup({
      options = {
        disabled_filetypes = { 'neo-tree', 'qf' },
        icons_enabled = false,
        theme = 'iceberg_' .. vim.opt.background:get(),
        component_separators = { left = '|', right = '|' },
        section_separators = { left = '', right = '' },
      },
      winbar = {
        lualine_c = {
          {
            function()
              return require('nvim-navic').get_location()
            end,
            cond = function()
              return require('nvim-navic').is_available()
            end,
          },
        },
      },
      sections = {
        lualine_c = {
          {
            'filename',
            path = 1,
          },
        },
      },
    })
  end

  configure()

  vim.api.nvim_create_autocmd('OptionSet', {
    pattern = 'background',
    callback = configure,
    desc = 'follow the terminal background into the statusline theme',
  })
end
