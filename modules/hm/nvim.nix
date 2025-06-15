{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nivium.nvim;
  factlang = pkgs.vimUtils.buildVimPlugin {
    name = "factlang.vim";
    src = pkgs.fetchFromGitHub {
      owner = "PLSysSec";
      repo = "factlang.vim";
      rev = "dcc43d1246ace013a0705759095ed056ed441cab";
      hash = "sha256-bEcv7TuermxP5b2qk2wxxyt1xYU30Fk5+fAW1oEuiQI=";
    };
  };

in
{
  options.nivium.nvim = {
    enable = mkOption { type = types.bool; default = config.nivium.profile != "bare"; };
    lspPackages = mkOption { type = types.bool; default = config.nivium.profile == "full"; };
    extraLuaConfig = mkOption { type = types.lines; default = ""; };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf cfg.lspPackages (with pkgs; [
      lua-language-server
      nodePackages.vscode-json-languageserver
      nodePackages.typescript-language-server
      nodePackages.yaml-language-server
      nil
      gopls
      texlab
      rust-analyzer
      pyright
      ruff # python linter
      clang-tools
      beancount-language-server
      tinymist
      nixpkgs-fmt
      efm-langserver
      # coqPackages.coq-lsp
    ]);

    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      plugins = with pkgs.vimPlugins; [
        factlang

        # operation
        smartyank-nvim
        vim-mundo # undo tree visualizer
        which-key-nvim
        vim-surround
        vim-matchup
        nvim-autopairs
        comment-nvim
        nvim-bqf # better quickfix
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
        nvim-bqf # better quickfix
        trouble-nvim # diagnostic window
        noice-nvim # replace messages, cmdline and popups

        # visual improvement
        nvim-spectre # file search panel
        indent-blankline-nvim # add indent guide line
        nvim-scrollbar
        fidget-nvim

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
        nvim-lspconfig
        (nvim-treesitter.withPlugins (
          plugins: with plugins; [
            tree-sitter-c
            tree-sitter-vim
            tree-sitter-nix
            tree-sitter-lua
            tree-sitter-rust
            tree-sitter-go
            tree-sitter-cpp
            tree-sitter-bash
            tree-sitter-fish
            tree-sitter-vimdoc # nvim bundled parser conflicts with treesitter
            tree-sitter-beancount
            tree-sitter-typst
          ]
        ))
        nvim-treesitter-textobjects
        nvim-lspconfig
        vimtex
        vim-just # tree-sitter-just is not merged and have problems

        # appearance
        onedark-nvim
      ];

      extraLuaPackages = (_: [
        pkgs.LuaMyNvim
      ]);

      # To debug lua code:
      # LUA_PATH=(realpath modules/hm)'/?.lua;'(realpath modules/hm'/?/init.lua'
      extraLuaConfig =
        ''
          vim.opt.shada:append { 'n${config.xdg.stateHome}/viminfo' }

          local lsp_autostart = ${if cfg.lspPackages then "true" else "false"}
          require"LuaMyNvim"(vim, lsp_autostart)
        '' + cfg.extraLuaConfig;
    };
  };
}
