{ config, pkgs, ... }:

let
  hostName = "${builtins.getEnv "HOST"}";

  theme = import ./challenger-deep-theme.nix;
  proportionalFont = "Abel"; monospaceFont = "Source Code Pro";

  myName = "Andrei Vladescu-Olt"; myEmail = "andrei@avolt.net";

  overlays =
    let path = ./overlays; in with builtins;
    map (n: import (path + ("/" + n)))
        (filter (n: match ".*\\.nix" n != null ||
                    pathExists (path + ("/" + n + "/default.nix")))
                (attrNames (readDir path)));

in {
  imports =
    [
      ./hardware-configuration.nix
      ./packages.nix

      ./docker-nginx-proxy.nix

      "${builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz}/nixos"
    ];

  boot.loader.timeout = 1;

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 100000;
    "vm.swappiness" = 1;
    "vm.vfs_cache_pressure" = 50;
    "kernel.core_pattern" = "|/run/current-system/sw/bin/false"; # disable core dumps
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  time.timeZone = "Europe/Paris";

  i18n = {
    consoleUseXkbConfig = true;
    defaultLocale = "en_US.UTF-8";
  };

  system = {
    autoUpgrade = {
      enable = true;
      channel = "https://nixos.org/channels/nixos-unstable";
    };
  };

  nix = {
    buildCores = 0;
    gc.automatic = true;
    optimise.automatic = true;
  };

  nixpkgs = {
    overlays = overlays;
    config.allowUnfree = true;
  };

  hardware = {
    bluetooth.enable = true;

    opengl = {
      driSupport = true;
      driSupport32Bit = true;
    };

    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
   };
  };

  networking = {
    enableIPv6 = false;
    firewall.allowedTCPPorts = [ 80 443 ];
    hostName = hostName;
  };

  hardware.opengl.extraPackages = with pkgs; [ vaapiVdpau ];

  services = {
    ipfs.enable = true;

    devmon.enable = true;

    mopidy = {
      enable = true;
      extensionPackages = with pkgs; [ mopidy-gmusic ];
      configuration = ''
        [gmusic]
        deviceid = 0123456789abcdef
        username = andreivolt
        password = ${builtins.getEnv "ANDREIVOLT_GOOGLE_PASSWORD"}
        bitrate = 320
      '';
    };

    bitlbee = {
      enable = true;
      libpurple_plugins = with pkgs; [ telegram-purple ];
    };

    zerotierone.enable = true;

    emacs.enable = true;

    offlineimap.enable = true;

    tor.client.enable = true;

    avahi = {
      enable = true;
      nssmdns = true;
      publish.enable = true;
    };

    openvpn.servers = {
      us = {
        config = '' config /home/avo/.config/openvpn/conf '';
        autoStart = false;
      };
    };

    xserver = {
      enable = true;

      # displayManager.sddm.enable = true;
      # windowManager.sway.enable = true;

      #dpi = 276;

      videoDrivers = [ "nvidia" ];

      xkbOptions = "ctrl:nocaps";

      layout = "fr";

      libinput = {
        enable = true;
        naturalScrolling = true;
        accelSpeed = "0.4";
      };

      xrandrHeads = [
        {
          output = "DP-2";
          monitorConfig = ''
            Option "metamodes" "nvidia-auto-select +2160+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On, Rotate=left}"
            Option "AllowIndirectGLXProtocol" "off"
            Option "TripleBuffer" "on"
          '';
        }
        {
          output = "DP-4";
          primary = true;
          monitorConfig = ''
            Option "metamodes" "nvidia-auto-select +3840+2160 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
            Option "AllowIndirectGLXProtocol" "off"
            Option "TripleBuffer" "on"
          '';
        }
        {
          output = "DP-0";
          monitorConfig = ''
            Option "metamodes" "nvidia-auto-select +3840+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
            Option "AllowIndirectGLXProtocol" "off"
            Option "TripleBuffer" "on"
          '';
        }
      ];

      windowManager = {
        default = "xmonad";
        xmonad  = {
          enable = true;
          enableContribAndExtras = true;
        };
      };

      desktopManager.xterm.enable = false;

      displayManager = {
        auto = {
          enable = true;
          user = "avo";
        };
      };
    };

    compton = {
      enable = true;
      shadow = true;
      shadowOffsets = [ (-15) (-5) ];
      shadowOpacity = "0.8";
      shadowExclude = [
        ''
          !(XMONAD_FLOATING_WINDOW ||
            (_NET_WM_WINDOW_TYPE@[0]:a = "_NET_WM_WINDOW_TYPE_DIALOG") ||
            (_NET_WM_STATE@[0]:a = "_NET_WM_STATE_MODAL"))
        ''
      ];
      extraOptions = ''
        blur-background = true;
        blur-background-frame = true;
        blur-background-fixed = true;
        blur-background-exclude = [
          "class_g = 'slop'";
        ];
        blur-kern = "11,11,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1";
        clear-shadow = true;
      '';
    };

    printing = {
      enable = true;
      clientConf = ''
        <Printer default>
          UUID urn:uuid:3c151d9e-3d44-3a04-59f9-5cdfbb513438
          Info DCPL2520DW
          MakeModel everywhere
          DeviceURI ipp://192.168.1.15/ipp/print
        </Printer>
      '';
    };

    dnsmasq = {
      enable = true;
      servers = ["8.8.8.8" "8.8.4.4"];

      extraConfig = ''
        address=/test/127.0.0.1
      '';
    };

    openssh.enable = true;
  };

  users.users.avo = {
    uid = 1000;
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "adbusers"
      "docker"
      "ipfs"
      "libvirtd"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2lzQAHzKnmiCQ9Ocb2PTMAQH9HR2x7KO7SV+og2a1nRH+T9bfQjgMW7SuPFbPN7Y4SoAgeBo+FFy7EczxyB7BW+z0u8uHlTJkQ4M1jmj5CQxdkuY/JLkbfJGhSw4eB4iJL7hhxwPvME9DgvdfN4ncxQZWiwrS0diLmydtUXcrEq1uqcaaTijJRADQpTxGUoEi9gNQDCHOWpPfKWAr6APS34MfWAfrc97n862xSPmwHFuCKuHG7WBzBhCSEPCFAI/mo+Wf9L6KWgz0jRRdwCPkMAxoYHmfZZqqRyoILr9CGKSFaN57kJevTMHDzoQgEskMS5Ln3qyFPvggpWWfGODL avo@watts"
    ];
  };

  home-manager.users.avo = rec {
    services = {
      gpg-agent = {
        enable = true;
        defaultCacheTtl = 1800;
        enableSshSupport = true;
      };

      dunst = {
        enable = true;
        settings = import ./dunstrc.nix { inherit theme; font = proportionalFont; };
      };

      unclutter.enable = true;
    };

    xresources.properties = {
      "Xft.dpi"       = 192;
      "Xft.hintstyle" = "hintfull";
      "Xcursor.theme" = "Adwaita";
      "Xcursor.size"  = 42;
      # "*.font" = "xft:${monospaceFont}:size=11";

      "*.foreground"  = theme.foreground;
      "*.background"  = theme.background;
      "*.borderColor" = theme.background;
      "*.cursorColor" = theme.foreground;
      "*.colorUL"     = theme.white;
      "*.color0"      = theme.black;
      "*.color8"      = theme.gray;
      "*.color1"      = theme.red;
      "*.color9"      = theme.lightRed;
      "*.color2"      = theme.green;
      "*.color10"     = theme.lightGreen;
      "*.color3"      = theme.yellow;
      "*.color11"     = theme.lightYellow;
      "*.color4"      = theme.blue;
      "*.color12"     = theme.lightBlue;
      "*.color5"      = theme.magenta;
      "*.color13"     = theme.lightMagenta;
      "*.color6"      = theme.cyan;
      "*.color14"     = theme.lightCyan;

      "rofi.font"     = "${proportionalFont} 24";
      "rofi.theme"    = "Pop-Dark";
    };

    home = {
      packages = with pkgs; [];
      sessionVariables = {
        ALTERNATE_EDITOR            = "${pkgs.neovim}/bin/nvim";
        BLOCK_SIZE                  = "\'1";
        BOOT_JVM_OPTIONS            = "'-client -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -Xverify:none'";
        BROWSER                     = "qutebrowser";
        COLUMNS                     = 100;
        EDITOR                      = "${pkgs.emacs}/bin/emacsclient";
        GPG_AGENT_INFO              = "$HOME/.gnupg/S.gpg-agent";
        PAGER                       = "less";
        PATH                        = "~/bin:~/.local/bin:~/.npm-packages/bin:$PATH";
        QT_AUTO_SCREEN_SCALE_FACTOR = 1;
        SSH_AUTH_SOCK               = "$XDG_RUNTIME_DIR/ssh-agent.socket";
      };

      file = {
        ".cups/lpoptions".text = ''
           Default default
        '';

        ".curlc".text = ''
          user-agent mozilla
          silent
          globoff
        '';

        ".httpie/config.json".text = ''
          {
            "default_options": [
              "--pretty",
              "format"
            ]
          }
        '';

        ".inputrc".text = ''
          set editing-mode vi

          set completion-ignore-case on
          set show-all-if-ambiguous  on

          set keymap vi
          C-r: reverse-search-history
          C-f: forward-search-history
          C-l: clear-screen
          v:   rlwrap-call-editor
        '';

        ".mailrc".text = ''
          set sendmail=${pkgs.msmtp}/bin/msmtp"
        '';

        ".npmrc".text = ''
          prefix=~/.npm-packages"
        '';

        ".ghci".text = ''
          :set prompt "λ "
        '';

        ".aws/config".text = ''
          [default]
          region = eu-west-1
        '';

        ".aws/credentials".text = ''
          [default]
          aws_access_key_id = ${builtins.getEnv "AWS_ACCESS_KEY_ID"}
          aws_secret_access_key = ${builtins.getEnv "AWS_SECRET_ACCESS_KEY"}
        '';

        ".tmux.conf".text = ''
          set -g @plugin 'tmux-plugins/tpm'

          set -g @plugin 'tmux-plugins/tmux-resurrect'
          set -g @resurrect-strategy-vim 'session'
          set -g @resurrect-capture-pane-contents 'on'

          set -g @plugin 'tmux-plugins/tmux-continuum'
          set -g @continuum-restore 'on'
          set -g @continuum-boot 'on'

          set -g @plugin 'tmux-plugins/tmux-sensible'

          set -g @plugin 'tmux-plugins/tmux-pain-control'

          set -g @plugin 'nhdaly/tmux-better-mouse-mode'
          set -g @scroll-speed-num-lines-per-scroll 1

          set -g @plugin 'tmux-plugins/tmux-copycat'
          set -g @plugin 'tmux-plugins/tmux-yank'
          set -g @yank_selection 'primary'

          run '~/.tmux/plugins/tpm/tpm'


          set -g base-index 1
          set -g renumber-windows on

          set -g monitor-activity on

          set -g set-titles on
          set -g set-titles-string "#T"

          set -g status-style bg=colour238,fg=colour252
          set -g status-left ' #S '
          set -g status-left-length 100
          set -g status-right '#h'
          set -g window-status-format ' #I: #W '
          set -g window-status-current-format ' #I: #W '
          setw -g window-status-current-style bg=black,fg=white
          setw -g window-status-activity-style bg=yellow

          set -g prefix C-a

          setw -g mode-keys vi
          set -g mode-keys vi

          bind C-o previous-window
          bind C-i next-window
          bind x choose-session
          bind s split-window -v
          bind v split-window -h

          bind -T copy-mode-vi v send -X begin-selection
          bind -T copy-mode-vi C-v send -X rectangle-toggle
          bind -T copy-mode-vi y send -X copy-selection
          unbind p
          bind p paste-buffer

          set -g mouse on
        '';

        ".stylish-yaskell.yaml".text = ''
          steps:
            - simple_align:
                cases: true
                top_level_patterns: true
                records: true
            - imports:
                align: global
                list_align: after_alias
                pad_module_names: true
                long_list_align: inline
                empty_list_align: inherit
                list_padding: 4
                separate_lists: true
                space_surround: false
            - language_pragmas:
                style: vertical
                align: true
                remove_redundant: true
            - trailing_whitespace: {}
          columns: 80
          newline: native
        '';

        ".notmuch-config".text = ''
          [user]
          name=${myName}
          primary_email=${myEmail}
          other_email=andrei.volt@gmail.com

          [new]
          tags=unread;inbox;
          ignore=

          [search]
          exclude_tags=deleted;spam;

          [maildir]
          synchronize_flags=true
        '';

        ".gist".text = builtins.getEnv "GIST_TOKEN";

        ".mailcap".text = ''
          application/doc; antiword %s; copiousoutput
          application/msword; antiword %s; copiousoutput
          application/pdf; view-attachment %s pdf
          application/vnd.ms-powerpoint; libreoffice %s
          application/vnd.ms-powerpoint; ppt2txt '%s'; copiousoutput; description=MS PowerPoint presentation;
          application/vnd.openxmlformats-officedocument.presentationml.presentation; libreoffice %s
          application/vnd.openxmlformats-officedocument.presentationml.presentation; pptx2txt '%s'; copiousoutput; description=MS PowerPoint presentation;
          application/vnd.openxmlformats-officedocument.presentationml.slideshow; libreoffice %s
          application/vnd.openxmlformats-officedocument.presentationml.slideshow; view-attachment %s
          application/vnd.openxmlformats-officedocument.spreadsheetmleet; view-attachment %s xls
          application/vnd.openxmlformats-officedocument.wordprocessingml.document; plaintextify < %s; copiousoutput
          image/gif; view-attachment %s gif
          image/jpeg; view-attachment %s jpg
          image/jpg; view-attachment %s jpg
          image/png; view-attachment %s png
          image/svg+xml; view-attachment %s svg
          image/x-png; view-attachment %s png
          text/html; firefox-devedition %s;
          text/html; w3m -o display_link=true -o display_link_number=true -dump -I %{charset} -cols 72 -T text/html %s; nametemplate=%s.html; copiousoutput
          text/plain; view-attachment %s txt
        '';
      };
    };

    xdg = {
      enable = true;

      configFile = {
        "mpv/mpv.conf".text = ''
          ao = pulse
          hwdec = vdpau
          profile = opengl-hq
          no-audio-display
        '';

        "offlineimap/config".text = ''
          [general]
          accounts = avolt.net
          fsync = false
          maxconnections = 10
          autorefresh = 0.5
          quick = 10

          [Account avolt.net]
          localrepository = avolt.net_local
          postsynchook = /run/current-system/sw/bin/notmuch new
          realdelete = yes
          remoterepository = avolt.net_remote

          [Repository avolt.net_local]
          localfolders = ~/mail/avolt.net
          type = Maildir
          nametrans = lambda folder: folder == 'INBOX' and 'INBOX' or ('INBOX.' + folder)

          [Repository avolt.net_remote]
          type = Gmail
          nametrans = lambda folder: {'[Gmail]/All Mail': 'archive',}.get(folder, folder)
          folderfilter = lambda folder: folder == '[Gmail]/All Mail'
          realdelete = yes
          remoteuser = andrei@avolt.net
          remotepass = ${builtins.getEnv "AVOLT_GOOGLE_PASSWORD"}
          sslcacertfile = /etc/ssl/certs/ca-certificates.crt
          synclabels = yes

          keepalive = 60
          holdconnectionopen = yes
        '';

        "alacritty/alacritty.yml".text = import ./alacritty.nix { inherit theme monospaceFont; };

        "xmobar/xmobarrc".text = import ./xmobarrc.nix { inherit theme; font = proportionalFont; };
        "xmobar/bin/online-indicator" = {
          text = ''
            color=$(is-online && echo '${theme.green}' || echo '${theme.red}')
            symbol=$(is-online && echo ﯱ || echo ﯱ)

            echo "<fc=$color>$symbol</fc>"
          '';
          executable = true;
        };

        "youtube-dl.conf".text = ''
           --output %(title)s.%(ext)s
        '';

        "nvim/init.vim".text = ''
          set runtimepath^=~/.vim runtimepath+=~/.vim/after
          let &packpath = &runtimepath
          source ~/.vim/vimrc
        '';

        "zathura/zathurarc".text = ''
          set incremental-search true
        '';

        "qutebrowser/autoconfig.yml".text = import ./qutebrowser.nix { inherit theme proportionalFont monospaceFont pkgs; };

        "user-dirs.dirs".text = ''
          XDG_DOWNLOAD_DIR="$HOME/tmp"
          XDG_DESKTOP_DIR="$HOME/tmp"
        '';

        "mimeapps.list".text = ''
           [Default Applications]
           x-scheme-handler/http=qutebrowser.desktop
           x-scheme-handler/https=qutebrowser.desktop
           x-scheme-handler/ftp=qutebrowser.desktop
           text/html=qutebrowser.desktop
           application/xhtml+xml=qutebrowser.deskop
           application/vnd.openxmlformats-officedocument.wordprocessingml.document=writer.desktop;libreoffice-writer.desktop;
           application/pdf=mupdf.desktop;zathura-pdf-mupdf.desktop;
           text/plain=emacs.desktop;
           application/vnd.openxmlformats-officedocument.spreadsheetml.sheet=calc.desktop;
           application/xml=emacs.desktop;
           x-scheme-handler/magnet=userapp-transmission-gtk-NWT3FZ.desktop;
        '';

        "brittany/config.yaml".text = ''
          conf_debug:
            dconf_roundtrip_exactprint_only: false
            dconf_dump_bridoc_simpl_par: false
            dconf_dump_ast_unknown: false
            dconf_dump_bridoc_simpl_floating: false
            dconf_dump_config: false
            dconf_dump_bridoc_raw: false
            dconf_dump_bridoc_final: false
            dconf_dump_bridoc_simpl_alt: false
            dconf_dump_bridoc_simpl_indent: false
            dconf_dump_annotations: false
            dconf_dump_bridoc_simpl_columns: false
            dconf_dump_ast_full: false
          conf_forward:
            options_ghc: []
          conf_errorHandling:
            econf_ExactPrintFallback: ExactPrintFallbackModeInline
            econf_Werror: false
            econf_omit_output_valid_check: false
            econf_produceOutputOnErrors: false
          conf_preprocessor:
            ppconf_CPPMode: CPPModeAbort
            ppconf_hackAroundIncludes: false
          conf_version: 1
          conf_layout:
            lconfig_a
        '';
      };
    };

    xsession = {
      enable = true;

      windowManager.command = "xmonad";

      initExtra = ''
        xsetroot -xcf ${pkgs.gnome3.adwaita-icon-theme}/share/icons/Adwaita/cursors/left_ptr 42

        wallpaper=~/data/wallpapers/matterhorn.jpg; setroot -z $wallpaper -z $wallpaper -z $wallpaper
      '';
    };

    programs = {
      home-manager.enable = true;

      htop = {
        enable = true;
        fields = [
          "USER"
          "PRIORITY"
          "STATE"
          "PERCENT_CPU"
          "PERCENT_MEM"
          "TIME"
          "IO_READ_RATE"
          "IO_WRITE_RATE"
          "STARTTIME"
          "COMM"
        ];
        accountGuestInCpuMeter = false;
        colorScheme = 6;
        hideUserlandThreads = true;
        meters = {
          left = [
            "Memory"
            "CPU"
            "LoadAverage"
          ];
          right = [
            "Tasks"
            "Uptime"
          ];
        };
      };

      git = {
        enable = true;

        userName  = myName;
        userEmail = myEmail;

        aliases = {
          "am" = "commit --amend -C HEAD";
          "ap" = "add -p";
          "ci" = "commit";
          "co" = "checkout";
          "dc" = "diff --cached";
          "di" = "diff";
          "root" = "!pwd";
          "st" = "status --short";
        };

        extraConfig = {
          core = {
            editor = "emacsclient -nw";
            pager = "diff-so-fancy | less --tabs=4 -RFX";
          };

          ghi.token = builtins.getEnv "GHI_TOKEN";
        };

        ignores = [
          "*~"
          "tags"
          ".#*"
          ".env*"
          ".nrepl*"
        ];
      };

      ssh = {
        enable = true;

        controlMaster  = "auto";
        controlPath    = "/tmp/ssh-%u-%r@%h:%p";
        controlPersist = "0";
      };

      zsh = rec {
        enable = true;

        enableCompletion = false;
        enableAutosuggestions = true;

        shellAliases = {
          "R"               = "ramda";
          "browser-history" = "qutebrowser-history";
          "e"               = "emacsclient -s scratchpad --no-wait";
          "fzf"             = "fzf --color bw";
          "gc"              = "git clone";
          "gdax"            = "webapp https://www.gdax.com/trade/BTC-USD";
          "git"             = "hub";
          "gr"              = "cd $(git root)";
          "grep"            = "grep --color=auto";
          "j"               = "jobs -d | paste - -";
          "l"               = "ls";
          "la"              = "ls -a";
          "ls"              = "ls --group-directories-first --classify --dereference-command-line -v";
          "mkdir"           = "mkdir -p";
          "rg"              = "rg --smart-case --colors match:bg:yellow --colors match:fg:black";
          "rm"              = "timeout 3 rm -Iv --one-file-system";
          "stack"           = "stack --nix";
          "tree"            = "tree -F --dirsfirst";
          "vi"              = "nvim";
          "vpnoff"          = "sudo systemctl stop openvpn-us";
          "vpnon"           = "sudo systemctl start openvpn-us";
        };

        history = rec {
          size = 99999;
          save = size;
          path = ".zsh_history";
          ignoreDups = true;
          share = true;
        };

        initExtra = ''
          setopt \
            extended_history \
            hist_ignore_space \
            hist_reduce_blanks

          setopt interactive_comments

          setopt \
            extended_glob \
            no_case_glob

          if [[ $TERM != eterm-color && $TERM != dumb ]]; then
            preexec() { print -Pn "\e]0;$1\a" }
          fi

          unset RPS1

          diff() { wdiff -n $@ | colordiff }
          open() { setsid xdg-open $* &>/dev/null }
          +x() { chmod +x "$*" }

          alias -g C='| wc -l'
          alias -g L='| less -R'
          alias -g H='| head'
          alias -g T='| tail'
          alias -g Y='| xsel -b'
          alias -g DN='2>/dev/null'
          alias -g FZ='| fzf | xargs'

          alias ..='cd ..'
          alias ...='cd .. && cd ..';
          alias ....='cd .. && cd .. && cd ..';

          #zplug 'andreivolt/zsh-auto-rlwrap'
          #bindkey -M viins '^x' insert-rlwrap
          #bindkey -M vicmd '^x' insert-rlwrap

          ################################################################################

          setopt glob_complete
          zstyle ':completion:*' menu select
          zstyle ':completion:*' rehash true

          ################################################################################

          source ~/.zplug/init.zsh
          zplug 'willghatch/zsh-hooks'; zplug load
          zplug 'andreivolt/zsh-prompt-lean'
          zplug 'andreivolt/zsh-vim-mode', defer:2; zplug load
          zplug 'zdharma/fast-syntax-highlighting'
          zplug 'hlissner/zsh-autopair', defer:2
          zplug 'chisui/zsh-nix-shell'
          zplug 'chrismwendt/auto-nix-shell'
          zplug load

          eval "$(direnv hook zsh)"

          source ~/.private
        '';
      };
    };
  };

  security.sudo.wheelNeedsPassword = false;

  virtualisation = {
    docker = {
      enable = true;
      extraOptions = "--experimental";
      autoPrune.enable = true;
    };

    libvirtd.enable = true;
  };

  environment.variables = {
    "IPFS_PATH" = "/var/lib/ipfs/.ipfs";
    "LIBVIRT_DEFAULT_URI" = "qemu:///system";
    "LIBVA_DRIVER_NAME" = "vdpau";
  };

  programs = {
    adb.enable = true;

    zsh = {
      enable = true;
      enableCompletion = true;
    };
  };

  fonts = {
    fontconfig = {
      ultimate.enable = false;
      defaultFonts = {
        monospace = [ monospaceFont ];
      };
    };
    enableCoreFonts = true;
    fonts = with pkgs; [
      emacs-all-the-icons-fonts
      font-awesome-ttf
      google-fonts
      hack-font
      hasklig
      (iosevka.override {
        set = "custom";
        weights = ["light"];
        design = [
          "termlig"
          "v-asterisk-low"
          "v-at-short"
          "v-i-zshaped"
          "v-tilde-low"
          "v-underscore-low"
          "v-zero-dotted"
          "v-zshaped-l"
        ];
      })
      material-icons
      nerdfonts
      overpass
      powerline-fonts
      terminus_font
      ubuntu_font_family
      vistafonts
    ];
  };

  powerManagement.resumeCommands = ''
    rm /tmp/ssh*
  '';

  systemd.user.services =
    let
      emacsDaemon = name : {
        enable = true;
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type      = "forking";
          Restart   = "always";
          ExecStart = ''${pkgs.bash}/bin/bash -c 'source ${config.system.build.setEnvironment}; exec ${pkgs.emacs}/bin/emacs --daemon=${name} --eval "(+avo/${name})"' '';
          ExecStop  = "${pkgs.emacs}/bin/emacsclient -s ${name} --eval (kill-emacs)";
        };
      };
    in {
      ircEmacsDaemon = emacsDaemon "irc";
      mailEmacsDaemon = emacsDaemon "mail";
      editorEmacsDaemon = emacsDaemon "scratchpad";

      dropbox = {
        enable = true;
        description = "Dropbox service";
        after = [ "network.target" ];
        wantedBy = [ "default.target" ];
        path = [ pkgs.dropbox ];
        serviceConfig = {
          Type      = "forking";
          Restart   = "always";
          ExecStart = "${pkgs.dropbox}/bin/dropbox start";
          ExecStop  = "${pkgs.dropbox}/bin/dropbox stop";
        };
      };
    };
}
