return function (vim)
  vim.g.maplocalleader = "\\"
  vim.g.vimtex_view_method = 'zathura'
  vim.g.matchup_override_vimtex = 1
  vim.g.vimtex_compiler_method = 'latexrun'
  vim.g.vimtex_compiler_latexrun = {
    out_dir = 'latex.out',
    options = { "--latex-cmd=xelatex", "--latex-args=--shell-escape --synctex=1" }
  }
end
