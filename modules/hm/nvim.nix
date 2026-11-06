{ config, pkgs, lib, ... }:

let
  cfg = config.nivium.nvim;
  langs = cfg.extraLangs;
in
{
  options.nivium.nvim = with lib; {
    enable = mkOption { type = types.bool; default = config.nivium.profile != "bare"; };
    lspPackages = mkOption { type = types.bool; default = config.nivium.profile == "full"; };
    initLua = mkOption { type = types.lines; default = ""; };
    extraLangs = {
      hocon.enable = mkEnableOption "HOCON support (tree-sitter grammar and language server)";
      era.enable = mkEnableOption "Emuera ERB support (tree-sitter grammar and language server)";
      latex.enable = mkEnableOption "LaTeX support (tree-sitter grammar, texlab and vimtex)";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals cfg.lspPackages
      (with pkgs; [
        lua-language-server
        vscode-json-languageserver
        typescript-language-server
        yaml-language-server
        nil
        gopls
        rust-analyzer
        basedpyright
        ruff # python linter
        clang-tools
        beancount-language-server
        tinymist
        nixpkgs-fmt
        efm-langserver
      ])
    ++ lib.optional langs.hocon.enable pkgs.hocon-language-server
    ++ lib.optional langs.era.enable pkgs.era_ls
    ++ lib.optional langs.latex.enable pkgs.texlab;

    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      plugins = with pkgs.vimPlugins; [
        factlang-vim

        # operation
        smartyank-nvim
        vim-mundo # undo tree visualizer
        which-key-nvim
        vim-surround
        vim-matchup
        nvim-autopairs
        comment-nvim
        trouble-nvim # diagnostic window
        vim-exchange
        vim-argumentative
        leap-nvim

        # widget
        barbar-nvim # tabline
        lualine-nvim
        neo-tree-nvim
        nui-nvim # required by neo-tree-nvim
        toggleterm-nvim
        telescope-nvim
        nvim-navic # breadcrumb
        nvim-navbuddy # code outline
        trouble-nvim # diagnostic window
        nvim-notify
        render-markdown-nvim
        fidget-nvim # lsp progress notification

        # visual improvement
        nvim-spectre # file search panel
        indent-blankline-nvim # add indent guide line
        nvim-scrollbar

        # "transparent" enhancement
        vim-repeat
        vim-sleuth # heuristicly adjust shiftwidth
        vim-barbaric
        nvim-lastplace

        # project-nvim # auto set root

        # git
        vim-fugitive
        gitsigns-nvim
        diffview-nvim

        # completion
        nvim-cmp
        luasnip
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        cmp-cmdline
        cmp-nvim-lsp-signature-help

        # TODO: try undotree

        # coding
        (nvim-treesitter.withPlugins (
          plugins: with plugins; [
            tree-sitter-c
            tree-sitter-vim
            tree-sitter-nix
            tree-sitter-lua
            tree-sitter-rust
            tree-sitter-go
            pkgs.tree-sitter-cpp-unstable
            tree-sitter-bash
            tree-sitter-python
            tree-sitter-fish
            tree-sitter-cmake
            tree-sitter-vimdoc # nvim bundled parser conflicts with treesitter
            tree-sitter-beancount
            tree-sitter-typst
            tree-sitter-typescript
          ]
          ++ lib.optional langs.hocon.enable pkgs.tree-sitter-hocon
          ++ lib.optional langs.era.enable pkgs.tree-sitter-era
          ++ lib.optional langs.latex.enable tree-sitter-latex
        ))
        nvim-treesitter-context
        # nvim-treesitter-textobjects

        # appearance
        onedark-nvim
      ] ++ lib.optional langs.latex.enable vimtex;

      extraLuaPackages = (_: [
        pkgs.LuaMyNvim
      ]);

      # To debug lua code:
      # LUA_PATH=(realpath modules/hm)'/?.lua;'(realpath modules/hm'/?/init.lua'
      initLua =
        ''
          vim.opt.shada:append { 'n${config.xdg.stateHome}/viminfo' }

          local lsp_autostart = ${if cfg.lspPackages then "true" else "false"}
          require"LuaMyNvim"(vim, lsp_autostart)
        '' + cfg.initLua;
    };

    xdg.configFile."nvim/queries" = {
      source = ./LuaMyNvim/runtime/queries;
    };
  };
}
