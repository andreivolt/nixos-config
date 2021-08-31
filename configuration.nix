{ lib, pkgs, config, ... }:

{
  imports = let
    home-manager-module = let
      rev = "604561ba9ac45ee30385670b18f15731c541287b";
      sha256 = "01mj8kqk8gv5v64dmbhx5mk0sz22cs2i0jybnlicv7318xzndzxk";
    in import "${
      fetchTarball {
        inherit sha256;
        url = "https://github.com/nix-community/home-manager/archive/${rev}.tar.gz";
      }
    }/nixos";
  in [
    ./hardware-configuration.nix
    home-manager-module
    ./cachix.nix

    # ./modules/dropbox.nix
    # ./modules/emacs.nix
    # ./modules/himalaya.nix # email client
    # ./modules/ipfs.nix
    # ./modules/keybase-sync.nix
    # ./modules/networkmanager-iwd.nix
    # ./modules/plymouth.nix
    # ./modules/wayland/wl-clipboard-x11.nix
    # ./modules/wayvnc.nix
    # ./modules/weechat-matrix.nix
    ./modules/adb.nix
    ./modules/adblock.nix
    ./modules/alacritty/alacritty.nix
    ./modules/aria2.nix
    ./modules/chrome
    ./modules/clipman.nix
    ./modules/clojure
    ./modules/clojure/boot
    ./modules/clojure/rebel-readline.nix
    ./modules/cloudflare-dns.nix
    ./modules/command-not-found.nix
    ./modules/curl.nix
    ./modules/direnv.nix
    ./modules/docker.nix
    ./modules/firefox-wayland.nix
    ./modules/flashfocus.nix
    ./modules/fonts.nix
    ./modules/foot.nix
    ./modules/fzf.nix
    ./modules/git.nix
    ./modules/github.nix
    ./modules/gnome-keyring.nix
    ./modules/gnupg.nix
    ./modules/grep.nix
    ./modules/gtk.nix
    ./modules/hardware-video-acceleration.nix
    ./modules/hardware-video-acceleration/mpv.nix
    ./modules/hidpi/console.nix
    ./modules/hidpi/gnome.nix # TODO: dconf needed?
    ./modules/hidpi/qt.nix
    ./modules/insync.nix
    ./modules/kdeconnect.nix
    ./modules/keybase.nix
    ./modules/less.nix
    ./modules/libvirt.nix
    ./modules/locate.nix
    ./modules/lowbatt.nix
    ./modules/mako.nix
    ./modules/map-test-tld-to-localhost.nix
    ./modules/matrix-cli.nix
    ./modules/mdns.nix
    ./modules/mpv.nix
    ./modules/networkmanager.nix
    ./modules/ngrok.nix
    ./modules/pipewire.nix
    ./modules/play-with-mpv.nix
    ./modules/printing.nix
    ./modules/readline/inputrc.nix
    ./modules/ripgrep.nix
    ./modules/scanning.nix
    ./modules/spotify.nix
    ./modules/sway-autorotate-screen.nix
    ./modules/sway-autostart.nix
    ./modules/sway.nix
    ./modules/swayidle.nix
    ./modules/swaylock.nix
    ./modules/tailscale.nix
    ./modules/tmux.nix
    ./modules/tor.nix
    ./modules/v4l2loopback.nix
    ./modules/virtualbox-host.nix
    ./modules/wayland.nix
    ./modules/weechat.nix
    ./modules/wireguard.nix
    ./modules/wob.nix
    ./modules/xdg-desktop-portal.nix
    ./modules/zsh/fzf.nix
    ./modules/zsh/prompt.nix
    ./modules/zsh/vi.nix
  ];

  hardware.bluetooth.enable = true;
  hardware.opengl.enable = true;

  networking.hostName = builtins.getEnv "HOSTNAME";

  services.sshd.enable = true;

  # services.udisks2.enable = true;

  documentation.man.generateCaches = true;

  environment.etc."mailcap".text = "*/*; xdg-open '%s'";

  security.sudo.wheelNeedsPassword = false;

  # automount removable devices
  services.devmon.enable = true;

  system.stateVersion = "19.09";

  nix = {
    gc.automatic = true;
    optimise.automatic = true;
    # nixPath = [
    #   "/home/avo/gdrive/nixos-config"
    #   "nixpkgs=/home/avo/gdrive/nixpkgs"
    #   "nixos-config=/home/avo/gdrive/nixos-config/configuration.nix"
    # ];
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (import ./packages)
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Paris";

  console.keyMap = "fr";

  # users.mutableUsers = false; # TODO

  users.users.avo = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
  };

  home-manager.users.avo = { pkgs, ... }:
    let
      vim = pkgs.callPackage ./modules/vim { };
      startsway = pkgs.writeShellScriptBin "startsway" ''
        systemctl --user import-environment

        exec systemd-cat \
          --identifier sway \
          dbus-run-session -- \
            ${pkgs.sway}/bin/sway --debug
      '';
    in rec {
      nixpkgs.overlays = let
        nixpkgsUnstable = self: super: {
          nixpkgsUnstable = let
            nixpkgs-unstable-src = fetchTarball
              "https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.xz";
          in import nixpkgs-unstable-src { };
        };
      in config.nixpkgs.overlays ++ [
        (_: _: { inherit startsway; })
        (_: super: {
          moreutilsWithoutParallel = lib.overrideDerivation super.moreutils (attrs: {
            postInstall = attrs.postInstall + "\n"
              + "rm $out/bin/parallel $out/share/man/man1/parallel.1";
          });
        })
        nixpkgsUnstable
      ];

      home.packages = with pkgs; [
        # (pulseaudio.overrideAttrs (oldAttrs: rec {
        #   patches = [
        #     (fetchpatch {
        #       url = "https://gitlab.freedesktop.org/pulseaudio/pulseaudio/-/commit/19adddee31ca34bf4e0db95df01b4ec595f2d267.patch";
        #       sha256 = "0kqw1nnlzcx7k5n7mmgin219r2gc6j3ygxvdds9nc7p8b4qis1w6";
        #     })
        #   ];
        # }))

        (zathura.override { useMupdf = true; })
        acpi
        archivemount
        aria
        atool # archive
        avo.pushover
        avo.zprint # clojure pretty-printer
        babashka # clojure
        bat
        bc # calculator
        binutils
        breeze-gtk # gtk qt
        breeze-qt5 # gtk qt
        gnome-breeze # gtk
        cachix # nixos
        chromedriver
        # cloc # count lines of code
        curl
        dateutils # dategrep
        dragon-drop # file drag-and-drop source/sink
        dtrx # unarchiver
        # expect # terminal automation
        fatrace # file access events
        fd # find alternative
        ffmpeg
        file
        firefox # TODO: xdg desktop associations
        fpp # path picker
        fzf # fuzzy finder
        gcolor2 # color chooser
        gh # github
        gist # github
        git-hub # github
        gnupg
        google-chrome # browser
        google-cloud-sdk # cloud
        usbutils # lsusb
        googler # google search cli
        graphicsmagick # image, tools
        gron # flatten JSON
        hr # horizontal rule
        htmlTidy # html
        httpie # http client
        hub # github
        imgurbash2 # file-sharing
        imv # image viewer
        inotify-tools # file watcher
        jc # json
        jo # create JSON
        jq # json
        keybase
        lastpass-cli
        leiningen # clojure
        libnotify # notify-send
        libreoffice-fresh
        ngrok
        lm_sensors
        lsof # system
        lxqt.pavucontrol-qt
        mailutils # email
        mediainfo # metadata
        monolith # web-archive
        moreutilsWithoutParallel # moreutils parallel conflicts with GNU parallel # for vipe & vidir
        neochat # matrix client
        neovide # vim, gui
        netcat # networking
        ngrep # networking
        nix-prefetch-github # nixos
        nix-prefetch-scripts # nixos
        nixfmt # code formatter, nix
        nixops # cloud, nixos
        nmap # network
        nox # search Nix packages
        ntfy # send notifications, on demand and when commands finish
        openssl
        pamixer # audio
        pandoc
        parallel
        patchelf
        pavucontrol # audio
        playerctl # mpris, cli
        ponymix # audio
        pqiv # image viewer
        protonvpn-cli # vpn
        psmisc
        pup # html
        pv # pipe viewer
        python3Packages.pipx # install & run Python packages in isolated environments
        rdrview # content extractor
        recode # encoding
        ripgrep
        rlwrap
        rsync
        simple-scan # scanning
        skype
        socat
        sqlite
        startsway
        strace
        sublime3 # text-editor
        surfraw
        swappy # image annotation
        t # twitter
        tdesktop # Telegram
        # telegram-cli
        telnet # network
        tesseract4 # ocr
        tmate # tmux remote sharing
        tmpmail # disposable email
        tree
        units
        vim
        wget
        xsel
        xurls
        youtube-viewer
        yt-dlp # youtube
      ];

      home.sessionVariables = {
        EDITOR = "${vim}/bin/vim";
        PAGER = "${pkgs.nvimpager}/bin/nvimpager";
        BROWSER = "${pkgs.google-chrome}/bin/google-chrome-stable";
      };

      home.sessionPath = [
        "$HOME/gdrive/bin"
        (builtins.toString ./bin)
      ];

      xdg.enable = true;

      xdg.mimeApps.enable = true;
      xdg.mimeApps.defaultApplications = {
        "application/pdf" = "zathura.desktop";
        "image/jpeg" = "imv.desktop";
        "image/png" = "imv.desktop";
        "text/html" = "google-chrome-stable.desktop";
        "text/plain" = "neovide.desktop";
        "video/mp4" = "mpv.desktop";
        "x-scheme-handler/http" = "google-chrome-stable.desktop";
        "x-scheme-handler/https" = "google-chrome-stable.desktop";
      };

      programs.zsh = {
        enable = true;

        enableCompletion = true;

        enableSyntaxHighlighting = true;

        defaultKeymap = "viins";

        # enableInteractiveComments = true;

        history = rec {
          size = 99999;
          save = size;
          share = true;
          ignoreSpace = true;
          ignoreDups = true;
          extended = true;
          path = ".cache/zsh_history";
        };

        shellGlobalAliases = {
          H = "| head";
          T = "| tail";
          C = "| wc -l";
          G = "| grep";
          L = "| ${home.sessionVariables.PAGER}";
          NE = "2>/dev/null";
          NUL = "&>/dev/null";
        };

        shellAliases = {
          ls = "ls --human-readable --classify";
          git = "GPG_TTY=$(tty) git";
          l = "ls -1";
          la = "ls -a";
          ll = "ls -l";
          grep = "grep --color";
          vi = "vim";
        };

        plugins = with pkgs; [
          {
            name = "zsh-nix-shell";
            file = "nix-shell.plugin.zsh";
            src = fetchFromGitHub {
              owner = "chisui";
              repo = "zsh-nix-shell";
              rev = "v0.2.0";
              sha256 = "1gfyrgn23zpwv1vj37gf28hf5z0ka0w5qm6286a7qixwv7ijnrx9";
            };
          }
          # {
          #   name = "fast-syntax-highlighting";
          #   file = "fast-syntax-highlighting.plugin.zsh";
          #   src = fetchFromGitHub {
          #     owner = "zdharma";
          #     repo = "fast-syntax-highlighting";
          #     rev = "5ed7c0fa0be5e456a131a2378af10b5c03131a7e";
          #     sha256 = "0g3vzaixwjl9rjxc8waq1458kqjg8hsgsaz3ln6a1jm8cd7qca50";
          #   };
          # }
          {
            name = "autopair";
            file = "autopair.zsh";
            src = fetchFromGitHub {
              owner = "hlissner";
              repo = "zsh-autopair";
              rev = "8c1b2b85ba40b9afecc87990c884fe5cf9ac56d1";
              sha256 = "0aa87r82w431445n4n6brfyzh3bnrcf5s3lhih1493yc5mzjnjh3";
            };
          }
        ];
        initExtra = ''
          # trigger completion on globbing
          setopt glob_complete
          # remove extraneous spaces from saved commands
          setopt hist_reduce_blanks
          # show menu when completing
          zstyle ':completion:*' menu select
          # automatically update PATH
          zstyle ':completion:*' rehash true
          # automatically add directories to the directory stack
          setopt auto_pushd

          source ${./modules/zsh/terminal-title.zsh}

          acd() {
            local tmp=$(mktemp -d)
            archivemount "$*" $tmp
            cd $tmp
          }

          ancestors() {
            pstree -p --show-parents --arguments $$ --unicode \
            | highlight yellow '(?<=,)[0-9]*'
          }

          highlight() {
            rg \
              --passthru \
              --colors "match:fg:$1" --color always \
              --pcre2 "$2"
          }

          bcat() {
            local f=$(mktemp).html
            cat > $f
            $BROWSER $f
          }

          # overwrite previous line
          overwrite() {
            echo -e "\r\033[1A\033[0K$@"
          }

          html-man() {
            man $@ \
            | ${pkgs.rman}/bin/rman -f html \
            | bcat
          }
        '';
      };
    };

  services.lowbatt = {
    enable = true;
    notifyCapacity = 40;
    suspendCapacity = 10;
  };

  # networking.networkmanager.dns = "dnsmasq";

  services.upower.enable = true;

  # networking.wireless.iwd.enable = true;

  programs.steam.enable = true;
}
