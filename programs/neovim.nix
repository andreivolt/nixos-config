{ pkgs, ... }:

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
              \ 'Boolean',
              \ 'Character',
              \ 'Comment',
              \ 'Conceal',
              \ 'Conditional',
              \ 'Constant',
              \ 'Cursor',
              \ 'CursorLine',
              \ 'CursorLineNR',
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
              \ 'Todo',
              \ 'Type',
              \ 'Typedef',
              \ 'Underlined',
              \ 'VertSplit',
              \ 'WarningMsg',
              \]
              exe 'hi ' . i . ' NONE ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE'
            endfor
          '';

          customPlugins = {
            colorscheme-acme = pkgs.vimUtils.buildVimPlugin {
              name = "colorscheme-acme";
              src = [
                (pkgs.writeTextFile {
                  name = "acme.vim";
                  text = (with import ../themes/acme.nix; ''
                    ${mkColorScheme "acme"}

                    hi Comment      cterm=italic    ctermfg=15            gui=italic guifg=${foregroundSecondary}
                    hi Cursor                       ctermfg=0                                                       guibg=${highlight}
                    hi CursorLine                              ctermbg=0                                            guibg=${subtleHighlight}
                    hi CursorLineNR                 ctermfg=15                       guifg=${gray}                  guibg=${subtleHighlight}
                    hi EndOfBuffer                  ctermfg=8                        guifg=${foregroundUnimportant}
                    hi LineNr                       ctermfg=8                        guifg=${foregroundUnimportant}
                    hi MatchParen   cterm=reverse   ctermfg=8                        guifg=${highlight}
                    hi NonText                      ctermfg=3                        guifg=${yellow}
                    hi Normal                       ctermfg=15                       guifg=${lightWhite}
                    hi Search                                  ctermbg=11                                           guibg=${lightYellow}
                    hi SpellBad     cterm=underline ctermfg=1
                    hi StatusLine                   ctermfg=8  ctermbg=8                                            guibg=${highlight}
                    hi StatusLineNC                 ctermfg=8  ctermbg=0                                            guibg=${yellow}
                    hi Visual                                  ctermbg=8                                            guibg=${selection}

                    hi String                                                        guifg=${foregroundSecondary}
                    hi Delimiter                    ctermfg=8             gui=bold   guifg=${important}
                    hi Keyword                                            gui=italic
                    hi Conditional                                        gui=italic
                  '');
                  destination = "/colors/acme.vim";
                })
              ];
            };

            colorscheme-challenger-deep-monochrome = pkgs.vimUtils.buildVimPlugin {
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
                    hi LineNr                       ctermfg=8                          guifg=${gray}
                    hi MatchParen   cterm=reverse
                    hi NonText                      ctermfg=3                          guifg=${yellow}
                    hi Normal                       ctermfg=15                         guifg=${lightWhite}
                    hi Search                                  ctermbg=11                                  guibg=${yellow}
                    hi SpellBad     cterm=underline ctermfg=1  ctermbg=NONE                                guibg=NONE
                    hi StatusLine                   ctermfg=8  ctermbg=8                                   guibg=${gray}
                    hi StatusLineNC                 ctermfg=8  ctermbg=0                                   guibg=${black}
                    hi Visual                                  ctermbg=8                                   guibg=${gray}

                    hi rainbowParensShell1 guifg=#0000ff
                    hi rainbowParensShell2 guifg=#005ffe
                    hi rainbowParensShell3 guifg=#00bffe
                    hi rainbowParensShell4 guifg=#00fede
                    hi rainbowParensShell5 guifg=#00fe7f
                    hi rainbowParensShell6 guifg=#00fe1f
                    hi rainbowParensShell7 guifg=#3ffe00
                    hi rainbowParensShell8 guifg=#9ffe00
                    hi rainbowParensShell9 guifg=#fefe00
                    hi rainbowParensShell10 guifg=#fe9f00
                    hi rainbowParensShell11 guifg=#fe3f00
                    hi rainbowParensShell12 guifg=#fe001f
                    hi rainbowParensShell13 guifg=#fe007f
                    hi rainbowParensShell14 guifg=#fe00de
                    hi rainbowParensShell15 guifg=#be00fe
                    hi rainbowParensShell16 guifg=#5f00fe
                  '');
                  destination = "/colors/challenger-deep-monochrome.vim";
                })
              ];
            };

            parinfer-rust = pkgs.vimUtils.buildVimPlugin {
              name = "parinfer";
              src = pkgs.fetchFromGitHub {
                owner = "eraserhd";
                repo = "parinfer-rust";
                rev = "642fec5698f21758029988890c6683763beee5fd";
                sha256 = "09gr3klm057l0ix9l4qxg65s2pw669k9l4prrr9gp7z30q1y5bi8";
              };
              buildPhase = ''
                export HOME=$TMP
                ${pkgs.cargo}/bin/cargo build --release
              '';
            };

            vim-cljfmt = pkgs.vimUtils.buildVimPlugin {
              name = "vim-cljfmt";
              src = pkgs.fetchFromGitHub {
                owner = "venantius";
                repo = "vim-cljfmt";
                rev = "f4bbc04967202a2b94a0ebbb3485991489b9dcd4";
                sha256 = "09x5w55cw4zb5cjbh1d78hxmbagy9xw8p95qry21i1ydi7m0rmn5";
              };
            };

            vim-fireplace = pkgs.vimUtils.buildVimPlugin {
              name = "fireplace.vim";
              src = pkgs.fetchFromGitHub {
                owner = "tpope";
                repo = "vim-fireplace";
                rev = "1ef0f0726cadd96547a5f79103b66339f170da02";
                sha256 = "0ihhd34bl98xssa602386ji013pjj6xnkgww3y2wg73sx2nk6qc4";
              };
            };

            paredit = pkgs.vimUtils.buildVimPlugin {
              name = "paredit.vim";
              src = pkgs.fetchFromGitHub {
                owner = "vim-scripts";
                repo = "paredit.vim";
                rev = "791c3a0cc3155f424fba9409a9520eec241c189c";
                sha256 = "15lg33bgv7afjikn1qanriaxmqg4bp3pm7qqhch6105r1sji9gz9";
              };
            };

            golden-ratio = pkgs.vimUtils.buildVimPlugin {
              name = "golden-ratio";
              src = pkgs.fetchFromGitHub {
                owner = "roman";
                repo = "golden-ratio";
                rev = "2e085355f2c1d0842b649a963958c21e6815ffc5";
                sha256 = "1n2mhvbi1qmxkc2gc8yxljr5f90pa0wsbggh4hdsx5ry4v940smq";
              };
            };

            vim-better-whitespace = pkgs.vimUtils.buildVimPlugin {
              name = "vim-better-whitespace";
              src = pkgs.fetchFromGitHub {
                owner = "ntpeters";
                repo = "vim-better-whitespace";
                rev = "984c8da518799a6bfb8214e1acdcfd10f5f1eed7";
                sha256 = "10l01a8xaivz6n01x6hzfx7gd0igd0wcf9ril0sllqzbq7yx2bbk";
              };
            };

            vim-ls = pkgs.vimUtils.buildVimPlugin {
              name = "vim-ls";
              src = pkgs.fetchFromGitHub {
                owner = "gkz";
                repo = "vim-ls";
                rev = "795568338ecdc5d8059db2eb84c7f0de3388bae3";
                sha256 = "0p3dbwfsqhhzh7icsiaa7j09zp5r8j7xrcaw6gjxcxqlhv86jaa1";
              };
            };

            vim-autoclose = pkgs.vimUtils.buildVimPlugin {
              name = "vim-autoclose";
              src = pkgs.fetchFromGitHub {
                owner = "Townk";
                repo = "vim-autoclose";
                rev = "a9a3b7384657bc1f60a963fd6c08c63fc48d61c3";
                sha256 = "12jk98hg6rz96nnllzlqzk5nhd2ihj8mv20zjs56p3200izwzf7d";
              };
            };

            rainbow_parentheses = pkgs.vimUtils.buildVimPlugin {
              name = "rainbow_parentheses";
              src = pkgs.fetchFromGitHub {
                owner = "junegunn";
                repo = "rainbow_parentheses.vim";
                rev = "27e7cd73fec9d1162169180399ff8ea9fa28b003";
                sha256 = "0izbjq6qbia013vmd84rdwjmwagln948jh9labhly0asnhqyrkb8";
              };
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
            { name = "nerdtree"; }
            { name = "paredit"; }
            { name = "parinfer-rust"; }
            { name = "rainbow_parentheses"; }
            { name = "supertab"; }
            { name = "surround"; }
            { name = "undotree"; }
            { name = "vim-autoclose"; }
            { name = "vim-better-whitespace"; }
            { name = "vim-cljfmt"; }
            { name = "vim-easy-align"; }
            { name = "vim-eunuch"; }
            { name = "vim-fireplace"; }
            { name = "vim-indent-guides"; }
            { name = "vim-indent-object"; }
            { name = "vim-ls"; }
            { name = "vim-nix"; }
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

          set inccommand=nosplit

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
            \ 'bg':      ['bg', 'Normal'],
            \ 'hl':      ['fg', 'Normal'],
            \ 'fg+':     ['fg', 'Normal', 'Normal', 'Normal'],
            \ 'bg+':     ['bg', 'Normal', 'Normal'],
            \ 'hl+':     ['fg', 'Normal'],
            \ 'info':    ['fg', 'Normal'],
            \ 'border':  ['fg', 'Normal'],
            \ 'prompt':  ['fg', 'Normal'],
            \ 'pointer': ['fg', 'Normal'],
            \ 'marker':  ['fg', 'Normal'],
            \ 'spinner': ['fg', 'Normal'],
            \ 'header':  ['fg', 'Normal'] }

          " autocmd FileType fzf set laststatus=0
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

        goyo = ''
          let g:goyo_width=150
          let g:goyo_height='96%'

          function! s:goyo_enter()
            let g:golden_ratio_autocommand = 0
          endfunction

          function! s:goyo_leave()
            let g:golden_ratio_autocommand = 1
          endfunction

          autocmd! User GoyoEnter nested call <SID>goyo_enter() | autocmd! User GoyoLeave nested call <SID>goyo_leave()
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
        goyo
        hideMessagesAfterTimeout
        highlightCurrentLineInNormalMode
        minimalMode acmeMinimalMode
        navigateQuickFix
        rebalanceSplitsOnResize
        returnToLastPositionWhenOpeningFiles
        ui
        useVeryMagicPatterns
      ];
    };
  }) ];
}
