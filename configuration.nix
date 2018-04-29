{ config, lib, pkgs, ... }:

let
  makeEmacsDaemon = name: (import ./make-emacs-daemon.nix { inherit config pkgs; name = name; });

  theme = import ./challenger-deep-theme.nix;
  proportionalFont = "Abel"; monospaceFont = "Source Code Pro";
  fontSize = 10; launcherFontSize = "28";

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

      ./home-manager/nixos

      ./clojure.nix
      ./docker.nix
      ./email.nix
      ./git.nix
      ./google-drive-ocamlfuse-service.nix
      ./haskell.nix
      ./libvirt.nix
      ./packages.nix
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

  i18n.defaultLocale = "en_US.UTF-8";

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
    hostName = builtins.getEnv "HOST";
  };

  hardware.opengl.extraPackages = with pkgs; [ vaapiVdpau ];

  services = {
    ipfs.enable = true;

    devmon.enable = true;

    mopidy = {
      enable = true;
      extensionPackages = with pkgs; [ mopidy-gmusic ];
      configuration = lib.generators.toINI {} {
        gmusic = {
          deviceid = "0123456789abcdef";
          username = "andreivolt";
          password = builtins.getEnv "ANDREIVOLT_GOOGLE_PASSWORD";
          bitrate = 320;
        };
      };
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
        config = "config ${config.users.users.avo.home}/.config/openvpn/conf";
        autoStart = false;
        authUserPass = {
          username = builtins.getEnv "OPENVPN_USERNAME";
          password = builtins.getEnv "OPENVPN_PASSWORD";
        };
      };
    };

    xserver = {
      enable = true;

      # displayManager.sddm.enable = true;
      # windowManager.sway.enable = true;
      layout = "fr";
      xkbOptions = "ctrl:nocaps";

      videoDrivers = [ "nvidia" ];

      libinput = {
        enable = true;
        naturalScrolling = true;
        accelSpeed = "0.4";
      };

      xrandrHeads =
        let withNvidiaTearingFix = { position, rotation ? "normal" }: ''
          Option "metamodes" "nvidia-auto-select ${position} {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On, Rotate=${rotation}}"
          Option "AllowIndirectGLXProtocol" "off"
          Option "TripleBuffer" "on"
        ''; in [
          {
            output = "DP-2";
            monitorConfig = withNvidiaTearingFix { position = "+2160+0"; rotation = "left"; };
          }
          {
            output = "DP-4";
            primary = true;
            monitorConfig = withNvidiaTearingFix { position = "+3840+2160"; };
          }
          {
            output = "DP-0";
            monitorConfig = withNvidiaTearingFix { position = "+3840+0"; };
          }
        ];

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
      "ipfs"
      "libvirtd"
      "wheel"
    ];
    openssh.authorizedKeys.keyFiles = [ ./avo.pub ];
  };

  home-manager.users.avo = rec {
    services = {
      dunst = {
        enable = true;
        settings = import ./dunstrc.nix {
          inherit theme;
          font = proportionalFont;
        };
      };

      unclutter.enable = true;

      dropbox.enable = true;
    };

    xresources.properties = {
      "Xcursor.theme" = "Adwaita";
      "Xcursor.size"  = 32;

      "*.font"        = "xft:${monospaceFont}:size=${toString fontSize}";

      "rofi.font"     = "${proportionalFont} ${launcherFontSize}";
      "rofi.theme"    = "avo";
    } // (with theme; {
      "*.background" = background; "*.foreground" = foreground;
      "*.color0"     = black;      "*.color8"     = gray;
      "*.color1"     = red;        "*.color9"     = lightRed;
      "*.color2"     = green;      "*.color10"    = lightGreen;
      "*.color3"     = yellow;     "*.color11"    = lightYellow;
      "*.color4"     = blue;       "*.color12"    = lightBlue;
      "*.color5"     = magenta;    "*.color13"    = lightMagenta;
      "*.color6"     = cyan;       "*.color14"    = lightCyan;

      "*.borderColor" = background;
      "*.colorUL"     = white;
      "*.cursorColor" = foreground;
    });

    home = {
      packages = with pkgs; [];

      keyboard = {
        layout = "fr";
        options = [ "ctrl:nocaps" ];
      };

      sessionVariables = {
        ALTERNATE_EDITOR            = "${pkgs.neovim}/bin/nvim";
        BLOCK_SIZE                  = "\'1";
        BROWSER                     = "${pkgs.qutebrowser}/bin/qutebrowser-open-in-instance";
        COLUMNS                     = 100;
        EDITOR                      = ''
                                        ${pkgs.emacs}/bin/emacsclient \
                                        --tty \
                                        --create-frame'';
        PAGER                       = ''
                                        less \
                                        --quit-if-one-screen \
                                        --no-init \
                                        --RAW-CONTROL-CHARS'';
        PATH                        = lib.concatStringsSep ":" [
                                        "$PATH"
                                        "$HOME/bin"
                                        "$HOME/.local/bin"
                                        "$HOME/.npm-packages/bin"
                                      ];
        QT_AUTO_SCREEN_SCALE_FACTOR = 1;
        GREP_COLOR                  = "43;30";
      };

      file = {
        ".cups/lpoptions".text = ''
           Default default
        '';

        ".curlrc".text = ''
          user-agent mozilla
          silent
          globoff
        '';

        ".httpie/config.json".text = lib.generators.toJSON {} {
          default_options = [
            "--pretty" "format"
            "--session" "default"
          ];
        };

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

        ".bitcoin/bitcoin.conf".text = lib.generators.toKeyValue {} {
          prune = 550;
        };

        ".nmprc".text = lib.generators.toKeyValue {} {
          prefix = "~/.npm-packages";
        };

        ".aws/config".text = lib.generators.toINI {} {
          default = {
            region = "eu-west-1";
          };
        };

        ".aws/credentials".text = lib.generators.toINI {} {
          default = {
            aws_access_key_id     = builtins.getEnv "AWS_ACCESS_KEY_ID";
            aws_secret_access_key = builtins.getEnv "AWS_SECRET_ACCESS_KEY";
          };
        };

        ".trc".text =
          let
            username       = "andreivolt";
            consumerKey    = builtins.getEnv "TWITTER_CONSUMER_KEY";
            consumerSecret = builtins.getEnv "TWITTER_CONSUMER_SECRET";
            token          = builtins.getEnv "TWITTER_TOKEN";
            secret         = builtins.getEnv "TWITTER_SECRET";
          in ''
            ---
            configuration:
              default_profile:
              - ${username}
              - ${consumerKey}
            profiles:
              ${username}:
                ${consumerKey}:
                  username: ${username}
                  consumer_key: ${consumerKey}
                  consumer_secret: ${consumerSecret}
                  token: ${token}
                  secret: ${secret}
          '';

        ".tmux.conf".text = ''
          set -g @plugin 'tmux-plugins/tpm'

          set -g @plugin 'tmux-plugins/tmux-sensible'

          set -g @plugin 'tmux-plugins/tmux-pain-control'

          set -g @plugin 'nhdaly/tmux-better-mouse-mode'
          set -g @scroll-speed-num-lines-per-scroll 1
          set -g mouse on

          set -g @plugin 'tmux-plugins/tmux-copycat'
          set -g @plugin 'tmux-plugins/tmux-yank'
          set -g @yank_selection 'primary'
          bind -T copy-mode-vi v   send -X begin-selection
          bind -T copy-mode-vi C-v send -X rectangle-toggle
          bind -T copy-mode-vi y   send -X copy-selection
          unbind p
          bind   p paste-buffer

          run '~/.tmux/plugins/tpm/tpm'

          set  -g base-index 1
          set  -g renumber-windows on
          set  -g monitor-activity on
          set  -g set-titles on
          set  -g set-titles-string "#T"

          set  -g status-style                 bg='${theme.background}',fg='${theme.foreground}'
          set  -g status-left                  '''
          set  -g status-right                 ' #S '
          set  -g window-status-format         ' #I: #W '
          set  -g window-status-current-format ' #I: #W '
          setw -g window-status-current-style  bg='${theme.black}',fg='${theme.white}'
          setw -g window-status-activity-style bg='${theme.yellow}'

          set  -g prefix C-a
          setw -g mode-keys vi
          set  -g mode-keys vi

          bind C-o previous-window
          bind C-i next-window
          bind s   split-window -v
          bind v   split-window -h
        '';

        ".local/share/rofi/themes/avo.rasi".text = import ./rofi-theme.nix { inherit theme; };

        ".gist".text = builtins.getEnv "GIST_TOKEN";
      };
    };

    xdg = {
      enable = true;

      configFile = {
        "alacritty/alacritty.yml".text =
          lib.generators.toYAML {} (
            import ./alacritty.nix {
              inherit theme monospaceFont;
              fontSize = fontSize;
          });

        "xmobar/xmobarrc".text =
           import ./xmobarrc.nix {
             inherit theme;
             font = proportionalFont;
           };
        "xmobar/bin/online-indicator" = {
          text = with theme; ''
            color=$(is-online && echo '${green}' || echo '${red}')
            symbol=$(is-online && echo ﯱ || echo ﯱ)

            echo "<fc=$color>$symbol</fc>"
          '';
          executable = true;
        };

        "youtube-dl.conf".text = ''
           --output %(title)s.%(ext)s
        '';

        "nixpkgs/config.nix".text = lib.generators.toPretty {} {
          allowUnfree = true;
        };

        "zathura/zathurarc".text = ''
          set incremental-search true
        '';

        "qutebrowser/autoconfig.yml".text =
          import ./qutebrowser.nix {
            inherit theme
                    proportionalFont
                    monospaceFont
                    pkgs;
          };

        "user-dirs.dirs".text = lib.generators.toKeyValue {} {
          XDG_DOWNLOAD_DIR = "$HOME/tmp";
          XDG_DESKTOP_DIR  = "$HOME/tmp";
        };

        "mimeapps.list".text = lib.generators.toINI {} {
           "Default Applications" = {
             "x-scheme-handler/http"                                                   = "qutebrowser.desktop";
             "x-scheme-handler/https"                                                  = "qutebrowser.desktop";
             "x-scheme-handler/ftp"                                                    = "qutebrowser.desktop";
             "text/html"                                                               = "qutebrowser.desktop";
             "application/xhtml+xml"                                                   = "qutebrowser.deskop";
             "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "libreoffice-writer.desktop";
             "application/pdf"                                                         = "zathura.desktop";
             "text/plain"                                                              = "emacs.desktop";
             "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"       = "calc.desktop";
             "application/xml"                                                         = "emacs.desktop";
             "x-scheme-handler/magnet"                                                 = "userapp-transmission-gtk-NWT3FZ.desktop";
           };
         };
      };
    };

    xsession = {
      enable = true;
      windowManager.command = "~/.local/bin/xmonad";
      initExtra =
        let wallpaperPath = "~/data/wallpapers/matterhorn.jpg";
        in with pkgs; ''
          # ${xorg.xsetroot}/bin/xsetroot -xcf ${gnome3.adwaita-icon-theme}/share/icons/Adwaita/cursors/left_ptr 32

          ${setroot}/bin/setroot -z ${wallpaperPath} -z ${wallpaperPath} -z ${wallpaperPath}
        '';
    };

    programs = {
      home-manager.enable = true;

      pianobar = {
        enable = true;

        config = {
          user = "andrei.volt@gmail.com";
          password = builtins.getEnv "PANDORA_PASSWORD";
          audio_quality = "high";
        };
     };

      mpv = {
        enable = true;

        config = {
          ao = "pulse";
          hwdec = "vdpau";
          profile = "opengl-hq";
          audio-display = "no";
        };
      };

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
          R               = "ramda";
          browser-history = "qutebrowser-history";
          e               = "${pkgs.emacs}/bin/emacsclient -s scratchpad --no-wait";
          fzf             = "${pkgs.fzf}/bin/fzf --color bw";
          gc              = "${pkgs.gitAndTools.hub}/bin/hub clone";
          git             = "${pkgs.gitAndTools.hub}/bin/hub";
          gr              = "cd $(${pkgs.git}/bin/git root)";
          grep            = "grep --color=auto";
          j               = "jobs -d | paste - -";
          l               = "ls";
          la              = "ls -a";
          ls              = "ls --group-directories-first --classify --dereference-command-line -v";
          mkdir           = "mkdir -p";
          rg              = "${pkgs.ripgrep}/bin/rg --smart-case --colors match:bg:yellow --colors match:fg:black";
          tree            = "${pkgs.tree}/bin/tree -F --dirsfirst";
          vi              = "${pkgs.neovim}/bin/nvim";
          vpnoff          = "sudo systemctl stop openvpn-us";
          vpnon           = "sudo systemctl start openvpn-us";
        } // {
          gdax            = "webapp https://www.gdax.com/trade/BTC-USD";
          pandora         = "webapp https://www.pandora.com/my-music";
        };

        history = rec {
          size = 99999;
          save = size;
          path = ".zsh_history";
          ignoreDups = true;
          share = true;
          extended = true;
          ignoreSpace = true;
          reduceBlanks = true;
        };

        setTerminalTitle = true;

        glob = {
          extended = true;
          case = false;
          complete = true;
        };

        enableInteractiveComments = true;

        enableDirenv = true;

        initExtra =
          let
            globalAliasesStr =
              let toStr = x: lib.concatStringsSep "\n"
                             (lib.mapAttrsToList (k: v: "alias -g ${k}='${v}'") x);
              in toStr {
                C  = "| wc -l";
                L  = "| less -R";
                H  = "| head";
                T  = "| tail";
                Y  = "| ${pkgs.xsel}/bin/xsel -b";
                N  = "2>/dev/null";
                F  = "| ${pkgs.fzf}/bin/fzf | xargs";
                FE = "| ${pkgs.fzf}/bin/fzf | ${pkgs.parallel}/bin/parallel -X --tty $EDITOR";
              };

            autoRlwrap = ''
              #zplug 'andreivolt/zsh-auto-rlwrap'
              #bindkey -M viins '^x' insert-rlwrap
              #bindkey -M vicmd '^x' insert-rlwrap
            '';

            functions = ''
              diff() { ${pkgs.wdiff}/bin/wdiff -n $@ | ${pkgs.colordiff}/bin/colordiff }
              open() { setsid xdg-open "$*" &>/dev/null }
              +x() { chmod +x "$*" }
            '';

            cdAliases = ''
              alias ..='cd ..'
              alias ...='cd .. && cd ..';
              alias ....='cd .. && cd .. && cd ..'
            '';

            completion = ''
              zstyle ':completion:*' menu select
              zstyle ':completion:*' rehash true
            '';

            plugins = ''
              source ~/.zplug/init.zsh
              zplug 'willghatch/zsh-hooks'; zplug load
              zplug 'andreivolt/zsh-prompt-lean'
              zplug 'andreivolt/zsh-vim-mode', defer:2; zplug load
              zplug 'zdharma/fast-syntax-highlighting'
              zplug 'hlissner/zsh-autopair', defer:2
              zplug 'chisui/zsh-nix-shell'
              zplug 'chrismwendt/auto-nix-shell'
              zplug load
            '';
          in ''
            ${cdAliases}
            ${globalAliasesStr}
            ${autoRlwrap}
            ${functions}
            ${completion}
            ${plugins}
         '';

         profileExtra = "source ~/.private.env";
      };
    };
  };

  security.sudo.wheelNeedsPassword = false;

  environment.variables = {
    IPFS_PATH = "/var/lib/ipfs/.ipfs";
    LIBVA_DRIVER_NAME = "vdpau";
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
        sansSerif = [ proportionalFont ];
      };
    };
    enableCoreFonts = true;
    fonts = with pkgs; [
      emacs-all-the-icons-fonts
      font-awesome-ttf
      google-fonts
      hack-font
      hasklig
      iosevka-custom
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

  systemd.user.services = {
    ircEmacsDaemon = makeEmacsDaemon "irc";
    mailEmacsDaemon = makeEmacsDaemon "mail";
    editorEmacsDaemon = makeEmacsDaemon "scratchpad";
  };
}
