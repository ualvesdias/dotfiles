" vicConfig {{{

syntax on
set t_Co=256
set tabpagemax=10000
set noerrorbells
set tabstop=4 
set softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set autoindent
set nu
set wrap
set linebreak
set smartcase
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile
set incsearch
set nohlsearch
set ignorecase
set relativenumber
set splitbelow
set splitright
set clipboard=unnamed
set lazyredraw
set cursorline
set conceallevel=2
set hidden
set scrolloff=10

" }}}

" SectionFoldingSettings {{{

set foldenable
set foldlevelstart=10
set foldnestmax=10
set foldmethod=marker
set foldmarker={{{,}}}
set foldlevel=0
nnoremap <leader>ft za " Toggle section folding

" Automatically save and load the folds
autocmd BufWinLeave *.* mkview
autocmd BufWinEnter *.* silent loadview

" }}}

" Remap leader key to space {{{

let mapleader = " "

" }}}

" Move line(s) up or down with Alt-k or Alt-j {{{

nnoremap <C-j> :m .+1<CR>==
nnoremap <C-k> :m .-2<CR>==
vnoremap <C-j> :m '>+1<CR>gv=gv
vnoremap <C-k> :m '<-2<CR>gv=gv

" }}}

" Navigate in insert mode with Alt + hjkl {{{

inoremap <A-h> <Left>
inoremap <A-j> <Down>
inoremap <A-k> <Up>
inoremap <A-l> <Right>
cnoremap <A-h> <Left>
cnoremap <A-j> <Down>
cnoremap <A-k> <Up>
cnoremap <A-l> <Right>

"}}}

" Move through panes with leader + hjkl {{{

nnoremap <leader>h :wincmd h<CR>
nnoremap <leader>j :wincmd j<CR>
nnoremap <leader>k :wincmd k<CR>
nnoremap <leader>l :wincmd l<CR>

" }}}

" Split panes {{{
nnoremap <leader>\ :vsp<CR>
nnoremap <leader>- :sp<CR>

" }}}

" Shortcuts for saving and quiting a file {{{
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>Q :q!<CR>
nnoremap <leader><Tab> :wq<CR>

" }}}

" Editing and sourcing .vimrc {{{

nnoremap <leader>sv :source $MYVIMRC<CR>
nmap <leader>ev :tabedit $MYVIMRC<CR>

" }}}

" Plugins via Plug manager {{{
call plug#begin('~/.vim/plugged')

Plug 'sonph/onehalf', { 'rtp': 'vim' }
Plug 'jiangmiao/auto-pairs'
Plug 'tyrannicaltoucan/vim-deep-space'
Plug 'plasticboy/vim-markdown'
Plug 'vim-airline/vim-airline'
Plug 'szw/vim-maximizer'
Plug 'vim-airline/vim-airline-themes'
Plug 'puremourning/vimspector'
Plug 'szw/vim-maximizer'
Plug 'voldikss/vim-floaterm'
Plug 'junegunn/vim-easy-align'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'vim-utils/vim-man'
Plug 'lyuts/vim-rtags'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'mbbill/undotree'
Plug 'tpope/vim-surround'
Plug 'junegunn/rainbow_parentheses.vim'
Plug 'preservim/nerdtree'
Plug 'rust-lang/rls'
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'tpope/vim-commentary'

call plug#end()

" }}}

" fzf  {{{
let g:fzf_layout = { 'window': { 'width': 0.8, 'height': 0.8 } }
let $FZF_DEFAULT_OPTS='--reverse'
nnoremap <leader>p :Files<CR>

" }}}

" Vimspector key mappings {{{

nnoremap <leader>m :MaximizerToggle!<CR>
nnoremap <leader>dd :call vimspector#Launch()<CR>

" }}}

" Rust commands (cargo build/run) {{{

nnoremap <leader>cb :FloatermNew --disposable cargo build<CR>
nnoremap <leader>cr :FloatermNew --disposable cargo run<CR>

" }}}

" Coc settings {{{

