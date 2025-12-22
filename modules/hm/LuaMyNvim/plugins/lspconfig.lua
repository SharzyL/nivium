return function(vim, lsp_autostart)
  local utils = require('LuaMyNvim/utils')(vim)
  local d = utils.d
  local map = utils.map

  -- lsp
  local servers = {
    gopls = {},
    rust_analyzer = {},
    clangd = {},
    nil_ls = {
      settings = {
        ['nil'] = {
          formatting = { command = { 'nixpkgs-fmt' } },
          nix = { flake = { autoArchive = true } },
        },
      },
    },
    texlab = {},
    pyright = {
      settings = {
        -- Using Ruff's import organizer
        pyright = { disableOrganizeImports = true },
      },
    },
    ruff = {
      init_options = {
        lint = { enable = false },
      },
    },
    lua_ls = {},
    ts_ls = {},
    jsonls = {
      cmd = { 'vscode-json-languageserver', '--stdio' },
    },
    yamlls = {
      settings = { yaml = { keyOrdering = false } },
    },
    beancount = {
      init_options = { journal_file = '~/ws/beancount/root.beancount' },
    },
    efm = {
      init_options = { documentFormatting = true },
    },
    tinymist = {
      settings = {
        exportPdf = 'never',
        outputPath = '$root/$name',
        formatterMode = 'typstyle',
        -- typstExtraArgs = { "--features", "html" },
      },
      root_dir = function(startpath)
        return (require('lspconfig.util')).find_git_ancestor(startpath) or vim.fn.getcwd()
      end,
      post_attach = function(_, bufnr)
        map('n', '<leader>lp', function()
          vim.lsp.buf.execute_command({
            command = 'tinymist.pinMain',
            arguments = { vim.api.nvim_buf_get_name(bufnr) },
          })
        end, { buffer = bufnr, desc = 'tinymists pin main' })
        map('n', '<leader>lP', function()
          vim.lsp.buf.execute_command({ command = 'tinymist.pinMain', arguments = { nil } })
        end, { buffer = bufnr, desc = 'tinymists unpin main' })
      end,
    },
    coq_lsp = {},
  }

  vim.lsp.config('*', {
    capabilities = require('cmp_nvim_lsp').default_capabilities(),
    flags = { debounce_text_changes = 150 },
  })

  for lsp, opts in pairs(servers) do
    vim.lsp.config(lsp, {
      settings = opts.settings,
      init_options = opts.init_options,
      cmd = opts.cmd,
      single_file_support = opts.single_file_support or true,
      -- root_dir = opts.root_dir or (require('lspconfig.util')).find_git_ancestor,

      on_attach = function(client, bufnr)
        if client.server_capabilities.documentSymbolProvider then
          require('nvim-navbuddy').attach(client, bufnr)
        end
        -- Enable completion triggered by <c-x><c-o>
        vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

        -- Mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        map('n', 'gD', vim.lsp.buf.declaration, { buffer = bufnr, desc = 'lsp declaration' })
        map('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr, desc = 'lsp definition' })
        map('n', 'gi', vim.lsp.buf.implementation, { buffer = bufnr, desc = 'lsp impl' })
        map('n', 'grl', function()
          vim.lsp.buf.format({ async = true })
        end, { buffer = bufnr, desc = 'lsp format document' })
        -- default maps:
        -- gra: code_action
        -- gri: implementation
        -- grn: rename
        -- grr: references
        -- grt: type definition
        -- gO document symbol

        if opts.post_attach then
          opts.post_attach(client, bufnr)
        end
      end,
    })
    if lsp_autostart then
      vim.lsp.enable(lsp)
    end
  end

  map('n', '<leader>e', vim.diagnostic.open_float, d('diagnostic open float'))
  map('n', '[d', vim.diagnostic.goto_prev, d('diagnostic goto prev'))
  map('n', ']d', vim.diagnostic.goto_next, d('diagnostic goto next'))

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp_attach_disable_ruff_hover', { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client == nil then
        return
      end
      if client.name == 'ruff' then
        -- Disable hover in favor of Pyright
        client.server_capabilities.hoverProvider = false
      end
    end,
    desc = 'LSP: Disable hover capability from Ruff',
  })
end
