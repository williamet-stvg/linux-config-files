"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""               
"               
"               ██╗   ██╗██╗███╗   ███╗██████╗  ██████╗
"               ██║   ██║██║████╗ ████║██╔══██╗██╔════╝
"               ██║   ██║██║██╔████╔██║██████╔╝██║     
"               ╚██╗ ██╔╝██║██║╚██╔╝██║██╔══██╗██║     
"                ╚████╔╝ ██║██║ ╚═╝ ██║██║  ██║╚██████╗
"                 ╚═══╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝
"               
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""        

" set UTF-8 encoding
set enc=utf-8
set fenc=utf-8
set termencoding=utf-8

" disable vi compatibility - emulation of old bugs
set nocompatible

" use indentation of previous line
set autoindent

" use intelligent indentation for C
set smartindent

" configure tabwidth and insert spaces instead of tabs
set tabstop=2 " tab width is 4 spaces
set shiftwidth=2 " indent also with 4 spaces
set expandtab " expand tabs to spaces

" wrap lines at 120 chars. 80 is somewaht antiquated with nowadays displays.
set textwidth=120

" turn syntax highlighting on
set t_Co=256
syntax on
" colorscheme wombat256

" highlight matching braces
set showmatch

" While searching though a file incrementally highlight matching characters as you type.
set incsearch

" Ignore capital letters during search.
set ignorecase

" Override the ignorecase option if searching for capital letters.
" This will allow you to search specifically for capital letters.
set smartcase

" Show partial command you type in the last line of the screen.
set showcmd

" Show the mode you are on the last line.
set showmode

" Show matching words during a search.
set showmatch

" Use highlighting when doing a search.
set hlsearch

" Enable auto completion menu after pressing TAB.
set wildmenu

" Make wildmenu behave like similar to Bash completion.
set wildmode=list:longest

" RELATIVE LINE NUMBERS --------------------------------------------------- {{{

" Automatic toggling between line number modes
" Insert mode: absolute line numbers
" Normal mode: relative line numbers
:set number
:augroup numbertoggle
:  autocmd!
:  autocmd BufEnter,FocusGained,InsertLeave,WinEnter * if &nu && mode() != "i" | set rnu   | endif
:  autocmd BufLeave,FocusLost,InsertEnter,WinLeave   * if &nu                  | set nornu | endif
:augroup END

" }}}

" STATUS LINE ------------------------------------------------------------ {{{

  " Clear status line when vimrc is reloaded.
  set statusline=

  " Status line left side.
  set statusline+=\ %F\ %M\ %Y\ %R

  " Use a divider to separate the left side from the right side.
  set statusline+=%=

  " Status line right side.
  set statusline+=\ ascii:\ %b\ hex:\ 0x%B\ row:\ %l\ col:\ %c\ percent:\ %p%%

  " Show the status on the second to last line.
  set laststatus=2

  " }}}
