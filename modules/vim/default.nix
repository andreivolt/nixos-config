{ pkgs, ... }:

let
  theme = import ../theme.nix;

  plugins = with pkgs; {
    parinfer-rust = import ./plugins/parinfer-rust.nix;
    challenger-deep-theme = import ./plugins/challenger-deep-theme.nix;
    vim-iced = import ./plugins/vim-iced.nix;
    vim-bracketed-paste = import ./plugins/vim-bracketed-paste.nix;
    spell-ro = import ./plugins/spell-ro.nix;
    spell-fr = import ./plugins/spell-fr.nix;
    vim-autoclose = import ./plugins/vim-autoclose.nix;
    vim-avanced-sorters = import ./plugins/vim-advanced-sorters.nix;
  };

  conf = with theme; ''
    set
      \ autoindent
      \ breakindent
      \ clipboard=unnamedplus
      \ expandtab
      \ grepprg=rg\ --smart-case\ --vimgrep
      \ hidden
      \ ignorecase infercase smartcase
      \ linebreak " don't cut words on wrap
      \ mouse=a
      \ nowrap
      \ shiftwidth=2 shiftround tabstop=2
      \ showbreak=↳ " show wrapped lines
      \ smartindent
      \ wildmode=longest:full,full
      \ statusline=\ %t

    syntax on

    " command mode movement
    cnoremap <C-a> <Home>
    cnoremap <C-e> <End>
    cnoremap <C-p> <Up>
    cnoremap <C-n> <Down>
    cnoremap <C-b> <Left>
    cnoremap <C-f> <Right>
    cnoremap <M-b> <S-Left>
    cnoremap <M-f> <S-Right>

    " file explorer
    map <silent> <leader>t :NERDTreeToggle %<CR>:wincmd=<CR>

    " show replacements while typing
    set gdefault inccommand=nosplit

    " switch between buffers
    nnoremap <leader><leader> :b#<CR>

    " clear search highlight
    nnoremap <silent><esc> :nohlsearch<return><esc>
    nnoremap <esc>^[ <esc>^["

    " better whitespace
    let b:better_whitespace_enabled = 1
    let g:strip_whitelines_at_eof = 1

    let g:conjure#log#hud#enabled = 0

    " lisp case movement
    set iskeyword+=-

    set wrap

    "" fzf
    "let $FZF_DEFAULT_COMMAND = 'rg --files --follow -g "!{.git}/*" 2>/dev/null'
    "let g:fzf_colors =
    "\ { 'fg':      ['fg', 'Normal'],
    "  \ 'bg':      ['bg', 'Normal'],
    "  \ 'hl':      ['fg', 'Search'],
    "  \ 'fg+':     ['fg', 'Normal', 'Normal', 'Normal'],
    "  \ 'bg+':     ['bg', 'Normal', 'Normal'],
    "  \ 'hl+':     ['fg', 'Search'],
    "  \ 'info':    ['fg', 'Normal'],
    "  \ 'border':  ['fg', 'Normal'],
    "  \ 'prompt':  ['fg', 'Normal'],
    "  \ 'pointer': ['fg', 'Normal'],
    "  \ 'marker':  ['fg', 'Normal'],
    "  \ 'spinner': ['fg', 'Normal'],
    "  \ 'header':  ['fg', 'Normal'] }
    autocmd! FileType fzf
    autocmd FileType fzf set laststatus=0 noshowmode noruler foldcolumn=0
      \| autocmd BufLeave <buffer> set laststatus=1 noshowmode noruler foldcolumn=1

    " NERD Tree
    let NERDTreeMapActivateNode='<tab>'
    let g:NERDTreeDirArrowExpandable = '+'| let g:NERDTreeDirArrowCollapsible = '-'
    let g:NERDTreeMinimalUI = 1
    let NERDTreeAutoDeleteBuffer=1

    " Supertab
    let g:SuperTabDefaultCompletionType = "context"

    " change cursor appearance with mode
    set guicursor=n-v-c:block-Cursor/lCursor,i-ci-ve:ver25-Cursor2/lCursor2,r-cr:hor20,o:hor50

    set showmatch

    set fillchars=stl:\ ,stlnc:\ ,vert:│
    set noruler
    set laststatus=1 noshowmode

    " hide messages after 1.5s
    set updatetime=1500 | autocmd CursorHold * :echo

    let mapleader = "\<Space>"
    let maplocalleader = ","
    " windows
    nmap <silent> <C-h> :wincmd h<CR> | nmap <silent> <C-j> :wincmd j<CR> | nmap <silent> <C-k> :wincmd k<CR> | nmap <silent> <C-l> :wincmd l<CR>
    " buffers
    nnoremap <leader>bn :bnext<CR> | nnoremap <leader>bp :bprevious<CR> | nnoremap <leader>bd :bdelete<CR> | nnoremap <leader>bf <C-^>
    " arglist
    nnoremap <leader>an :next<cr> | nnoremap <leader>ap :prev<cr>
    " quickfix
    nnoremap <leader>cn :cnext<cr> | nnoremap <leader>cp :cprev<cr>
    " select last inserted text
    nnoremap gV '[V']
    " toggle line numbers
    map <silent> <leader>tn :set number!<CR>
    " fuzzy find
    nnoremap <silent> <leader>b :Buffers<CR>
    nnoremap <silent> <leader>f :Files<CR>


    map <silent> <leader>g :Goyo<CR>

    ${import ./colorscheme.nix { inherit theme; } }

    colorscheme challenger_deep | hi Normal guibg=black

    " indent guides
    let g:indent_guides_auto_colors = 0
    autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd ctermbg=NONE guibg=NONE
    autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=15 guibg=${white_bg}

    " NERD Tree
    hi NERDTreeCWD ctermfg=8 guifg=${black_bg}
    hi NERDTreeClosable ctermfg=8 guifg=${black_bg} | hi NERDTreeOpenable ctermfg=8 guifg=${black_bg}

    " LanguageClient-neovim
    let g:LanguageClient_serverCommands = {
        \ 'clojure': ['clojure-lsp'],
        \ }

    set autoread

    set title

    set guifont=Hack\ Nerd\ Font:h28

    let g:neovide_cursor_animation_length=0.02

    hi CursorLine guibg=#333333

    let g:compe = {}
    let g:compe.enabled = v:true
    let g:compe.source = {
      \ 'path': v:true,
      \ 'buffer': v:true,
      \ 'nvim_lsp': v:true,
      \ 'conjure': v:true,
      \ }
''; in pkgs.neovim.override {
  vimAlias = true;
  configure.vam = {
    knownPlugins = pkgs.vimPlugins // plugins;

    pluginDictionaries = [
      { name = "commentary"; }
      # { name = "floobits-neovim"; }
      { name = "fzfWrapper"; }
      { name = "fzf-vim"; }
      { name = "neovim-fuzzy"; }
      { name = "nerdtree"; }
      { name = "parinfer-rust"; }
      { name = "spell-fr"; }
      { name = "spell-ro"; }
      { name = "supertab"; }
      { name = "surround"; }
      { name = "vim-grepper"; }
      { name = "challenger-deep-theme"; }
      { name = "vim-autoclose"; }
      { name = "vim-better-whitespace"; }
      { name = "vim-bracketed-paste"; }
      { name = "vim-eunuch"; }
      { name = "vim-indent-guides"; }
      { name = "vim-indent-object"; }
      { name = "goyo"; }
      { name = "vim-nix"; }
      { name = "vim-iced"; }
      { name = "vim-sexp"; }
      { name = "vim-sexp-mappings-for-regular-people"; }
      { name = "conjure"; }
      { name = "rainbow_parentheses-vim"; }
      { name = "vim-clojure-static"; }
      { name = "vim-clojure-highlight"; }
      { name = "LanguageClient-neovim"; }
      # { name = "nvim-treesitter"; }
      # { name = "nvim-treesitter-refactor"; }
      # { name = "compe-conjure"; }
      # { name = "nvim-compe"; }
      # { name = "nvim-treesitter-context"; }
      { name = "open-browser-vim"; }
      { name = "vim-avanced-sorters"; }
      # { name = "rainbow"; }
    ];
  };
  configure.customRC = conf;
}
