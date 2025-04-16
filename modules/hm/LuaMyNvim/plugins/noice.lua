return function (vim)
  require('noice').setup {
    cmdline = {
      view = "cmdline",
    },
    messages = {
      view = "messages",
    },
  }
end
