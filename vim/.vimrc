set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'ycm-core/YouCompleteMe'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

runtime! archlinux.vim

filetype plugin on
filetype indent on
syntax on

set expandtab
set tabstop=2
set shiftwidth=2
set number

set cursorline
set cursorlineopt=number
highlight CursorLineNr cterm=none ctermfg=15
highlight LineNr ctermbg=none ctermfg=8

" GitGutter configs
set updatetime=100
set signcolumn=auto

highlight SignColumn guifg=NONE guibg=NONE ctermfg=NONE ctermbg=NONE

highlight GitGutterAdd    guifg=NONE guibg=#009900 ctermfg=2  ctermbg=NONE
highlight GitGutterChange guifg=NONE guibg=#bbbb00 ctermfg=3  ctermbg=NONE
highlight GitGutterDelete guifg=NONE guibg=#ff2222 ctermfg=1  ctermbg=NONE

function! GitStatus()
  let [a,m,r] = GitGutterGetHunkSummary()
  return printf('+%d ~%d -%d', a, m, r)
endfunction
set statusline+=%{GitStatus()}

set termguicolors
let g:gitgutter_signs=0
let g:gitgutter_highlight_linenrs=1

highlight GitGutterAddLineNr guifg=lightgreen
highlight GitGutterChangeLineNr guifg=lightblue
highlight GitGutterDeleteLineNr guifg=lightred
highlight GitGutterChangeDeleteLineNr guifg=lightred
