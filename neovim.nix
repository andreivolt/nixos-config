{ pkgs, ... }:

# let
#   customPlugins.monochrome-colors = pkgs.vimUtils.buildVimPlugin {
#     name = "monochrome-colors";
#     src = pkgs.writeText "monochrome.vim" ''
#       hi clear
#       syntax reset

#       let colors_name="monochrome"

#       for i in [
#         \ 'WarningMsg',
#         \ 'Boolean',
#         \ 'Character',
#         \ 'Comment',
#         \ 'Conceal',
#         \ 'Conditional',
#         \ 'Constant',
#         \ 'Debug',
#         \ 'Define',
#         \ 'Delimiter',
#         \ 'Directory',
#         \ 'Error',
#         \ 'ErrorMsg',
#         \ 'Exception',
#         \ 'Float',
#         \ 'Function',
#         \ 'Identifier',
#         \ 'Ignore',
#         \ 'Include',
#         \ 'Keyword',
#         \ 'Label',
#         \ 'Macro',
#         \ 'Normal',
#         \ 'Number',
#         \ 'Operator',
#         \ 'PreCondit',
#         \ 'PreProc',
#         \ 'Repeat',
#         \ 'SignColumn',
#         \ 'Special',
#         \ 'SpecialChar',
#         \ 'SpecialComment',
#         \ 'Statement',
#         \ 'StorageClass',
#         \ 'String',
#         \ 'Structure',
#         \ 'Tag',
#         \ 'Todo',
#         \ 'Type',
#         \ 'Typedef',
#         \ 'Underlined',
#         \ 'VertSplit',
#         \ 'CursorLine',
#         \]
#         exe 'hi ' . i . ' NONE ctermbg=NONE ctermfg=NONE'
#       endfor

#       hi Comment      cterm=italic    ctermfg=15
#       hi CursorLine                              ctermbg=8
#       hi CursorLineNR                 ctermfg=15
#       hi EndOfBuffer                  ctermfg=8
#       hi FoldColumn   NONE
#       hi LineNr                       ctermfg=8
#       hi MatchParen   cterm=reverse              ctermbg=NONE
#       hi NonText                      ctermfg=3
#       hi Normal                       ctermfg=15
#       hi Search                                  ctermbg=11
#       hi SpellBad     cterm=underline ctermfg=1  ctermbg=NONE
#       hi StatusLine                   ctermfg=8  ctermbg=8
#       hi StatusLineNC                 ctermfg=8  ctermbg=0
#       hi Visual                                  ctermbg=8
#     '';
#   };

# pkgs.fetchFromGitHub {
#       owner = "ntpeters";
#       repo = "vim-better-whitespace";
#       rev = "984c8da518799a6bfb8214e1acdcfd10f5f1eed7";
#       sha256 = "10l01a8xaivz6n01x6hzfx7gd0igd0wcf9ril0sllqzbq7yx2bbk";
#     };
#   };

# in {
#    users.users.<yourNickname>.packages = [
#     (pkgs.vim_configurable.customize {
#       name = "vim";
#       vimrcConfig.vam.knownPlugins = pkgs.vimPlugins // customPlugins;
#       vimrcConfig.vam.pluginDictionaries = [
#         { names = "vim-better-whitespace" ]; } ]
#     })
# };

