return function(vim)
  local utils = require('LuaMyNvim/utils')(vim)
  local d = utils.d
  local nmap = utils.nmap

  require('telescope').setup({
    defaults = {
      vimgrep_arguments = {
        'rg',
        '--color=never',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
        '--smart-case',
        '--hidden', -- add this flag to search dotfiles
        '-g=!.git',
        '-g=!.direnv',
      },
    },
    pickers = {
      find_files = {
        find_command = {
          'fd',
          '--type',
          'f',
          '--strip-cwd-prefix',
          '--hidden',
          '--exclude=.git',
          '--exclude=.direnv',
        },
      },
    },
  })
  nmap('<leader>f', function()
    require('telescope.builtin').find_files(require('telescope.themes').get_ivy({ hidden = true }))
  end, d('telescope find_files'))

  nmap('<leader>F', function()
    require('telescope.builtin').find_files(require('telescope.themes').get_ivy({
      hidden = true,
      no_ignore = true,
    }))
  end, d('telescope find_files (include hidden)'))

  nmap('<C-f>', function()
    require('telescope.builtin').live_grep(require('telescope.themes').get_ivy())
  end, d('telescope live grep'))

  nmap('<leader>p', function()
    require('telescope.builtin').buffers(require('telescope.themes').get_ivy())
  end, d('telescope find buffer'))
end
