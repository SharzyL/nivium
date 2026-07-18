return function(vim)
  -- Emuera ERB, not Ruby eRuby. `.erb` is ambiguous, so disambiguate by
  -- content (Ruby templates contain `<%` tags); `.erh` is always Emuera.
  -- Emuera files use uppercase extensions, so match case-insensitively via
  -- patterns (which also take precedence over the builtin `erb`->eruby).
  local function detect_erb(_, bufnr)
    for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)) do
      if line:find('<%', 1, true) then
        return 'eruby'
      end
    end
    return 'era'
  end

  vim.filetype.add({
    filename = { ['.envrc'] = 'bash' },
    pattern = {
      ['.*%.[eE][rR][hH]'] = 'era',
      ['.*%.[eE][rR][bB]'] = detect_erb,
    },
  })

  vim.api.nvim_create_augroup('EraFileType', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = 'EraFileType',
    pattern = 'era',
    callback = function()
      vim.opt_local.commentstring = ';%s'
    end,
  })

  -- era-ls marks Emuera builtins with the LSP `defaultLibrary` modifier, but
  -- colourschemes leave the `@lsp.typemod.*.defaultLibrary` groups unstyled, so
  -- builtins fall back to the plain function/variable colour. Link the era-
  -- scoped groups to the (distinctly coloured) *.builtin groups the tree-sitter
  -- grammar already uses, so both highlight layers agree. Re-applied on every
  -- ColorScheme load (which clears highlights), and once now via vim.schedule
  -- (deferred so it runs after the startup colourscheme has loaded).
  local function era_builtin_highlights()
    vim.api.nvim_set_hl(0, '@lsp.typemod.function.defaultLibrary.era', { link = '@function.builtin' })
    vim.api.nvim_set_hl(0, '@lsp.typemod.method.defaultLibrary.era', { link = '@function.builtin' })
    vim.api.nvim_set_hl(0, '@lsp.typemod.variable.defaultLibrary.era', { link = '@variable.builtin' })
  end
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = 'EraFileType',
    callback = era_builtin_highlights,
  })
  vim.schedule(era_builtin_highlights)

  vim.api.nvim_create_augroup('TypstFileType', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = 'TypstFileType',
    pattern = 'typst',
    callback = function()
      vim.opt_local.indentkeys:remove({ '0#' })
    end,
  })

  vim.api.nvim_create_augroup('TextualFileType', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = 'TextualFileType',
    pattern = { 'typst', 'tex', 'plaintex', 'markdown' },
    callback = function()
      vim.opt_local.linebreak = true
      vim.opt_local.spell = true
      vim.opt.spelllang = { 'en_us', 'cjk' }
      vim.opt_local.formatoptions:append({ 't', 'n' })
      vim.opt_local.textwidth = 100
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
