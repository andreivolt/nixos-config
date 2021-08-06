{ pkgs, ... }:

let
  theme = import ../theme.nix;

  plugins = with pkgs; {
    parinfer-rust = vimUtils.buildVimPlugin {
      name = "parinfer";
      src = (rustPlatform.buildRustPackage rec {
        pname = "parinfer-rust";
        version = "0.4.3";

        src = fetchFromGitHub {
          owner = "eraserhd";
          repo = "parinfer-rust";
          rev = "v${version}";
          sha256 = "0hj5in5h7pj72m4ag80ing513fh65q8xlsf341qzm3vmxm3y3jgd";
        };

        cargoSha256 = "1lam4gwzcj6w0pyxf61l2cpbvvf5gmj2gwi8dangnhd60qhlnvrx";

        nativeBuildInputs = [ llvmPackages.clang ];
        buildInputs = [ llvmPackages.libclang ];
        LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";

        postInstall = ''
          mkdir -p $out/share/kak/autoload/plugins
          cp rc/parinfer.kak $out/share/kak/autoload/plugins/
          rtpPath=$out/share/vim-plugins/parinfer-rust
          mkdir -p $rtpPath/plugin
          sed "s,let s:libdir = .*,let s:libdir = '${placeholder "out"}/lib'," \
            plugin/parinfer.vim >$rtpPath/plugin/parinfer.vim
        '';

        meta = with lib; {
          description = "Infer parentheses for Clojure, Lisp, and Scheme";
          homepage = "https://github.com/eraserhd/parinfer-rust";
          license = licenses.isc;
          maintainers = with maintainers; [ eraserhd ];
        };
      }) + "/share/vim-plugins/parinfer-rust";
    };

    challenger-deep-theme = vimUtils.buildVimPlugin {
      name = "challenger-deep-theme";
      src = fetchFromGitHub {
        owner = "challenger-deep-theme";
        repo = "vim";
        rev = "b3109644b30f6a34279be7a7c9354360be207105";
        sha256 = "1q3zjp9p5irkwmnz2c3fk8xrpivkwv1kc3y5kzf1sxdrbicbqda8";
      };
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

  conf = with theme; ''
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


    " indent guides
    let g:indent_guides_auto_colors = 0
    autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd ctermbg=NONE guibg=NONE
    autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=15 guibg=${white_bg}

    " NERD Tree
    hi NERDTreeCWD ctermfg=8 guifg=${black_bg}
    hi NERDTreeClosable ctermfg=8 guifg=${black_bg} | hi NERDTreeOpenable ctermfg=8 guifg=${black_bg}

    set autoread

    set title

    set guifont=Ubuntu\ Mono:h36
    let g:neovide_cursor_animation_length=0.02
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
      # { name = "rainbow"; }
    ];
  };
  configure.customRC = conf;
}
