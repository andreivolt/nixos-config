{ lib, pkgs, ... }:

let
  theme = rec {
    background = "#000000"; foreground = "#ccccc";

    white_bg = "#707880"; white_fg = "#aaaaaa";
    black_bg = "#131313"; black_fg = "#373b41";

    blue_fg = "#0000ff"; blue_bg = "#81a2be";
    cyan_fg = "#5e8d87"; cyan_bg = "#8abeb7";
    green_fg = "#00ff00"; green_bg = "#3ec97d";
    red_fg = "#ff0000"; red_bg = "#c94e3e";
    yellow_fg = "#00ffff"; yellow_bg = "#f0c674";
    magenta_fg = "#85678f"; magenta_bg = "#b294bb";

    success = green_fg; warning = yellow_fg; error = red_fg;
    highlight_fg = blue_fg; highlight_bg = blue_bg;
    selection = white_fg;
  };

  waylandOverlay = import (builtins.fetchTarball "https://github.com/colemickens/nixpkgs-wayland/archive/master.tar.gz");
in {
  imports = [
    <home-manager/nixos>
    ./hardware-configuration.nix
  ];

  nixpkgs.overlays = [
    waylandOverlay
  ];

  programs.sway.enable = true;
  programs.sway.extraPackages = with pkgs; [
    gebaar-libinput  # libinput gestures utility
    glpaper          # GL shaders as wallpaper
    grim             # screen image capture
    mako
    redshift-wayland
    slurp
    swayidle
    swaylock
    waybar        # polybar-alike
    wayfire   # 3D wayland compositor
    wf-config # wayfire config manager
    wf-recorder      # wayland screenrecorder
    wl-clipboard     # clipboard CLI utilities
    wtype            # xdotool, but for wayland
    xwayland
  ];

  # printing
  environment.variables.PRINTER = "_";
  services.printing.enable = true;
  services.printing.clientConf = lib.mkAfter ''
    <Printer _>
      UUID urn:uuid:3c151d9e-3d44-3a04-59f9-5cdfbb513438
      MakeModel DCP-L2520DW series
      DeviceURI ipp://192.168.1./ipp/print
    </Printer>
  '';

  # audio
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.extraModules = [ pkgs.pulseaudio-modules-bt ];
  hardware.pulseaudio.package = pkgs.pulseaudioFull;
  hardware.pulseaudio.daemon.config = {
    flat-volumes = "no";
    resample-method = "soxr-vhq";
    avoid-resampling = "yes";
    default-sample-format = "s32le";
    default-sample-rate = "96000";
  };

  # automount removable devices
  services.devmon.enable = true;

  environment.variables.PATH = "$HOME/bin:$HOME/.local/share/npm/packages/bin:$PATH:${./.}";

  programs.npm.enable = true;
  programs.npm.npmrc = ''
    prefix = ~/.local/share/npm/packages
    cache = ~/.cache/npm/packages
  '';

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Paris";

  hardware.bluetooth.enable = true;
  hardware.opengl.enable = true;

  nix.buildCores = 0;
  nix.gc.automatic = true;
  nix.optimise.automatic = true;
  nix.useSandbox = false;

  users.users.avo.isNormalUser = true;
  users.users.avo.shell = pkgs.zsh;
  users.users.avo.extraGroups = [
    "wheel"
    "adbusers"
  ];

  security.sudo.wheelNeedsPassword = false;

  networking.hostName = builtins.getEnv "HOSTNAME";

  nixpkgs.config.allowUnfree = true;

  # grep colors
  environment.variables.GREP_COLOR = "1";
  programs.zsh.shellAliases.grep = "grep --color=auto";

  # less
  environment.variables.LESS = ''
    --RAW-CONTROL-CHARS \
    --ignore-case \
    --no-init \
    --quit-if-one-screen\
  '';

  # block ads
  networking.extraHosts = builtins.readFile (builtins.fetchurl "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts");

  # fzf
  programs.zsh.shellAliases.fzf = ''
    fzf \
      --color bg:15,fg:8,bg+:4,fg+:0,hl:3,hl+:3,info:15,pointer:12,prompt:8 \
      --no-bold\
  '';

  environment.variables.LS_COLORS = "di=0;35:fi=0;37:ex=0;96:ln=0;37";

  i18n.consoleUseXkbConfig = true;

  services.dnsmasq.enable = true;

  # map *.test to localhost
  services.dnsmasq.extraConfig = "address=/test/127.0.0.1";

  # Cloudflare
  services.dnsmasq.servers = [ "1.1.1.1" ];

  # Tor
  services.tor.enable = true;
  services.tor.client.enable = true;
  services.tor.client.dns.enable = true;
  services.tor.torsocks.enable = true;

  networking.wireless = {
    enable = true;
    networks =
      let _ = builtins.getEnv "WIFI_NETWORKS";
      in lib.mapAttrs'
        (k: v: lib.nameValuePair k (lib.listToAttrs [ (lib.nameValuePair "psk" v) ]))
        (builtins.fromJSON _);
  };

  programs.adb.enable = true;

  fonts.fontconfig.ultimate.enable = true;
  fonts.fontconfig.ultimate.preset = "windowsxp";
  fonts.fontconfig.defaultFonts = {
    monospace = [ "Source Code Pro" ];
    sansSerif = [ "Source Sans Pro" ];
  };
  fonts.enableCoreFonts = true;
  fonts.fonts = with pkgs; [
    google-fonts
    victor-mono
    nerdfonts
    ia-writer-duospace
  ];

  # hardware video acceleration
  hardware.opengl.extraPackages = [ pkgs.vaapiVdpau ];
  environment.variables.LIBVA_DRIVER_NAME = "vdpau";

  systemd.user.services.insync = {
    after = [ "network.target" ];
    wantedBy = [ "default.target" ];
    path = [ pkgs.insync ];
    script = "insync start";
    serviceConfig.Type = "forking";
    serviceConfig.Restart = "always";
  };

  # ripgrep
  programs.zsh.shellAliases.rg = "rg --smart-case --colors=match:fg:yellow";

  environment.etc."mailcap".text = "*/*; xdg-open '%s'";

  environment.variables.BROWSER = "browser";
  environment.variables.EDITOR = "vim";
  environment.variables.PAGER = "less";

  home-manager.users.avo = { pkgs, ... }: {
    gtk.enable = true;
    gtk.theme.name = "dark";
    # gtk.theme.package = pkgs.gnome-breeze;

    gtk.font.name = "Product Sans 8";

    home.packages = let
      pushover = pkgs.writeScriptBin "pushover" ''
        #!${pkgs.python}/bin/python

        import getopt
        import sys
        import os
        import StringIO
        import httplib
        import urllib


        class Pushover:
            priorities = {"high": 1, "normal": 0, 'low': -1}

            message = ""
            priority = priorities["normal"]
            title = ""
            token = os.environ['PUSHOVER_TOKEN']
            url = None
            user = os.environ['PUSHOVER_USER']

            def exit(self, code):
                sys.exit(code)

            def usage(self):
                file = os.path.basename(__file__)
                print "Usage:   " + file + " [options] <message> <title>"
                print "Stdin:   " + file + " [options] - <title>"
                print "Example: " + file + " \"Hello World\""
                print ""
                print "  -p --priority <high, normal, low>   Default: normal"
                print "  -l --url      <url>                 Link the message to this URL"

            def main(self):
                try:
                    opts, args = getopt.getopt(sys.argv[1:], "hu:t:p:u:c:l:",
                                              ["help",
                                                "user=",
                                                "token=",
                                                "priority=",
                                                "url="])
                except getopt.GetoptError as err:
                    print str(err)
                    self.usage()
                    self.exit(2)

                if len(args) > 0:
                    self.message = args.pop(0)

                    if len(args) > 0:
                        self.title = args.pop(0)

                    for o, a in opts:
                        if o in ("-h", "--help"):
                            self.usage()
                            self.exit(0)
                        elif o in ("-u", "--user"):
                            self.user = a
                        elif o in ("-t", "--token"):
                            self.token = a
                        elif o in ("-p", "--priority"):
                            for name, priority in self.priorities.iteritems():
                                if name == a:
                                    self.priority = priority
                        elif o in ("-l", "--url"):
                            self.url = a

                    if self.message == "-":
                        while True:
                            try:
                                line = sys.stdin.readline().strip()
                                if len(line) > 0:
                                    self.message = line
                                    self.send()
                            except KeyboardInterrupt:
                                break
                            if not line:
                                break

                    else:
                        self.send()

                else:
                    self.usage()
                    self.exit(2)

            def send(self):
                conn = httplib.HTTPSConnection("api.pushover.net:443")
                conn.request("POST", "/1/messages.json",
                            urllib.urlencode({
                                "token": self.token,
                                "user": self.user,
                                "url": self.url,
                                "title": self.title,
                                "message": self.message,
                                "priority": self.priority,
                            }), {"Content-type": "application/x-www-form-urlencoded"})

        if __name__ == "__main__":
            pushover = Pushover()
            pushover.main()
      '';

      colorpicker = pkgs.writeShellScriptBin "colorpicker" ''
         grim -g "$(slurp -p)" -t ppm - | convert - -format '%[pixel:p{0,0}]' txt:-
      '';

      moreutilsWithoutParallel = pkgs.stdenv.lib.overrideDerivation pkgs.moreutils (attrs: {
        postInstall =
          attrs.postInstall +
          "\n" +
          "rm $out/bin/parallel $out/share/man/man1/parallel.1";
      });

      zprint = pkgs.stdenv.mkDerivation rec {
        name = "zprint";
        src = pkgs.fetchurl {
          url = "https://github.com/kkinnear/zprint/releases/download/0.4.10/zprintl-0.4.10";
          sha256 = "0iab2gvynb0njhr2vy26li165sc2v6p5pld7ifp6jlf7yj3yr4gl";
        };
        unpackPhase = ":";
        dontStrip = true;
        preFixup =
          let rpath = with pkgs; lib.makeLibraryPath [ zlib ];
          in ''
            patchelf \
              --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
              --set-rpath "${rpath}" \
              $out/bin/zprint
          '';
        installPhase = "mkdir -p $out/bin && cp $src $out/bin/zprint && chmod +x $out/bin/zprint";
      };

      myNeovim = with pkgs; neovim.override {
        vimAlias = true;
        configure.vam = {
          knownPlugins = vimPlugins // {
            parinfer-rust = vimUtils.buildVimPlugin {
              name = "parinfer";
              src = fetchFromGitHub {
                owner = "eraserhd"; repo = "parinfer-rust";
                rev = "642fec5698f21758029988890c6683763beee5fd"; sha256 = "09gr3klm057l0ix9l4qxg65s2pw669k9l4prrr9gp7z30q1y5bi8";
              };
              buildPhase = "HOME=$TMP ${cargo}/bin/cargo build --release";
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

          pluginDictionaries = [
            { name = "parinfer-rust"; }
            { name = "spell-fr"; }
            { name = "spell-ro"; }
            { name = "commentary"; }
            { name = "fzf-vim"; }
            { name = "gitgutter";  }
            { name = "goyo"; }
            { name = "nerdtree"; }
            { name = "supertab"; }
            { name = "surround"; }
            { name = "vim-autoclose"; }
            { name = "vim-better-whitespace"; }
            { name = "vim-bracketed-paste"; }
            { name = "vim-eunuch"; }
            { name = "vim-indent-guides"; }
            { name = "vim-indent-object"; }
            { name = "vim-nix"; }
          ];
        };
        configure.customRC =
          let colorscheme = with theme; ''
          ''; in with theme; ''
          set noswapfile
          set hidden

          " clipboard
          set clipboard=unnamedplus

          set wildmode=longest:full,full
          set grepprg=rg\ --smart-case\ --vimgrep
          set autoindent smartindent breakindent

          set nowrap
          set linebreak " don't cut words on wrap
          " show wrapped lines
          set showbreak=↳
          hi NonText ctermfg=red guifg=red cterm=bold gui=bold

          set ignorecase smartcase infercase
          set
            \ shiftwidth=2 shiftround
            \ expandtab
            \ tabstop=2

          set mouse=a

          " statusline
          set statusline=\ %t

          " rebalance-splits-on-resize
          autocmd VimResized * wincmd =

          " file explorer
          map <silent> <leader>t :NERDTreeToggle %<CR>:wincmd=<CR>

          set gdefault inccommand=nosplit

          " clear search highlight
          nnoremap <silent><esc> :nohlsearch<return><esc>
          nnoremap <esc>^[ <esc>^["

          " disable git gutter by default
          let g:gitgutter_enabled = 0

          " better whitespace
          let b:better_whitespace_enabled = 1
          let g:strip_whitelines_at_eof = 1

          " lisp case movement
          set iskeyword+=-

          " fzf
          let $FZF_DEFAULT_COMMAND = 'rg --files --follow -g "!{.git}/*" 2>/dev/null'
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
            \ 'header':  ['fg', 'Normal'] }
          autocmd! FileType fzf
          autocmd FileType fzf set laststatus=0 noshowmode noruler foldcolumn=0
            \| autocmd BufLeave <buffer> set laststatus=1 noshowmode noruler foldcolumn=1

          " NERD Tree
          let NERDTreeMapActivateNode='<tab>'
          let g:NERDTreeDirArrowExpandable = '+'| let g:NERDTreeDirArrowCollapsible = '-'
          let g:NERDTreeMinimalUI = 1
          let NERDTreeAutoDeleteBuffer=1

          " Goyo
          let g:goyo_width = 66
          let g:goyo_height = "100%"

          " Supertab
          let g:SuperTabDefaultCompletionType = "context"

          " change cursor appearance with mode
          set guicursor=n-v-c:block-Cursor/lCursor,i-ci-ve:ver25-Cursor2/lCursor2,r-cr:hor20,o:hor50

          " search
          set showmatch

          set fillchars=stl:\ ,stlnc:\ ,vert:│
          set noruler
          set
            \ laststatus=1
            \ noshowmode

          " hide messages after 2s
          set updatetime=2000
          autocmd CursorHold * :echo

          set foldcolumn=1

          let mapleader = "\<Space>"
          let maplocalleader = ","
          " windows
          nmap <silent> <C-h> :wincmd h<CR>
          nmap <silent> <C-j> :wincmd j<CR>
          nmap <silent> <C-k> :wincmd k<CR>
          nmap <silent> <C-l> :wincmd l<CR>
          " buffers
          nnoremap <leader>bn :bnext<CR>
          nnoremap <leader>bp :bprevious<CR>
          nnoremap <leader>bd :bdelete<CR>
          nnoremap <leader>bf <C-^>
          " arglist
          nnoremap <leader>an :next<cr>
          nnoremap <leader>ap :prev<cr>
          " quickfix
          nnoremap <leader>cn :cnext<cr>
          nnoremap <leader>cp :cprev<cr>
          " select last inserted text
          nnoremap gV '[V']
          " toggle line numbers
          map <silent> <leader>n :set number!<CR>
          " fuzzy find
          nnoremap <silent> <leader>b :Buffers<CR>
          nnoremap <silent> <leader>f :Files<CR>

          set termguicolors

          for i in [ 'Keyword', 'Boolean', 'Character', 'Comment', 'Conceal', 'Conditional', 'Constant', 'Cursor', 'Cursor2', 'CursorLine', 'Debug', 'Define', 'Delimiter', 'Directory', 'Error', 'ErrorMsg', 'Exception', 'Float', 'FoldColumn', 'Function', 'Identifier', 'Ignore', 'Include', 'IncSearch', 'Keyword', 'Label', 'Macro', 'MatchParen', 'Normal', 'Number', 'Operator', 'PreCondit', 'PreProc', 'Repeat', 'Search', 'SignColumn', 'Special', 'SpecialChar', 'SpecialComment', 'SpellBad', 'Statement', 'StorageClass', 'String', 'Structure', 'Tag', 'Title', 'Todo', 'Type', 'Typedef', 'Underlined', 'VertSplit', 'WarningMsg' ]
            exe 'hi ' . i . ' NONE'
          endfor

          hi StatusLine gui=NONE guibg=#222222 guifg=#ffffff
          hi StatusLineNC gui=NONE guibg=${black_fg} guifg=${foreground}

          hi Comment gui=italic guifg=${black_fg}
          hi Delimiter gui=bold
          hi EndOfBuffer guifg=${background}
          hi Folded guibg=${white_bg} guifg=${white_fg}
          hi IncSearch gui=bold guibg=${yellow_fg} guifg=${black_fg}
          hi Keyword gui=italic
          hi LineNr guibg=${white_bg} guifg=${black_bg}
          hi MatchParen gui=bold guifg=${red_fg}
          hi NonText guifg=${foreground}
          hi EndOfBuffer guifg=${background}
          hi Normal guifg=${foreground} guibg=${background}
          hi Search gui=bold,underline guifg=${yellow_fg}
          hi SpellBad NONE cterm=undercurl gui=undercurl guifg=${red_fg}
          hi VertSplit guifg=${white_bg}
          hi Visual guibg=${white_bg}

          hi Cursor guibg=${red_fg}
          hi Cursor2 guibg=${blue_fg}

          " indent guides
          let g:indent_guides_auto_colors = 0
          autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd ctermbg=NONE guibg=NONE
          autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=15 guibg=${white_bg}

          " NERD Tree
          hi NERDTreeCWD ctermfg=8 guifg=${black_bg}
          hi NERDTreeClosable ctermfg=8 guifg=${black_bg} | hi NERDTreeOpenable ctermfg=8 guifg=${black_bg}
        '';
      };
    in with pkgs; [
      acpi
      alacritty
      aria
      chromedriver
      chromium
      clojure
      curl
      dnsutils
      dtach
      dtrx
      evince
      fd
      ffmpeg
      file
      fzf
      git
      git-hub
      gnumake
      gnupg
      google-chrome
      graphicsmagick
      httpie
      iftop
      insync
      iotop
      jq
      lastpass-cli
      libinput-gestures
      libnotify
      libreoffice-fresh
      lsof
      mediainfo
      moreutilsWithoutParallel
      mosh
      mpv
      msmtp
      myNeovim
      netcat
      nethogs
      nmap
      openssl
      pandoc
      parallel
      patchelf
      pavucontrol
      psmisc
      pulseaudio-ctl
      pup
      pushover
      recode
      ripgrep
      rlwrap
      socat
      spotify
      strace
      telnet
      tree
      urlview
      usbutils
      wget
      xfce.thunar
      xurls
      xxd
      youtube-dl
      youtube-viewer
    ];

    xdg.configFile."sway/config".text = ''
      workspace_layout tabbed

      set $lock swaylock -f -c 000000

      exec_always swayidle -w \
          timeout 250 '$lock' \
          timeout 1000 'swaymsg "output * dpms off"' \
              resume 'swaymsg "output * dpms on"' \
          timeout 2000 'systemctl suspend' \
          before-sleep '$lock'

      output * background #000000 solid_color

      set $cyan #00877c
      set $darkgray #484848
      set $black #000000
      set $white #ffffff
      set $gray #333333
      set $green #00ff00
      set $orange #873200
      set $blue #1a0099
      set $gray-bg #595959
      set $gray-fg #bfbfbf
      set $lightgray #777777
      set $inactive-bg $gray-bg
      set $active-fg $darkgray
      set $active-bg $darkgray


      for_window [class=".*mpv$"] inhibit_idle visible


      set $mod Mod4

      set $left h
      set $down j
      set $up k
      set $right l

      hide_edge_borders both

      set $term alacritty

      set $menu dmenu_path | dmenu -fn 'Source Sans Pro-25' | xargs swaymsg exec --

      bindsym $mod+Return exec $term
      bindsym $mod+Shift+c kill

      bindsym $mod+p exec $menu

      bindsym $mod+q reload

      bindsym $mod+Tab focus right
      bindsym $mod+Shift+Tab focus left

      bindsym $mod+$left focus left
      bindsym $mod+$down focus down
      bindsym $mod+$up focus up
      bindsym $mod+$right focus right

      bindsym $mod+t layout tabbed
      bindsym $mod+s layout toggle split

      bindsym $mod+Shift+$left move left
      bindsym $mod+Shift+$down move down
      bindsym $mod+Shift+$up move up
      bindsym $mod+Shift+$right move right

      bindsym $mod+Shift+Left move left
      bindsym $mod+Shift+Down move down
      bindsym $mod+Shift+Up move up
      bindsym $mod+Shift+Right move right

      bindsym $mod+Alt+$left resize shrink width 160px
      bindsym $mod+Alt+$down resize grow height 160px
      bindsym $mod+Alt+$up resize shrink height 160px
      bindsym $mod+Alt+$right resize grow width 160px

      bindsym $mod+b splith
      bindsym $mod+v splitv

      bindsym $mod+f fullscreen

      bindsym $mod+a focus parent

      floating_modifier $mod normal

      bar mode invisible

      include @sysconfdir@/sway/config.d/*

      titlebar_padding 16 5

      input * xkb_layout "fr"
      input * xkb_options ctrl:nocaps

      bindsym F1 exec pulseaudio-ctl mute
      bindsym F2 exec pulseaudio-ctl down 1
      bindsym F3 exec pulseaudio-ctl up 1
      bindsym F4 exec pactl set-source-mute @DEFAULT_SOURCE@ toggle
      bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
      bindsym XF86MonBrightnessUp exec brightnessctl set +5%

      client.unfocused $black $black $lightgray $black $black
      client.focused $darkgray $darkgray $white $darkgray $darkgray
      client.focused_inactive $black $black $gray $black $black

      default_border normal 1

      input "1133:45081:MX_Master_2S_Mouse" {
        accel_profile flat
        pointer_accel 1
      }

      input "2:7:SynPS/2_Synaptics_TouchPad" {
        dwt enabled
        tap enabled
        natural_scroll enabled
        middle_emulation enabled
      }

      font pango:Product Sans Bold 18

      bindsym F5 mode "default"

      bindsym $mod+ampersand workspace 1
      bindsym $mod+eacute workspace 2
      bindsym $mod+quotedbl workspace 3
      bindsym $mod+apostrophe workspace 4
      bindsym $mod+parenleft workspace 5
      bindsym $mod+egrave workspace 6
      bindsym $mod+minus workspace 7
      bindsym $mod+underscore workspace 8
      bindsym $mod+ccedilla workspace 9
      bindsym $mod+agrave workspace 10

      bindsym $mod+Shift+ampersand move container to workspace 1
      bindsym $mod+Shift+eacute move container to workspace 2
      bindsym $mod+Shift+quotedbl move container to workspace 3
      bindsym $mod+Shift+apostrophe move container to workspace 4
      bindsym $mod+Shift+parenleft move container to workspace 5
      bindsym $mod+Shift+egrave move container to workspace 6
      bindsym $mod+Shift+minus move container to workspace 7
      bindsym $mod+Shift+underscore move container to workspace 8
      bindsym $mod+Shift+ccedilla move container to workspace 9
      bindsym $mod+Shift+agrave move container to workspace 10

      bindsym twosuperior scratchpad show
      bindsym $mod+x move container to scratchpad

      # Toggle the current focus between tiling and floating mode
      bindsym $mod+Shift+space floating toggle

      # Swap focus between the tiling area and the floating area
      bindsym $mod+space focus mode_toggle

      smart_borders on
    '';

    programs.direnv.enable = true;
    programs.direnv.enableZshIntegration = true;

    programs.zsh = let
      conf = {
        disable-beep = ''
          unsetopt beep
        '';

        globbing = ''
          setopt \
            case_glob \
            extended_glob \
            glob_complete
        '';
      };

      plugins = {
        zsh-autopair = let _ = pkgs.fetchFromGitHub {
          owner = "hlissner"; repo = "zsh-autopair";
          rev = "8c1b2b85ba40b9afecc87990c884fe5cf9ac56d1"; sha256 = "0aa87r82w431445n4n6brfyzh3bnrcf5s3lhih1493yc5mzjnjh3";
        }; in "source ${_}/autopair.zsh";

        fast-syntax-highlighting = let _ = pkgs.fetchFromGitHub {
          owner = "zdharma"; repo = "fast-syntax-highlighting";
          rev = "5ed7c0fa0be5e456a131a2378af10b5c03131a7e"; sha256 = "0g3vzaixwjl9rjxc8waq1458kqjg8hsgsaz3ln6a1jm8cd7qca50";
        }; in "source ${_}/fast-syntax-highlighting.plugin.zsh";
      };
    in {
      enable = true;

      enableCompletion = true;

      shellAliases = {
        l = "ls -1";
        la = "ls -a";
        ls = ''
          LC_COLLATE=C \
            ls \
              --dereference \
              --human-readable \
              --indicator-style=slash \
        '';
        ll = "ls -l";
        vi = "vim";
      };


      initExtra =
        (lib.concatStringsSep "\n" [
          (lib.concatStringsSep "\n" [
            (lib.concatStringsSep "\n" (lib.attrValues conf))
            (lib.concatStringsSep "\n" (lib.attrValues plugins))
          ]) 

          ''
            bindkey -v

            export KEYTIMEOUT=1

            autoload -U edit-command-line; zle -N edit-command-line
            autoload -U select-bracketed; zle -N select-bracketed
            autoload -U select-quoted; zle -N select-quoted
            autoload -U surround; zle -N delete-surround surround; zle -N change-surround surround; zle -N add-surround surround

            bindkey -M vicmd '^x^e' edit-command-line; bindkey -M viins '^x^e' edit-command-line
            bindkey -M vicmd 'H' run-help

            bindkey ''${terminfo[kcbt]:-^\[\[Z} reverse-menu-complete

            bindkey '^n' expand-or-complete
            bindkey '^p' reverse-menu-complete

            for m in visual viopp; do
              for c in {a,i}''${(s..)^:-'()[]{}<>bB'}; do
                bindkey -M $m $c select-bracketed
              done
            done
            for m in visual viopp; do
              for c in {a,i}{\',\",\`}; do
                bindkey -M $m $c select-quoted
              done
            done

            bindkey -a cs change-surround
            bindkey -a ds delete-surround
            bindkey -a ys add-surround
            bindkey -M visual S add-surround

            function zle-keymap-select zle-line-init zle-line-finish {
              case $KEYMAP in
                vicmd) print -n '\033[1 q' ;;
                viins|main) print -n '\033[6 q' ;;
              esac
            }
            zle -N zle-line-init; zle -N zle-line-finish; zle -N zle-keymap-select

            zstyle ':completion:*' menu select
            zstyle ':completion:*' rehash true

            source ${pkgs.fzf}/share/fzf/completion.zsh

            HISTSIZE=99999 SAVEHIST=$HISTSIZE
            HISTFILE=~/.cache/zsh_history

            setopt \
              extended_history \
              hist_ignore_all_dups \
              hist_ignore_space \
              hist_reduce_blanks \
              share_history

            source ${pkgs.fzf}/share/fzf/key-bindings.zsh

            prompt_precmd() {
              rehash
              setopt promptsubst

              local jobs; unset jobs
              local prompt_jobs
              for a (''${(k)jobstates}) {
                j=$jobstates[$a];i=\'''''${''${(@s,:,)j}[2]}'
                jobs+=($a''${i//[^+-]/})
              }
              prompt_jobs=""
              [[ -n $jobs ]] && prompt_jobs="["''${(j:,:)jobs}"] "

              PROMPT="%(?.%F{green}.%F{red})%~ $ %f%K{black}%F{white}$prompt_jobs%f%k"
            }
            prompt_opts=(cr percent sp subst)
            autoload -U add-zsh-hook
            add-zsh-hook precmd prompt_precmd
          ''
        ]);
      };

    home.file.".inputrc".text = ''
      set editing-mode vi

      set completion-ignore-case on
      set show-all-if-ambiguous on

      set keymap vi
      C-r: reverse-search-history
      C-f: forward-search-history
      C-l: clear-screen
      v: rlwrap-call-editor
    '';

    home.file.".gitconfig".text = ''
      [user]
        name = Andrei Volt
        email = andrei@avolt.net
    '';
  };

  environment.variables.PUSHOVER_USER = builtins.getEnv "PUSHOVER_USER";
  environment.variables.PUSHOVER_TOKEN = builtins.getEnv "PUSHOVER_TOKEN";

  # Git
  environment.variables.EMAIL = builtins.getEnv "EMAIL";
  environment.variables.GIT_AUTHOR_NAME = builtins.getEnv "FULL_NAME";
  environment.etc."gitconfig".text = lib.generators.toINI {} {
    alias = {
      am = "commit --all --amend --no-edit";
      ap = "add --patch";
      ci = "commit";
      co = "checkout";
      dc = "diff --cached";
      di = "diff";
      st = "status --short";
    };
    # core.pager = "${pkgs.gitAndTools.diff-so-fancy}/bin/diff-so-fancy | less -X";
    push.default = "current";

    hub.oauthtoken = builtins.getEnv "GITHUB_TOKEN";
  };

  system.autoUpgrade.enable = true;
  system.autoUpgrade.channel = https://nixos.org/channels/nixos-unstable;
  system.stateVersion = "19.09";
}
