return function (vim)
  require('onedark').setup {
    highlights = {
      BufferCurrent = { fg = '$fg', bg = '$bg3', fmt = 'bold'},
      BufferCurrentSign = { fg = '$purple', bg = '$bg3', fmt = 'bold'},
      BufferInactive = { fg = '#848b98', bg = '$bg0' },
      BufferInactiveSign = { bg = '$bg0' },
      BufferTabpageFill = { bg = '$bg0' },

      WinBar = { bg = '$bg3' },
    }
  }
  require('onedark').load {}
end
