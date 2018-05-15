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
      vam =
        let
          mkColorScheme = name: ''
            hi clear
            syntax reset

            let g:colors_name="${name}"

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
              \ 'Cursor',
              \ 'CursorLine',
              \ 'CursorLineNR',
              \]
              exe 'hi ' . i . ' NONE ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE'
            endfor
          '';

          customPlugins.colorscheme-acme = pkgs.vimUtils.buildVimPlugin {
            name = "colorscheme-acme";
            src = [
              (pkgs.writeTextFile {
                name = "acme.vim";
                text = (with import ../themes/acme.nix; ''
                  ${mkColorScheme "acme"}

                  hi Comment      cterm=italic    ctermfg=15              gui=italic guifg=${lightWhite}
                  hi Cursor ctermfg=0 guibg=${highlight}
                  hi CursorLine                              ctermbg=0                                     guibg=${subtleHighlight}
                  hi CursorLineNR                 ctermfg=15                         guifg=${gray}         guibg=${subtleHighlight}
                  hi Delimiter                    ctermfg=8                          guifg=${important}
                  hi EndOfBuffer                  ctermfg=8                          guifg=${foregroundFaded}
                  hi FoldColumn   NONE
                  hi LineNr                       ctermfg=8                          guifg=${foregroundFaded}
                  hi MatchParen   cterm=reverse              ctermbg=NONE                                guibg=NONE
                  hi NonText                      ctermfg=3                          guifg=${yellow}
                  hi Normal                       ctermfg=15                         guifg=${lightWhite}
                  hi Search                                  ctermbg=11                                  guibg=${lightYellow}
                  hi SpellBad     cterm=underline ctermfg=1  ctermbg=NONE                                guibg=NONE
                  hi StatusLine                   ctermfg=8  ctermbg=8               guifg=${yellow}   guibg=${darkGray}
                  hi StatusLineNC                 ctermfg=8  ctermbg=0               guifg=${lightYellow}  guibg=${gray}
                  hi Visual                                  ctermbg=8                                   guibg=${selection}
                '');
                destination = "/colors/acme.vim";
              })
            ];
          };

          customPlugins.colorscheme-challenger-deep-monochrome = pkgs.vimUtils.buildVimPlugin {
            name = "colorscheme-challenger-deep-monochrome";
            src = [
              (pkgs.writeTextFile {
                name = "challenger-deep-monochrome.vim";
                text = (with import ../themes/challenger-deep.nix; ''
                  ${mkColorScheme "challenger-deep-monochrome"}

                  hi Comment      cterm=italic    ctermfg=15              gui=italic guifg=${lightWhite}
                  hi CursorLine                              ctermbg=0
                  hi CursorLineNR                 ctermfg=15                                             guibg={lightWhite}
                  hi EndOfBuffer                  ctermfg=8                          guifg={gray}
                  hi FoldColumn   NONE
                  hi LineNr                       ctermfg=8                          guifg=${gray}
                  hi MatchParen   cterm=reverse              ctermbg=NONE                                guibg=NONE
                  hi NonText                      ctermfg=3                          guifg=${yellow}
                  hi Normal                       ctermfg=15                         guifg=${lightWhite}
                  hi Search                                  ctermbg=11                                  guibg=${yellow}
                  hi SpellBad     cterm=underline ctermfg=1  ctermbg=NONE                                guibg=NONE
                  hi StatusLine                   ctermfg=8  ctermbg=8                                   guibg=${gray}
                  hi StatusLineNC                 ctermfg=8  ctermbg=0                                   guibg=${black}
                  hi Visual                                  ctermbg=8                                   guibg=${gray}
                '');
                destination = "/colors/challenger-deep-monochrome.vim";
              })
            ];
          };

          customPlugins.golden-ratio = pkgs.vimUtils.buildVimPlugin {
            name = "golden-ratio";
            src = pkgs.fetchFromGitHub {
              owner = "roman";
              repo = "golden-ratio";
              rev = "2e085355f2c1d0842b649a963958c21e6815ffc5";
              sha256 = "1n2mhvbi1qmxkc2gc8yxljr5f90pa0wsbggh4hdsx5ry4v940smq";
            };
          };

          customPlugins.vim-better-whitespace = pkgs.vimUtils.buildVimPlugin {
            name = "vim-better-whitespace";
            src = pkgs.fetchFromGitHub {
              owner = "ntpeters";
              repo = "vim-better-whitespace";
              rev = "984c8da518799a6bfb8214e1acdcfd10f5f1eed7";
              sha256 = "10l01a8xaivz6n01x6hzfx7gd0igd0wcf9ril0sllqzbq7yx2bbk";
            };
          };

          customPlugins.vim-ls = pkgs.vimUtils.buildVimPlugin {
            name = "vim-ls";
            src = pkgs.fetchFromGitHub {
              owner = "gkz";
              repo = "vim-ls";
              rev = "795568338ecdc5d8059db2eb84c7f0de3388bae3";
              sha256 = "0p3dbwfsqhhzh7icsiaa7j09zp5r8j7xrcaw6gjxcxqlhv86jaa1";
            };
          };

          customPlugins.vim-autoclose = pkgs.vimUtils.buildVimPlugin {
            name = "vim-autoclose";
            src = pkgs.fetchFromGitHub {
              owner = "Townk";
              repo = "vim-autoclose";
              rev = "a9a3b7384657bc1f60a963fd6c08c63fc48d61c3";
              sha256 = "12jk98hg6rz96nnllzlqzk5nhd2ihj8mv20zjs56p3200izwzf7d";
            };
          };

        in {
          knownPlugins = pkgs.vimPlugins // customPlugins;
          pluginDictionaries = [
            { name = "colorscheme-acme"; }
            { name = "colorscheme-challenger-deep-monochrome"; }
            { name = "commentary"; }
            { name = "easy-align"; }
            { name = "fzf-vim"; }
            { name = "fzfWrapper"; }
            { name = "gitgutter"; }
            { name = "golden-ratio"; }
            { name = "goyo"; }
            { name = "supertab"; }
            { name = "surround"; }
            { name = "undotree"; }
            { name = "vim-autoclose"; }
            { name = "vim-better-whitespace"; }
            { name = "vim-eunuch"; }
            { name = "vim-indent-guides"; }
            { name = "vim-ls"; }
          ];
        };

      customRC = let
        settings = ''
          set
            \ title
            \ hidden
            \ lazyredraw
            \ linebreak " don't cut words on wrap

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
        '';

        BetterWhitespace = ''
          " Plug 'ntpeters/vim-better-whitespace'
          "   let b:better_whitespace_enabled = 0
          "   let g:strip_whitelines_at_eof = 1
        '';

        hideMessagesAfterTimeout = ''
          set updatetime=2000
          autocmd CursorHold * redraw!
        '';

        fzf = ''
          let $FZF_DEFAULT_COMMAND = '${pkgs.ripgrep}/bin/rg --files --hidden --follow -g "!{.git}/*" 2>/dev/null'
          nnoremap <silent> <leader>b :Buffers<CR>
          nnoremap <silent> <leader>f :Files<CR>

          let g:fzf_colors =
          \ { 'fg':      ['fg', 'Normal'],
            \ 'bg':      ['bg', 'StatusLine'],
            \ 'hl':      ['fg', 'Comment'],
            \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
            \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
            \ 'hl+':     ['fg', 'Statement'],
            \ 'info':    ['fg', 'PreProc'],
            \ 'border':  ['fg', 'Visual'],
            \ 'prompt':  ['fg', 'Conditional'],
            \ 'pointer': ['fg', 'Exception'],
            \ 'marker':  ['fg', 'Keyword'],
            \ 'spinner': ['fg', 'Label'],
            \ 'header':  ['fg', 'Comment'] }
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
          nnoremap <silent><esc> :nohlsearch<return><esc>
          nnoremap <esc>^[ <esc>^[
        '';

        navigateQuickFix = ''
          nnoremap <leader>cn :cnext<cr>| nnoremap <leader>cp :cprev<cr>
          nnoremap <leader>an :next<cr> | nnoremap <leader>ap :prev<cr>
        '';

        rebalanceSplitsOnResize = ''
          autocmd VimResized * wincmd =
        '';

        minimalMode = ''
          let g:golden_ratio_autocommand = 0
          function MinimalMode()
            Goyo 130
          endfunction
        '';

        acmeMinimalMode = ''
          function AcmeMinimalMode()
            call MinimalMode()
            colorscheme acme
          endfunction
        '';

        cursor = ''
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
          set termguicolors
          colorscheme challenger-deep-monochrome

          set showmatch

          set
            \ laststatus=1
            \ noshowmode

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

      in lib.concatStringsSep "\n" [
        settings

        BetterWhitespace
        SuperTab
        bufferNavigation
        clearSearchHighlight
        cursor
        fzf
        highlightCurrentLineInNormalMode
        minimalMode acmeMinimalMode
        navigateQuickFix
        rebalanceSplitsOnResize
        returnToLastPositionWhenOpeningFiles
        ui
        useVeryMagicPatterns
        hideMessagesAfterTimeout
      ];
    };
  }) ];

  home-manager.users.avo
    .programs.zsh.shellAliases.vi = "nvim";
}
