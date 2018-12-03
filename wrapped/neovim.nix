self: super: with super; {

neovim =
  let neovim-custom = neovim.override {
    vimAlias = true;
    configure.vam = {
      knownPlugins = vimPlugins // {
        parinfer-rust = vimUtils.buildVimPlugin {
          name = "parinfer";
          src = fetchFromGitHub {
            owner = "eraserhd"; repo = "parinfer-rust";
            rev = "642fec5698f21758029988890c6683763beee5fd"; sha256 = "09gr3klm057l0ix9l4qxg65s2pw669k9l4prrr9gp7z30q1y5bi8"; };
          buildPhase = "HOME=$TMP ${cargo}/bin/cargo build --release"; };

        vim-bracketed-paste = vimUtils.buildVimPlugin {
          name = "vim-bracketed-paste";
          src = fetchFromGitHub {
            owner = "ConradIrwin"; repo = "vim-bracketed-paste";
            rev = "c4c639f3cacd1b874ed6f5f196fac772e089c932"; sha256 = "1hhi7ab36iscv9l7i64qymckccnjs9pzv0ccnap9gj5xigwz6p9h"; }; };

        paredit = vimUtils.buildVimPlugin {
          name = "paredit.vim";
          src = fetchFromGitHub {
            owner = "vim-scripts"; repo = "paredit.vim";
            rev = "791c3a0cc3155f424fba9409a9520eec241c189c"; sha256 = "15lg33bgv7afjikn1qanriaxmqg4bp3pm7qqhch6105r1sji9gz9"; }; };

        unimpaired = vimUtils.buildVimPlugin {
          name = "unimpaired.vim";
          src = fetchFromGitHub {
            owner = "tpope"; repo = "vim-unimpaired";
            rev = "d6325994b3c16ce36fd494c47dae4dab8d21a3da"; sha256 = "0l5g3xq0azplaq3i2rblg8d61czpj47k0126zi8x48na9sj0aslv"; };
          buildInputs = [ sharutils ]; };

        vimpager = vimUtils.buildVimPlugin {
          name = "vimpager";
          src = fetchFromGitHub {
            owner = "rkitover"; repo = "vimpager";
            rev = "82619297ca1533ffe72d1ea27131d7302164d47a"; sha256 = "0ip1ncl34j7lzxyv1r6z58fk7jkxjs2vdwk1vs77icxsg61y746v"; };
          buildInputs = [ sharutils ]; };

        vim-better-whitespace = vimUtils.buildVimPlugin {
          name = "vim-better-whitespace";
          src = fetchFromGitHub {
            owner = "ntpeters"; repo = "vim-better-whitespace";
            rev = "984c8da518799a6bfb8214e1acdcfd10f5f1eed7"; sha256 = "10l01a8xaivz6n01x6hzfx7gd0igd0wcf9ril0sllqzbq7yx2bbk"; }; };

        spell-ro = vimUtils.buildVimPlugin {
          name = "spell-ro";
          src = [(builtins.fetchurl ftp://ftp.vim.org/pub/vim/runtime/spell/ro.utf-8.spl)];
          unpackPhase = "true";
          buildPhase = "mkdir -p $out/spell && cp $src $out/spell/ro.utf-8.spl"; };

        spell-fr = vimUtils.buildVimPlugin {
          name = "spell-fr";
          src = [(builtins.fetchurl ftp://ftp.vim.org/pub/vim/runtime/spell/fr.utf-8.spl)];
          unpackPhase = "true";
          buildPhase = "mkdir -p $out/spell && cp $src $out/spell/fr.utf-8.spl"; };

        vim-ls = vimUtils.buildVimPlugin {
          name = "vim-ls";
          src = fetchFromGitHub {
            owner = "gkz"; repo = "vim-ls";
            rev = "795568338ecdc5d8059db2eb84c7f0de3388bae3"; sha256 = "0p3dbwfsqhhzh7icsiaa7j09zp5r8j7xrcaw6gjxcxqlhv86jaa1"; }; };

        vim-autoclose = vimUtils.buildVimPlugin {
          name = "vim-autoclose";
          src = fetchFromGitHub {
            owner = "Townk"; repo = "vim-autoclose";
            rev = "a9a3b7384657bc1f60a963fd6c08c63fc48d61c3"; sha256 = "12jk98hg6rz96nnllzlqzk5nhd2ihj8mv20zjs56p3200izwzf7d"; }; };

        vim-rooter = vimUtils.buildVimPlugin {
          name = "vim-rooter";
          src = fetchFromGitHub {
            owner = "airblade"; repo = "vim-rooter";
            rev = "42a97c624f4f9465703558bf004b013bc36facdb"; sha256 = "0ivvc3w2gd317j79zcc73bjmp99w99cls0gj4f7vnbpfh34gmjmj"; }; }; };

      pluginDictionaries = [
        { name = "commentary"; }
        { name = "fzf-vim"; }
        { name = "fzfWrapper"; }
        { name = "gitgutter"; }
        { name = "goyo"; }
        { name = "nerdtree"; }
        # { name = "parinfer-rust"; }
        { name = "spell-fr"; }
        { name = "spell-ro"; }
        { name = "supertab"; }
        { name = "surround"; }
        { name = "undotree"; }
        { name = "unimpaired"; }
        { name = "vim-autoclose"; }
        { name = "vim-better-whitespace"; }
        { name = "vim-bracketed-paste"; }
        { name = "vim-eunuch"; }
        { name = "vim-indent-object"; }
        { name = "vim-nix"; }
        { name = "vim-rooter"; } ]; };

    configure.customRC = with (import /etc/nixos/theme.nix).dark; let
      _settings = ''
        set noswapfile

        set hidden

        set title

        set linebreak " don't cut words on wrap

        set clipboard=unnamedplus

        set wildmode=longest,list,full

        set grepprg=${ripgrep}/bin/rg\ --smart-case\ --vimgrep

        set
          \ autoindent
          \ smartindent
          \ breakindent

        set
          \ ignorecase
          \ smartcase
          \ infercase

        set
          \ shiftwidth=2
          \ shiftround
          \ expandtab
          \ tabstop=2

        set gdefault " default replace to global
        set inccommand=nosplit

        set mouse=a

        let mapleader = "\<Space>"
        let maplocalleader = ","

        nnoremap gV '[V'] " select last inserted text

        map <silent> <leader>n :set number!<CR>'';

      disable-git-gutter-by-default = ''
        let g:gitgutter_enabled = 0'';

      better-whitespace = ''
        let b:better_whitespace_enabled = 1
        let g:strip_whitelines_at_eof = 1'';

      hide-messages-after-timeout = ''
        set updatetime=2000
        autocmd CursorHold * redraw!'';

      lisp = ''
        set iskeyword+=-'';

      _ui = with (import ../theme.nix).dark; ''
        set termguicolors

        set noruler

        for i in [
          \ 'Boolean',
          \ 'Character',
          \ 'Comment',
          \ 'Conceal',
          \ 'Conditional',
          \ 'Constant',
          \ 'Cursor',
          \ 'Cursor2',
          \ 'CursorLine',
          \ 'Debug',
          \ 'Define',
          \ 'Delimiter',
          \ 'Directory',
          \ 'Error',
          \ 'ErrorMsg',
          \ 'Exception',
          \ 'Float',
          \ 'FoldColumn',
          \ 'Function',
          \ 'Identifier',
          \ 'Ignore',
          \ 'IncSearch',
          \ 'Include',
          \ 'Keyword',
          \ 'Label',
          \ 'Macro',
          \ 'MatchParen',
          \ 'Normal',
          \ 'Number',
          \ 'Operator',
          \ 'PreCondit',
          \ 'PreProc',
          \ 'Repeat',
          \ 'Search',
          \ 'SignColumn',
          \ 'Special',
          \ 'SpecialChar',
          \ 'SpecialComment',
          \ 'SpellBad',
          \ 'Statement',
          \ 'StorageClass',
          \ 'String',
          \ 'Structure',
          \ 'Tag',
          \ 'Title',
          \ 'Todo',
          \ 'Type',
          \ 'Typedef',
          \ 'Underlined',
          \ 'VertSplit',
          \ 'WarningMsg',
          \]
          exe 'hi ' . i . ' NONE'
        endfor

        hi Comment ctermfg=5 guifg=${color5}
        hi Delimiter ctermfg=8 guifg=${color8}
        hi EndOfBuffer ctermfg=15 guifg=${color15}
        hi Folded ctermbg=15 ctermfg=7 guibg=${color15} guifg=${color7}
        hi IncSearch cterm=bold gui=bold ctermbg=3 ctermfg=0 guibg=${color3} guifg=${color0}
        hi Keyword cterm=bold gui=bold
        hi LineNr ctermbg=15 ctermfg=8 guibg=${color15} guifg=${color8}
        hi MatchParen cterm=bold gui=bold ctermfg=4 guifg=${color4}
        hi NonText ctermfg=15 guifg=${color15}
        hi Normal ctermfg=7 guifg=${color7}
        hi Search cterm=bold,underline gui=bold,underline ctermfg=3 guifg=${color3}
        hi SpellBad NONE cterm=undercurl gui=undercurl ctermfg=1 guifg=${color1}
        hi String ctermfg=8 guifg=${color8}
        hi VertSplit ctermfg=15 guifg=${color15}
        hi Visual ctermbg=15 guibg=${color15}

        set fillchars=stl:\ ,stlnc:\ ,vert:│

        set foldcolumn=1 | hi FoldColumn NONE

        set showmatch

        set
          \ laststatus=1
          \ noshowmode

        hi Cursor guibg=${red}
        hi Cursor2 guibg=${blue}
        set guicursor=n-v-c:block-Cursor/lCursor,i-ci-ve:ver25-Cursor2/lCursor2,r-cr:hor20,o:hor50'';

      fzf = ''
        let $FZF_DEFAULT_COMMAND = '${self.ripgrep}/bin/rg --files --follow -g "!{.git}/*" 2>/dev/null'

        nnoremap <silent> <leader>b :Buffers<CR>
        nnoremap <silent> <leader>f :Files<CR>

        autocmd! FileType fzf
        autocmd FileType fzf set laststatus=0 noshowmode noruler foldcolumn=0
          \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler foldcolumn=1

        let g:fzf_colors =
        \ { 'fg':      ['fg', 'Normal'],
          \ 'bg':      ['bg', 'Normal'],
          \ 'hl':      ['fg', 'Search'],
          \ 'fg+':     ['fg', 'Normal', 'Normal', 'Normal'],
          \ 'bg+':     ['bg', 'Normal', 'Normal'],
          \ 'hl+':     ['fg', 'Search'],
          \ 'info':    ['fg', 'Normal'],
          \ 'border':  ['fg', 'Normal'],
          \ 'prompt':  ['fg', 'Normal'],
          \ 'pointer': ['fg', 'Normal'],
          \ 'marker':  ['fg', 'Normal'],
          \ 'spinner': ['fg', 'Normal'],
          \ 'header':  ['fg', 'Normal'] }'';

      nerdtree = ''
        let NERDTreeMapActivateNode='<tab>'

        map <silent> <leader>e :NERDTreeToggle %<CR>:wincmd=<CR>

        let g:NERDTreeDirArrowExpandable = '+'| let g:NERDTreeDirArrowCollapsible = '-'

        let g:NERDTreeMinimalUI = 1

        hi NERDTreeCWD ctermfg=8 guifg=${color8}
        hi NERDTreeClosable ctermfg=8 guifg=${color8} | hi NERDTreeOpenable ctermfg=8 guifg=${color8}

        let NERDTreeAutoDeleteBuffer=1

        " autocmd BufWritePost * NERDTreeFocus | execute 'normal R' | wincmd p
        " exists('t:NERDTreeBufName') && bufwinnr(t:NERDTreeBufName) != -1
        " autocmd BufWinEnter * silent! NERDTreeFind'';

      use-very-magic-patterns = ''
        nnoremap / /\v
        vnoremap / /\v'';

      clear-search-highlight = ''
        nnoremap <silent><esc> :nohlsearch<return><esc>
        nnoremap <esc>^[ <esc>^['';

      navigate-arg-list = ''
        nnoremap <leader>an :next<cr>
        nnoremap <leader>ap :prev<cr>'';

      navigate-quick-fix = ''
        nnoremap <leader>cn :cnext<cr>
        nnoremap <leader>cp :cprev<cr>'';

      rebalance-splits-on-resize = ''
        autocmd VimResized * wincmd ='';

      statusline = ''
        set statusline=\ %f

        hi StatusLine cterm=bold gui=bold ctermbg=4 ctermfg=7 gui=NONE guibg=${color4} guifg=${color7}
        hi StatusLineNC cterm=bold gui=bold ctermbg=15 ctermfg=8 gui=NONE guibg=${color15} guifg=${color8}'';

      turn-on-spell-checking-for-text-files = ''
        autocmd FileType mail,markdown,text setlocal spell'';

      window-mappings = ''
        nmap <silent> <C-h> :wincmd h<CR>
        nmap <silent> <C-j> :wincmd j<CR>
        nmap <silent> <C-k> :wincmd k<CR>
        nmap <silent> <C-l> :wincmd l<CR>'';

      reload-buffers-when-changed-externally = ''
        " Triger `autoread` when files changes on disk
        " https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim/383044#383044
        " https://vi.stackexchange.com/questions/13692/prevent-focusgained-autocmd-running-in-command-line-editing-mode
        autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * if mode() != 'c' | checktime | endif
        " Notification after file change
        " https://vi.stackexchange.com/questions/13091/autocmd-event-for-autoread
        autocmd FileChangedShellPost *
          \ echohl WarningMsg | echo "File changed on disk. Buffer reloaded." | echohl None'';

      goyo = ''
        let g:goyo_width = 140
        let g:goyo_height = "100%"'';

      supertab = ''
        let g:SuperTabDefaultCompletionType = "context"
        let g:SuperTabLongestEnhanced = 1
        let g:SuperTabLongestHighlight = 0'';

      buffer-navigation = ''
        nnoremap gn :bnext<CR>
        nnoremap gN :bprevious<CR>
        nnoremap gd :bdelete<CR>
        nnoremap gf <C-^>'';

      unimpaired = ''
        nmap < [
        nmap > ]
        omap < [
        omap > ]
      '';

      return-to-last-position-when-opening-files = ''
        augroup LastPosition
          autocmd! BufReadPost *
            \ if line("'\"") > 0 && line("'\"") <= line("$") |
            \   exe "normal! g`\"" |
            \ endif
        augroup END'';

    in lib.concatStringsSep "\n" [
      _settings
      _ui
      better-whitespace
      buffer-navigation
      clear-search-highlight
      disable-git-gutter-by-default
      unimpaired
      fzf
      goyo
      lisp
      hide-messages-after-timeout
      navigate-arg-list
      navigate-quick-fix
      nerdtree
      rebalance-splits-on-resize
      reload-buffers-when-changed-externally
      return-to-last-position-when-opening-files
      statusline
      supertab
      turn-on-spell-checking-for-text-files
      use-very-magic-patterns
      window-mappings ]; };
  in let terminal-bg-change-wrapper = ''
    #!/usr/bin/env bash

    printf '\033]11;#111111\007'

    cleanup() {
      printf '\033]11;#000000\007'
      exit
    }

    trap cleanup EXIT INT TERM

    exec ${neovim-custom}/bin/nvim "$@"'';
  in hiPrio (stdenv.lib.overrideDerivation neovim-custom (attrs: { postInstall = "cp ${writeScript "wrapper" terminal-bg-change-wrapper} $out/bin/vim_terminal-bg-change-wrapper"; }));

}
