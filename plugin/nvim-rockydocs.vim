" File: plugin/nvim-rockydocs.vim
" Description: Plugin entry point for Vimscript

if exists('g:loaded_rockydocs')
  finish
endif
let g:loaded_rockydocs = 1

lua require("rockydocs").setup()
