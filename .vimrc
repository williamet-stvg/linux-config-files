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
 
" Disable vi compatibility.
" IMPORTANT: setting this yourself means Vim does NOT load its own
" defaults.vim, so a handful of sane settings you would otherwise inherit
" (notably 'backspace') have to be set explicitly below.
set nocompatible
 
" ---------------------------------------------------------------------------
" ENCODING
" ---------------------------------------------------------------------------
set encoding=utf-8
scriptencoding utf-8
set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,latin1
 
" ---------------------------------------------------------------------------
" FILETYPE + SYNTAX
" ---------------------------------------------------------------------------
" This was missing. Without `filetype indent on` you get no language-aware
" indentation at all, which is most of what you actually want from an editor.
filetype plugin indent on
syntax enable
 
" ---------------------------------------------------------------------------
" INDENTATION — 2 spaces
" ---------------------------------------------------------------------------
set autoindent
set expandtab                 " insert spaces, never a literal tab
set tabstop=2                 " a tab character displays as 2 columns
set softtabstop=2             " <Tab>/<BS> move by 2 in insert mode
set shiftwidth=2              " >> and << shift by 2
set shiftround                " round shifts to a multiple of shiftwidth
 
" NOTE: 'smartindent' was removed deliberately. It is superseded by
" `filetype indent on` and actively misbehaves — most visibly, it yanks
" '#' comment lines to column 0 in Python.
 
" ---------------------------------------------------------------------------
" LINE LENGTH
" ---------------------------------------------------------------------------
" 'textwidth' HARD-wraps as you type — it inserts real newlines into your
" source. That is almost never what you want in code. Use 'colorcolumn' for
" a visual guide, and turn textwidth on only for prose filetypes.
set colorcolumn=120
set textwidth=0
set nowrap                    " don't soft-wrap long lines either
set linebreak                 " ...but if you :set wrap, break at word bounds
 
augroup prose_textwidth
  autocmd!
  autocmd FileType markdown,text,gitcommit,rst setlocal textwidth=120 wrap
  autocmd FileType gitcommit setlocal colorcolumn=51,73
augroup END
 
" ---------------------------------------------------------------------------
" EDITING BEHAVIOUR
" ---------------------------------------------------------------------------
" Without this, backspace refuses to delete past the start of insert mode,
" past autoindent, or over a line break. Classic "my backspace is broken".
set backspace=indent,eol,start
 
set hidden                    " switch buffers without forcing a write
set confirm                   " ask instead of failing on unsaved changes
set autoread                  " reload files changed outside vim
set mouse=a                   " works in Windows Terminal and tmux
set ttimeout
set ttimeoutlen=50            " no lag after pressing Esc
set updatetime=300
set scrolloff=3               " keep 3 lines of context when scrolling
set sidescrolloff=5
set nostartofline
set splitbelow splitright     " new splits appear where you expect
 
" ---------------------------------------------------------------------------
" SEARCH
" ---------------------------------------------------------------------------
set incsearch                 " highlight matches while typing
set hlsearch                  " highlight all matches
set ignorecase                " case-insensitive by default...
set smartcase                 " ...unless the pattern contains a capital
 
" Clear the search highlight. hlsearch with no way to dismiss it is misery.
nnoremap <silent> <Esc><Esc> :nohlsearch<CR>
 
" ---------------------------------------------------------------------------
" UI
" ---------------------------------------------------------------------------
set showmatch                 " briefly jump to the matching bracket
set showcmd                   " show the partial command in the last line
set showmode                  " show -- INSERT --
set ruler
set laststatus=2
set number                    " see the relative-number block below
set signcolumn=no
set display+=lastline
set shortmess+=I              " skip the intro splash screen
 
" Show whitespace that matters.
set list
set listchars=tab:»·,trail:·,nbsp:␣,extends:›,precedes:‹
 
" ---------------------------------------------------------------------------
" COLOURS
" ---------------------------------------------------------------------------
" 't_Co=256' is legacy. Windows Terminal and modern gnome-terminal both do
" 24-bit colour; prefer termguicolors when the terminal advertises it.
if has('termguicolors')
  if $COLORTERM ==# 'truecolor' || $COLORTERM ==# '24bit' || !empty($WT_SESSION)
    set termguicolors
  endif
