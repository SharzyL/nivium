return function(vim)
  -- No style here: onedark's colorscheme() switches to the light palette on its
  -- own when 'background' is light, and nvim reloads the colorscheme whenever
  -- 'background' changes
  require('onedark').setup({
    highlights = {
      BufferCurrent = { fg = '$fg', bg = '$bg3', fmt = 'bold' },
      BufferCurrentSign = { fg = '$purple', bg = '$bg3', fmt = 'bold' },
      BufferInactive = { fg = '$light_grey', bg = '$bg0' },
      BufferInactiveSign = { bg = '$bg0' },
      BufferTabpageFill = { bg = '$bg0' },

      WinBar = { bg = '$bg3' },
    },
  })
  require('onedark').load({})
end
