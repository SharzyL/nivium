return function(vim)
  require('notify').setup({
    top_down = false,
    stages = 'static',
    timeout = 5000,
    minimum_width = 20,
    render = 'compact',
  })
end