{
  environment.systemPackages = with pkgs; [ (neovim.override {
    vimAlias = true;
    configure = {
      vam = {
        knownPlugins = pkgs.vimPlugins; # // customPlugins;
        pluginDictionaries = [
          # { name = "vim-autoclose"; }
          # { name = "vim-better-whitespace"; }
          { name = "commentary"; }
          # { name = "monochrome-colors"; }
          { name = "easy-align"; }
          { name = "fzfWrapper"; }
          { name = "fzf-vim"; }
          { name = "gitgutter"; }
          { name = "goyo"; }
          { name = "supertab"; }
          { name = "surround"; }
          { name = "undotree"; }
          { name = "vim-eunuch"; }
          { name = "vim-indent-guides"; }
        ];
      };

      customRC = let
        settings = ''
          set
            \ title
            \ hidden
            \ lazyredraw
            \ linebreak " don't cut words on wrap

          set showmatch

          set autoread

          set clipboard=unnamedplus

          set wildmode=longest,list,full

          set
            \ grepprg=${pkgs.ripgrep}/bin/rg\ --smart-case\ --vimgrep

          set
            \ autoindent
            \ smartindent
            \ breakindent

          set
            \ ignorecase
            \ smartcase
            \ infercase

          set
            \ foldmethod=marker
            \ foldlevel=1
            \ foldlevelstart=99 " open folds by default

          set
            \ shiftwidth=2
            \ shiftround
            \ expandtab
            \ tabstop=2

          set gdefault " default replace to global

          let mapleader = "\<Space>"

          nnoremap gV '[V'] " select last inserted text

          set mouse=a

          set noshowmode
        '';

        BetterWhitespace = ''
          " Plug 'ntpeters/vim-better-whitespace'
          "   let b:better_whitespace_enabled = 0
          "   let g:strip_whitelines_at_eof = 1
        '';

        fzf = ''
          let $FZF_DEFAULT_COMMAND = '${pkgs.ripgrep}/bin/rg --files --hidden --follow -g "!{.git}/*" 2>/dev/null'
          nnoremap <silent> <leader>b :Buffers<CR>
          nnoremap <silent> <leader>f :Files<CR>
        '';

        highlightCurrentLineInNormalMode = ''
          set cursorline
          autocmd InsertEnter * set nocursorline
          autocmd InsertLeave * set cursorline
        '';

        useVeryMagicPatterns = ''
          nnoremap / /\v
          vnoremap / /\v
        '';

        clearSearchHighlight = ''
          nnoremap <esc> :nohlsearch<return><esc>
          nnoremap <esc>^[ <esc>^[
        '';

        navigateQuickFix = ''
          nnoremap <leader>cn :cnext<cr>| nnoremap <leader>cp :cprev<cr>
          nnoremap <leader>an :next<cr> | nnoremap <leader>ap :prev<cr>
        '';

        rebalanceSplitsOnResize = ''
          autocmd VimResized * wincmd =
        '';

        cursor = ''
          silent !echo -ne "\033]112\007"
          if exists('$TMUX')
            let &t_SI  = "\<Esc>Ptmux;\<Esc>\<Esc>]12;red\x7\<Esc>\\\<Esc>Ptmux;\<Esc>\<Esc>[5 q\<Esc>\\"
            let &t_EI  = "\<Esc>Ptmux;\<Esc>\<Esc>]12;black\x7\<Esc>\\\<Esc>Ptmux;\<Esc>\<Esc>[5 q\<Esc>\\"
            autocmd VimLeave * silent !printf "\033Ptmux;\033\033]12;grey\007\033\\"
          else
            autocmd BufEnter *
            \ let &t_SI  = "\<Esc>]12;red\x7\<Esc>[5 q" |
            \ let &t_EI  = "\<Esc>]12;black\x7\<Esc>[5 q"
            autocmd VimLeave * silent !echo -ne "\033]112\007"
          endif

          set guicursor=n-v-c:block-Cursor/lCursor-blinkon0,i-ci:ver25-Cursor/lCursor,r-cr:hor20-Cursor/lCursor
        '';

        SuperTab = ''
          let g:SuperTabDefaultCompletionType = "context"
          let g:SuperTabLongestEnhanced = 1
          let g:SuperTabLongestHighlight = 0
        '';

        bufferNavigation = ''
          nnoremap gn :bnext<CR>
          nnoremap gN :bprevious<CR>
          nnoremap gd :bdelete<CR>
          nnoremap gf <C-^>
        '';

        ui = ''
          " colorscheme monochrome

          set fillchars=stl:\ ,stlnc:\ ,vert:│ | hi VertSplit NONE
          set foldcolumn=1 | hi FoldColumn NONE
        '';

        returnToLastPositionWhenOpeningFiles = ''
          augroup LastPosition
              autocmd! BufReadPost *
                  \ if line("'\"") > 0 && line("'\"") <= line("$") |
                  \     exe "normal! g`\"" |
                  \ endif
          augroup END
        '';

        colorscheme = ''
          hi clear
          syntax reset

          let colors_name="monochrome"

          for i in [
            \ 'WarningMsg',
            \ 'Boolean',
            \ 'Character',
            \ 'Comment',
            \ 'Conceal',
            \ 'Conditional',
            \ 'Constant',
            \ 'Debug',
            \ 'Define',
            \ 'Delimiter',
            \ 'Directory',
            \ 'Error',
            \ 'ErrorMsg',
            \ 'Exception',
            \ 'Float',
            \ 'Function',
            \ 'Identifier',
            \ 'Ignore',
            \ 'Include',
            \ 'Keyword',
            \ 'Label',
            \ 'Macro',
            \ 'Normal',
            \ 'Number',
            \ 'Operator',
            \ 'PreCondit',
            \ 'PreProc',
            \ 'Repeat',
            \ 'SignColumn',
            \ 'Special',
            \ 'SpecialChar',
            \ 'SpecialComment',
            \ 'Statement',
            \ 'StorageClass',
            \ 'String',
            \ 'Structure',
            \ 'Tag',
            \ 'Todo',
            \ 'Type',
            \ 'Typedef',
            \ 'Underlined',
            \ 'VertSplit',
            \ 'CursorLine',
            \]
            exe 'hi ' . i . ' NONE ctermbg=NONE ctermfg=NONE'
          endfor

          hi Comment      cterm=italic    ctermfg=15
          hi CursorLine                              ctermbg=8
          hi CursorLineNR                 ctermfg=15
          hi EndOfBuffer                  ctermfg=8
          hi FoldColumn   NONE
          hi LineNr                       ctermfg=8
          hi MatchParen   cterm=reverse              ctermbg=NONE
          hi NonText                      ctermfg=3
          hi Normal                       ctermfg=15
          hi Search                                  ctermbg=11
          hi SpellBad     cterm=underline ctermfg=1  ctermbg=NONE
          hi StatusLine                   ctermfg=8  ctermbg=8
          hi StatusLineNC                 ctermfg=8  ctermbg=0
          hi Visual                                  ctermbg=8
        '';
      in ''
        ${settings}
        ${BetterWhitespace}
        ${highlightCurrentLineInNormalMode}
        ${useVeryMagicPatterns}
        ${clearSearchHighlight}
        ${navigateQuickFix}
        ${rebalanceSplitsOnResize}
        ${cursor}
        ${SuperTab}
        ${fzf}
        ${bufferNavigation}
        ${colorscheme}
        ${ui}
        ${returnToLastPositionWhenOpeningFiles}
      '';
    };
  }) ];

  home-manager.users.avo
    .programs.zsh.shellAliases.vi = "nvim";
}
