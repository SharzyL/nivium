return function(vim)
  vim.filetype.add({ filename = { ['.envrc'] = 'bash' } })

  vim.api.nvim_create_augroup('TypstFileType', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = 'TypstFileType',
    pattern = 'typst',
    callback = function()
      vim.opt_local.indentkeys:remove({ '0#' })
      vim.opt_local.linebreak = true
      vim.opt_local.spell = true
    end,
  })

  vim.api.nvim_create_autocmd({ 'FileType' }, {
    pattern = { 'rust', 'c', 'cpp', 'nix' },
    callback = function()
      -- vim.opt_local.textwidth = 80
    end,
  })

  vim.api.nvim_create_autocmd('BufRead', {
    pattern = '*.v',
    callback = function()
      if vim.fn.filereadable(vim.fn.getcwd() .. '/_CoqProject') == 1 then
        vim.bo.filetype = 'coq'
      end
    end,
  })
end
