{ pkgs, ... }:

let
  theme = import (dirOf <nixos-config> + /modules/theme.nix);

  plugins = with pkgs; {
    challenger-deep-theme = import ./plugins/challenger-deep-theme.nix;
    parinfer-rust = import ./plugins/parinfer-rust.nix;
    spell-fr = import ./plugins/spell-fr.nix;
    spell-ro = import ./plugins/spell-ro.nix;
    vim-autoclose = import ./plugins/vim-autoclose.nix;
    vim-avanced-sorters = import ./plugins/vim-advanced-sorters.nix;
    vim-bracketed-paste = import ./plugins/vim-bracketed-paste.nix;
    vim-iced = import ./plugins/vim-iced.nix;
    vim-ripgrep = import ./plugins/vim-advanced-sorters.nix;
  };

  conf = with theme; ''
    set
      \ autoindent
      \ breakindent
      \ clipboard=unnamedplus
      \ expandtab
      \ grepprg=${pkgs.ripgrep}/bin/rg\ --smart-case\ --vimgrep
      \ hidden
      \ ignorecase infercase smartcase
      \ linebreak
      \ mouse=a
      \ nowrap
      \ shiftwidth=2 shiftround tabstop=2
      \ showbreak=↳
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
    nnoremap <silent> <leader>b :FuzzyBuffer<CR>
    nnoremap <silent> <leader>f :FuzzyOpen<CR>

    " narrower file explorer
    let g:netrw_winsize = 20

    let g:ctrlp_clear_cache_on_exit = 0

    map <silent> <leader>g :Goyo<CR>

    ${import ./colorscheme.nix { inherit theme; } }

    " colorscheme challenger_deep | hi Normal guibg=black
    hi StatusLineNC guibg=#111111 guifg=#777777 | hi StatusLine guibg=#222222 guifg=#777777 | hi VertSplit guifg=#111111 | hi Normal guifg=white

    " indent guides
    let g:indent_guides_auto_colors = 0
    autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd ctermbg=NONE guibg=NONE
    autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=15 guibg=${white_bg}

    "  " NERD Tree
    "  hi NERDTreeCWD ctermfg=8 guifg=${black_bg}
    "  hi NERDTreeClosable ctermfg=8 guifg=${black_bg} | hi NERDTreeOpenable ctermfg=8 guifg=${black_bg}

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
''; in pkgs.nixpkgsUnstable.neovim.override {
  vimAlias = true;
  viAlias = true;
  configure.vam = {
    knownPlugins = pkgs.vimPlugins // plugins;

    pluginDictionaries = [
      # { name = "floobits-neovim"; }
      # { name = "goyo"; }
      # { name = "nerdtree"; }
      # { name = "nvim-treesitter"; }
      # { name = "rainbow"; }
      # { name = "supertab"; }
      # { name = "vim-avanced-sorters"; }
      # { name = "vim-grepper"; }
      # { name = "vim-iced"; } # clojure
      # { name = "vim-indent-guides"; }
      # { name = "vim-sexp"; }
      # { name = "vim-sexp-mappings-for-regular-people"; }
      # { name = "vim-sort-motion"; }
      # { name = "nvim-treesitter-context"; }
      # { name = "nvim-treesitter-refactor"; }
      { name = "challenger-deep-theme"; }

      { name = "neovim-fuzzy"; }
      # { name = "command-t"; }

      { name = "commentary"; }

      { name = "nvim-compe"; }
      { name = "compe-conjure"; }

      { name = "conjure"; } # clojure
      { name = "LanguageClient-neovim"; }
      { name = "open-browser-vim"; }
      { name = "parinfer-rust"; }
      # { name = "rainbow_parentheses-vim"; } # TODO
      { name = "spell-fr"; }
      { name = "spell-ro"; }
      { name = "surround"; }
      { name = "vim-autoclose"; }
      { name = "vim-better-whitespace"; }
      { name = "vim-clojure-highlight"; }
      { name = "vim-clojure-static"; }
      { name = "vim-eunuch"; }
      { name = "vim-indent-object"; }
      { name = "vim-nix"; }
      { name = "vim-ripgrep"; }
      { name = "vim-javascript"; }
    ];
  };
  configure.customRC = conf;
}
