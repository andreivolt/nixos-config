{ pkgs, ... }:

let
  theme = import ./theme.nix;
  plugins = with pkgs; {
    parinfer-rust = vimUtils.buildVimPlugin {
      name = "parinfer";
      src = fetchFromGitHub {
        owner = "eraserhd"; repo = "parinfer-rust";
        rev = "642fec5698f21758029988890c6683763beee5fd"; sha256 = "09gr3klm057l0ix9l4qxg65s2pw669k9l4prrr9gp7z30q1y5bi8";
      };
      buildPhase = "HOME=$TMP ${cargo}/bin/cargo build --release";
    };

    vim-iced = vimUtils.buildVimPlugin {
      name = "vim-iced";
      src = fetchFromGitHub {
        owner = "liquidz"; repo = "vim-iced";
        rev = "ea2cb830ccecd3ce9d4d21de55c58b59c5ca86a9"; sha256 = "1m4rn68gcj5ikiz21sh50gyz9f4g634zzhn178avhwgdfbjs8ryl";
      };
    };

    vim-bracketed-paste = vimUtils.buildVimPlugin {
      name = "vim-bracketed-paste";
      src = fetchFromGitHub {
        owner = "ConradIrwin"; repo = "vim-bracketed-paste";
        rev = "c4c639f3cacd1b874ed6f5f196fac772e089c932"; sha256 = "1hhi7ab36iscv9l7i64qymckccnjs9pzv0ccnap9gj5xigwz6p9h";
      };
    };

    spell-ro = vimUtils.buildVimPlugin {
      name = "spell-ro";
      src = [ (builtins.fetchurl ftp://ftp.vim.org/pub/vim/runtime/spell/ro.utf-8.spl) ];
      unpackPhase = ":";
      buildPhase = "mkdir -p $out/spell && cp $src $out/spell/ro.utf-8.spl";
    };

    spell-fr = vimUtils.buildVimPlugin {
      name = "spell-fr";
      src = [ (builtins.fetchurl ftp://ftp.vim.org/pub/vim/runtime/spell/fr.utf-8.spl) ];
      unpackPhase = ":";
      buildPhase = "mkdir -p $out/spell && cp $src $out/spell/fr.utf-8.spl";
    };

    vim-autoclose = vimUtils.buildVimPlugin {
      name = "vim-autoclose";
      src = fetchFromGitHub {
        owner = "Townk"; repo = "vim-autoclose";
        rev = "a9a3b7384657bc1f60a963fd6c08c63fc48d61c3"; sha256 = "12jk98hg6rz96nnllzlqzk5nhd2ihj8mv20zjs56p3200izwzf7d";
      };
    };
  };

  rc = with theme; ''
    set noswapfile
    set hidden
    set clipboard=unnamedplus
    set wildmode=longest:full,full
    set grepprg=rg\ --smart-case\ --vimgrep
    set autoindent smartindent breakindent
    set nowrap
    set linebreak " don't cut words on wrap
    " show wrapped lines
    set showbreak=↳
    set ignorecase smartcase infercase
    set
      \ shiftwidth=2 shiftround
      \ expandtab
      \ tabstop=2

    set mouse=a

    " statusline
    set statusline=\ %t

    " file explorer
    map <silent> <leader>t :NERDTreeToggle %<CR>:wincmd=<CR>

    set gdefault inccommand=nosplit

    " clear search highlight
    nnoremap <silent><esc> :nohlsearch<return><esc>
    nnoremap <esc>^[ <esc>^["

    " better whitespace
    let b:better_whitespace_enabled = 1
    let g:strip_whitelines_at_eof = 1

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
    "autocmd! FileType fzf
    "autocmd FileType fzf set laststatus=0 noshowmode noruler foldcolumn=0
    "  \| autocmd BufLeave <buffer> set laststatus=1 noshowmode noruler foldcolumn=1

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

    " hide messages after 2s
    set updatetime=2000 | autocmd CursorHold * :echo

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
    nnoremap <silent> <leader>f :FuzzyOpen<CR>

    set termguicolors

    for i in [ 'Keyword', 'Boolean', 'Character', 'Comment', 'Conceal', 'Conditional', 'Constant', 'Cursor', 'Cursor2', 'CursorLine', 'Debug', 'Define', 'Delimiter', 'Directory', 'Error', 'ErrorMsg', 'Exception', 'Float', 'FoldColumn', 'Function', 'Identifier', 'Ignore', 'Include', 'IncSearch', 'Keyword', 'Label', 'Macro', 'MatchParen', 'Normal', 'Number', 'Operator', 'PreCondit', 'PreProc', 'Repeat', 'Search', 'SignColumn', 'Special', 'SpecialChar', 'SpecialComment', 'SpellBad', 'Statement', 'StorageClass', 'String', 'Structure', 'Tag', 'Title', 'Todo', 'Type', 'Typedef', 'Underlined', 'VertSplit', 'WarningMsg' ]
      exe 'hi ' . i . ' NONE'
    endfor

    hi Comment gui=italic guifg=${black_fg}
    hi Cursor guibg=${red_fg}
    hi Cursor2 guibg=${blue_fg}
    hi Delimiter gui=bold
    hi EndOfBuffer guifg=${background}
    hi Folded guibg=${white_bg} guifg=${white_fg}
    hi IncSearch gui=bold guibg=${yellow_fg} guifg=${black_fg}
    hi Keyword gui=italic
    hi LineNr guibg=${white_bg} guifg=${black_bg}
    hi MatchParen gui=bold guifg=${red_fg}
    hi NonText ctermfg=red guifg=red cterm=bold gui=bold
    hi NonText guifg=${foreground}
    hi Normal guifg=${foreground} guibg=${background}
    hi Search gui=bold,underline guifg=${yellow_fg}
    hi SpellBad NONE cterm=undercurl gui=undercurl guifg=${red_fg}
    hi StatusLine gui=NONE guibg=#222222 guifg=#ffffff
    hi StatusLineNC gui=NONE guibg=${black_fg} guifg=${foreground}
    hi VertSplit guifg=${white_bg}
    hi Visual guibg=${white_bg}

    " indent guides
    let g:indent_guides_auto_colors = 0
    autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd ctermbg=NONE guibg=NONE
    autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=15 guibg=${white_bg}

    " NERD Tree
    hi NERDTreeCWD ctermfg=8 guifg=${black_bg}
    hi NERDTreeClosable ctermfg=8 guifg=${black_bg} | hi NERDTreeOpenable ctermfg=8 guifg=${black_bg}

    set foldcolumn=3

    set autoread
  '';
in {
  environment.systemPackages = [ (with pkgs; neovim.override {
    vimAlias = true;
    configure.vam = {
      knownPlugins = vimPlugins // plugins;

      pluginDictionaries = [
        { name = "commentary"; }
        # { name = "floobits-neovim"; }
        # { name = "fzf-vim"; }
        { name = "neovim-fuzzy"; }
        { name = "nerdtree"; }
        { name = "parinfer-rust"; }
        { name = "spell-fr"; }
        { name = "spell-ro"; }
        { name = "supertab"; }
        { name = "surround"; }
        { name = "vim-autoclose"; }
        { name = "vim-better-whitespace"; }
        { name = "vim-bracketed-paste"; }
        { name = "vim-eunuch"; }
        { name = "vim-indent-guides"; }
        { name = "vim-indent-object"; }
        { name = "vim-nix"; }
        { name = "vim-iced"; }
      ];
    };
    configure.customRC = rc;
  }) ];
}
