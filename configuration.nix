{ config, pkgs, lib, ... }:

let
  hostName = "${builtins.getEnv "HOST"}";

  makeEmacsDaemon = name: (import ./make-emacs-daemon.nix { inherit config pkgs; name = name; });

  theme = import ./challenger-deep-theme.nix;
  proportionalFont = "Abel"; monospaceFont = "Source Code Pro";
  fontSize = 11; launcherFontSize = 32;

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

      ./packages.nix
      ./docker-nginx-proxy.nix
      ./clojure.nix
      ./haskell.nix
      ./email.nix
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
    hostName = hostName;
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
        config = '' config /home/avo/.config/openvpn/conf '';
        autoStart = false;
      };
    };

    xserver = {
      enable = true;

      # displayManager.sddm.enable = true;
      # windowManager.sway.enable = true;

      videoDrivers = [ "nvidia" ];

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

      dropbox.enable = true;
    };

    xresources.properties = {
      "Xft.dpi"       = 192;
      "Xft.hintstyle" = "hintfull";

      "Xcursor.theme" = "Adwaita";
      "Xcursor.size"  = 42;

      "*.font"        = "xft:${monospaceFont}:size=${toString fontSize}";

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

      "rofi.font"     = "${proportionalFont} ${toString launcherFontSize}";
      "rofi.theme"    = "avo";
    };

    home = {
      packages = with pkgs; [];

      keyboard = {
        layout = "fr";
        options = [ "ctrl:nocaps" ];
      };

      sessionVariables = {
        ALTERNATE_EDITOR            = "${pkgs.neovim}/bin/nvim";
        BLOCK_SIZE                  = "\'1";
        BOOT_JVM_OPTIONS            = "-client -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -Xverify:none";
        BROWSER                     = "qutebrowser-open";
        COLUMNS                     = 100;
        EDITOR                      = "${pkgs.emacs}/bin/emacsclient";
        PAGER                       = "less";
        PATH                        = lib.concatStringsSep ":" [
                                        "$PATH"
                                        "$HOME/bin"
                                        "$HOME/.local/bin"
                                        "$HOME/.npm-packages/bin"
                                      ];
        QT_AUTO_SCREEN_SCALE_FACTOR = 1;
        SSH_AUTH_SOCK               = "$XDG_RUNTIME_DIR/ssh-agent.socket";
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

        ".ghci".text = ''
          :set prompt "λ "
        '';

        ".aws/config".text = lib.generators.toINI {} {
          default = {
            region = "eu-west-1";
          };
        };

        ".aws/credentials".text = lib.generators.toINI {} {
          default = {
            aws_access_key_id = builtins.getEnv "AWS_ACCESS_KEY_ID";
            aws_secret_access_key = builtins.getEnv "AWS_SECRET_ACCESS_KEY";
          };
        };

        ".trc".text = ''
          ---
          configuration:
            default_profile:
            - andreivolt
            - ${builtins.getEnv "TWITTER_CONSUMER_KEY"}
          profiles:
            andreivolt:
              ${builtins.getEnv "TWITTER_CONSUMER_KEY"}:
                username: andreivolt
                consumer_key: ${builtins.getEnv "TWITTER_CONSUMER_KEY"}
                consumer_secret: ${builtins.getEnv "TWITTER_CONSUMER_SECRET"}
                token: ${builtins.getEnv "TWITTER_TOKEN"}
                secret: ${builtins.getEnv "TWITTER_SECRET"}
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
          bind -T copy-mode-vi v send -X begin-selection
          bind -T copy-mode-vi C-v send -X rectangle-toggle
          bind -T copy-mode-vi y send -X copy-selection
          unbind p
          bind p paste-buffer

          run '~/.tmux/plugins/tpm/tpm'

          set -g base-index 1
          set -g renumber-windows on
          set -g monitor-activity on
          set -g set-titles on
          set -g set-titles-string "#T"
          set -g status-style bg='${theme.background}',fg='${theme.foreground}'
          set -g status-left ' #S '
          set -g status-left-length 100
          set -g status-right '''
          set -g window-status-format ' #I: #W '
          set -g window-status-current-format ' #I: #W '
          setw -g window-status-current-style bg='${theme.black}',fg='${theme.white}'
          setw -g window-status-activity-style bg='${theme.yellow}'

          set -g prefix C-a
          setw -g mode-keys vi
          set -g mode-keys vi

          bind C-o previous-window
          bind C-i next-window
          bind x choose-session
          bind s split-window -v
          bind v split-window -h
        '';

        ".local/share/rofi/themes/avo.rasi".text = import ./rofi-theme.nix { inherit theme; };

        "bin/qutebrowser-open" = {
          text = "${pkgs.qutebrowser}/share/qutebrowser/scripts/open_url_in_instance.sh $1";
          executable = true;
        };

        ".gist".text = builtins.getEnv "GIST_TOKEN";
      };
    };

    xdg = {
      enable = true;

      configFile = {
        "mpv/mpv.conf".text = lib.generators.toKeyValue {} {
          ao = "pulse";
          hwdec = "vdpau";
          profile = "opengl-hq";
          audio-display = "no";
        };

        "alacritty/alacritty.yml".text =
          lib.generators.toYAML {} (
            import ./alacritty.nix {
              inherit theme monospaceFont;
              fontSize = toString fontSize;
          });

        "xmobar/xmobarrc".text =
           import ./xmobarrc.nix {
             inherit theme;
             font = proportionalFont;
           };
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

        "openvpn/auth.txt".text = ''
          ${builtins.getEnv "VPN_USER"}
          ${builtins.getEnv "VPN_PASSWORD"}
        '';

        "nixpkgs/config.nix".text = lib.generators.toPretty {} {
          allowUnfree = true;
        };

        "pianobar/config".text = lib.generators.toKeyValue {} {
          user = "andrei.volt@gmail.com";
          password = builtins.getEnv "PANDORA_PASSWORD";
          audio_quality = "high";
        };

        "zathura/zathurarc".text = ''
          set incremental-search true
        '';

        "hub".text = lib.generators.toYAML {} {
          "github.com" = {
            user = "andreivolt";
            oauth_token = builtins.getEnv "GITHUB_OAUTH_TOKEN";
          };
        };

        "qutebrowser/autoconfig.yml".text = import ./qutebrowser.nix { inherit theme proportionalFont monospaceFont pkgs; };

        "virt-viewer/settings".text = lib.generators.toINI {} {
          virt-viewer = {
            ask-quit = false;
          };
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
             "application/pdf"                                                         = "zathura-pdf-mupdf.desktop";
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
      windowManager.command = "xmonad";
      initExtra = let wallpaperPath = "~/data/wallpapers/matterhorn.jpg"; in ''
        xsetroot -xcf ${pkgs.gnome3.adwaita-icon-theme}/share/icons/Adwaita/cursors/left_ptr 42

        setroot -z ${wallpaperPath} -z ${wallpaperPath} -z ${wallpaperPath}
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
          R               = "ramda";
          browser-history = "qutebrowser-history";
          e               = "emacsclient -s scratchpad --no-wait";
          fzf             = "fzf --color bw";
          gc              = "git clone";
          gdax            = "webapp https://www.gdax.com/trade/BTC-USD";
          git             = "hub";
          gr              = "cd $(git root)";
          grep            = "grep --color=auto";
          j               = "jobs -d | paste - -";
          l               = "ls";
          la              = "ls -a";
          ls              = "ls --group-directories-first --classify --dereference-command-line -v";
          mkdir           = "mkdir -p";
          rg              = "rg --smart-case --colors match:bg:yellow --colors match:fg:black";
          rm              = "timeout 3 rm -Iv --one-file-system";
          stack           = "stack --nix";
          tree            = "tree -F --dirsfirst";
          vi              = "nvim";
          vpnoff          = "sudo systemctl stop openvpn-us";
          vpnon           = "sudo systemctl start openvpn-us";
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
            globalAliasesStr = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (k: v: "alias -g ${k}='${v}'") globalAliases
            );

            globalAliases = {
              C   = "| wc -l";
              L   = "| less -R";
              H   = "| head";
              T   = "| tail";
              Y   = "| xsel -b";
              DN  = "2>/dev/null";
              FZ  = "| fzf | xargs";
              FZV = "| fzf | parallel -X --tty $EDITOR";
            };

            autoRlwrap = ''
              #zplug 'andreivolt/zsh-auto-rlwrap'
              #bindkey -M viins '^x' insert-rlwrap
              #bindkey -M vicmd '^x' insert-rlwrap
            '';

            functions = ''
              diff() { wdiff -n $@ | colordiff }
              open() { setsid xdg-open "$*" &>/dev/null }
              +x() { chmod +x "$*" }
            '';

            cdAliases = ''
              alias ..='cd ..'
              alias ...='cd .. && cd ..';
              alias ....='cd .. && cd .. && cd ..';
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

         profileExtra = "source ~/.private";
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
    IPFS_PATH = "/var/lib/ipfs/.ipfs";
    LIBVIRT_DEFAULT_URI = "qemu:///system";
    LIBVA_DRIVER_NAME = "vdpau";
  };

  programs = {
    adb.enable = true;
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
