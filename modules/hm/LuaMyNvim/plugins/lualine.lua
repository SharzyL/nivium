return function (vim)
  require('lualine').setup {
    options = {
      disabled_filetypes = { 'neo-tree', 'qf' },
      icons_enabled = false,
      theme = 'iceberg',
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
          end
        },
      }
    },
    sections = {
      lualine_c = {
        {
          'filename',
          path = 1
        }
      }
    }
  }
end