endif
set background=dark
" colorscheme wombat256   " needs to be installed under ~/.vim/colors/
 
" Make colorcolumn subtle rather than a wall of magenta.
highlight ColorColumn ctermbg=236 guibg=#2a2f33
 
" ---------------------------------------------------------------------------
" COMPLETION / WILDMENU
" ---------------------------------------------------------------------------
set wildmenu
set wildmode=longest:full,full
set wildignorecase
set wildignore+=*.o,*.obj,*.pyc,*.class,*.swp,*/.git/*,*/node_modules/*
set completeopt=menuone,longest
set path+=**                  " :find searches recursively
 
" ---------------------------------------------------------------------------
" FILES: no swap clutter, persistent undo
" ---------------------------------------------------------------------------
set noswapfile
set nobackup
set nowritebackup
 
if has('persistent_undo')
  let s:undodir = expand('~/.vim/undo')
  if !isdirectory(s:undodir)
    call mkdir(s:undodir, 'p', 0700)
  endif
  let &undodir = s:undodir
  set undofile
  set undolevels=1000
endif
 
" ---------------------------------------------------------------------------
" RELATIVE LINE NUMBERS ---------------------------------------------------- {{{
" Insert mode: absolute.  Normal mode: relative.
" (The original had a stray ':' on every line — a copy/paste artefact from
" the docs. Harmless, but it is not idiomatic vimscript.)
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave,WinEnter *
        \ if &number && mode() !=# 'i' | set relativenumber | endif
  autocmd BufLeave,FocusLost,InsertEnter,WinLeave *
        \ if &number | set norelativenumber | endif
augroup END
" }}}
 
" ---------------------------------------------------------------------------
" STATUS LINE ------------------------------------------------------------- {{{
set statusline=
set statusline+=\ %f                      " relative path (%F is often too long)
set statusline+=\ %m%r%h%w                " modified / readonly / help / preview
set statusline+=\ %y                       " filetype
set statusline+=\ [%{&fileencoding?&fileencoding:&encoding}]
set statusline+=\ [%{&fileformat}]         " unix / dos — useful on WSL
set statusline+=%=                         " ---- divider ----
set statusline+=\ ascii:\ %b\ hex:\ 0x%B
set statusline+=\ \|\ %l:%c\ (%p%%)
set statusline+=\ %L\ lines\
" }}}
 
" ---------------------------------------------------------------------------
" HANDY MAPPINGS
" ---------------------------------------------------------------------------
" Move by display line when a line is wrapped.
nnoremap <expr> j v:count ? 'j' : 'gj'
nnoremap <expr> k v:count ? 'k' : 'gk'
 
" Keep the cursor centred when jumping through search results.
nnoremap n nzz
nnoremap N Nzz
 
" Retain visual selection after shifting.
vnoremap < <gv
vnoremap > >gv
 
" Write a file you forgot to open with sudo.
command! W execute 'silent! write !sudo tee % >/dev/null' <bar> edit!
 
" Jump to the last cursor position when reopening a file.
augroup last_position
  autocmd!
  autocmd BufReadPost *
        \ if line("'\"") >= 1 && line("'\"") <= line("$") && &filetype !=# 'gitcommit'
        \ |   execute "normal! g`\""
        \ | endif
augroup END
 
" Strip trailing whitespace on write, preserving cursor position.
function! s:StripTrailingWhitespace() abort
  if &binary || &filetype ==# 'diff'
    return
  endif
  let l:view = winsaveview()
  keeppatterns %s/\s\+$//e
  call winrestview(l:view)
endfunction
 
augroup strip_whitespace
  autocmd!
  autocmd BufWritePre * call s:StripTrailingWhitespace()
augroup END
 
" ---------------------------------------------------------------------------
" WSL: yank to the Windows clipboard with <leader>y
" ---------------------------------------------------------------------------
if executable('clip.exe')
  vnoremap <leader>y y:call system('clip.exe', @0)<CR>
  nnoremap <leader>Y yy:call system('clip.exe', @0)<CR>
endif
 