nmap <leader>gd <Plug>(coc-definition)
nmap <leader>gr <Plug>(coc-references)
autocmd FileType rust let b:coc_root_patterns = ['Cargo.toml','.git']

" }}}

" Airline configs {{{

let g:airline#extensions#tabline#enabled = 1
let g:airline_theme='deep_space'

" }}}

" Color Scheme {{{

set background=dark
set termguicolors
colorscheme deep-space

" }}}

" Buffer{{{

" Show the buffer number on the status lins

nnoremap <Leader>l :ls<CR>
nnoremap <Leader>bf :bn<CR>
nnoremap <Leader>bb :bp<CR>
nnoremap <Leader>1 :1b<CR>
nnoremap <Leader>2 :2b<CR>
nnoremap <Leader>3 :3b<CR>
nnoremap <Leader>4 :4b<CR>
nnoremap <Leader>5 :5b<CR>
nnoremap <Leader>6 :6b<CR>
nnoremap <Leader>7 :7b<CR>
nnoremap <Leader>8 :8b<CR>
nnoremap <Leader>9 :9b<CR>
nnoremap <Leader>0 :10b<CR>

" }}}

" FloatTerm Mappings{{{

" Set key mappings for floatterm

nnoremap <F5> :FloatermNew<CR>
tnoremap <F5> <C-\><C-n>:FloatermNew<CR>
nnoremap <F6> :FloatermToggle<CR>
tnoremap <F6> <C-\><C-n>:FloatermToggle<CR>
nnoremap <F7> :FloatermPrev<CR>
tnoremap <F7> <C-\><C-n>:FloatermPrev<CR>
nnoremap <F8> :FloatermNext<CR>
tnoremap <F8> <C-\><C-n>:FloatermNext<CR>
nnoremap <F9> :FloatermKill<CR>
tnoremap <F9> <C-\><C-n>:FloatermKill<CR>

" }}}

" EasyAlign shortcuts {{{

" gaip= (Align inside paragraph around =)
" ga-  ('space' Align inside paragraph around last space)
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

" }}}

" Rainbow parenthesis  {{{
let g:rainbow#max_level = 16
let g:rainbow#pairs = [['(', ')'], ['[', ']']]
au VimEnter * RainbowParentheses!!

" }}}

" Navigate through tabs with shift-HL {{{
nnoremap H gT
nnoremap L gt
nmap <leader>nt :tabnew<CR>

" }}}

" NerdTree options {{{

" Toggle NerdTree
nnoremap <leader>n :NERDTreeToggle<CR>
" Focus on NerdTree
nnoremap <leader>nf :NERDTreeFocus<CR>
" Open the existing NERDTree on each new tab.
autocmd BufWinEnter * if getcmdwintype() == '' | silent NERDTreeMirror | endif

" }}}

" Add support for True Color {{{

if exists('+termguicolors')
  let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

" }}}

" Rust RLS Settings {{{

if executable('rls')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'rls',
        \ 'cmd': {server_info->['rustup', 'run', 'nightly', 'rls']},
        \ 'whitelist': ['rust'],
        \ })
endif

" }}}

" Abbreviations {{{

" Python
autocmd Filetype python :iabbrev prt print("")<left><left>
autocmd Filetype python :iabbrev ifelse if :<CR>pass<CR>else:<CR>pass<esc>3k03li
autocmd Filetype python :iabbrev ifelif if :<CR>pass<CR>elif :<CR>pass<esc>3k03li
autocmd Filetype python :iabbrev elifelse if :<CR>pass<CR>elif :<CR>pass<CR>else :<CR>pass<esc>4k03li
autocmd Filetype python :iabbrev pydef def ():<CR>pass<esc>k0wli
autocmd Filetype python :iabbrev ifmain if __name__ == '__main__':

" }}}

" Vim Maximizer {{{

nnoremap <silent><F3> :MaximizerToggle<CR>
vnoremap <silent><F3> :MaximizerToggle<CR>gv
inoremap <silent><F3> <C-o>:MaximizerToggle<CR>

" }}}
