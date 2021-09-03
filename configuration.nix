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

    nix-ld-module = let
      rev = "cac5bd577da26aefdabc742340a156414ac08890";
      sha256 = "11ayyqdl2a36h5zl6mmcahla4zl7rdg5nqyxbnwvmaz90gry10s1";
    in import "${
      fetchTarball {
        inherit sha256;
        url = "https://github.com/Mic92/nix-ld/archive/${rev}.tar.gz";
      }
    }/modules/nix-ld.nix";
  in [
    ./hardware-configuration.nix
    home-manager-module
    nix-ld-module
    ./cachix.nix

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
    ./modules/cuff.nix # torrent search cli
    ./modules/curl.nix
    ./modules/direnv.nix
    ./modules/docker.nix
    # ./modules/dropbox.nix
    # ./modules/emacs.nix
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
    # ./modules/himalaya.nix # email client
    ./modules/insync.nix
    # ./modules/ipfs.nix
    ./modules/kdeconnect.nix
    ./modules/keybase-files.nix
    # ./modules/keybase-sync.nix
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
    # ./modules/networkmanager-iwd.nix
    ./modules/networkmanager.nix
    ./modules/ngrok.nix
    ./modules/pipewire.nix
    ./modules/play-with-mpv.nix
    # ./modules/plymouth.nix # boot animations
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
    # ./modules/wayland/wl-clipboard-x11.nix
    # ./modules/wayvnc.nix
    # ./modules/weechat-matrix.nix
    ./modules/weechat.nix
    ./modules/wireguard.nix
    ./modules/wob.nix
    ./modules/xdg-desktop-portal.nix
    ./modules/zsh/fzf.nix
    ./modules/zsh/prompt.nix
    ./modules/zsh/vi.nix
    ./modules/zsh/functions.nix
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
    nixPath = [
      "nixpkgs=/home/avo/gdrive/nixpkgs"
      "nixos-config=/home/avo/gdrive/nixos-config/configuration.nix"
    ];
  };

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = let
    nixpkgsUnstable = self: super: {
      nixpkgsUnstable =
        let nixpkgs-unstable-src = fetchTarball "https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.xz";
        in import nixpkgs-unstable-src { };
    };
  in [
    nixpkgsUnstable
    (import ./packages)
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Paris";

  console.keyMap = "fr";

  users.users.avo = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
  };

  home-manager.users.avo = { pkgs, ... }:
    let
      vim = pkgs.callPackage ./modules/vim { };
    in rec {
      nixpkgs.overlays =
        config.nixpkgs.overlays
        ++ [
          (_: super: {
            moreutilsWithoutParallel = super.moreutils.overrideAttrs (attrs: {
              postInstall = attrs.postInstall + "\n"
                + "rm $out/bin/parallel $out/share/man/man1/parallel.1";
            });
          })
        ];

      home.packages = with pkgs; [
        # audd-cli # music recognition cli
        acpi
        apktool
        archivemount
        aria
        atool # archive
        avo.pushover
        babashka # clojure
        bat
        bc # calculator
        binutils
        breeze-gtk # gtk qt
        breeze-qt5 # gtk qt
        cachix # nixos
        chromedriver
        cloc
        # cloc # count lines of code
        curl
        cv # progress viewer for running coreutils
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
        rnix-lsp # nix language server
        gist # github
        git-hub # github
        gnome-breeze # gtk
        gnupg
        (google-chrome.override { commandLineArgs = "--force-device-scale-factor=2"; })
        google-cloud-sdk # cloud
        googler # google search cli
        graphicsmagick # image, tools
        gron # flatten JSON
        haskellPackages.aeson-pretty # format json
        hr # horizontal rule
        html2text
        htmlTidy # html
        httpie # http client
        hub # github
        imagemagick # some things don't work with graphicsmagick
        imgurbash2 # file-sharing
        imv # image viewer
        inkscape
        inotify-tools # file watcher
        jc # json
        jo # create JSON
        jq # json
        keybase
        lastpass-cli
        leiningen # clojure
        libnotify # notify-send
        libreoffice-fresh
        lm_sensors
        lsof # system
        lxqt.pavucontrol-qt
        mailutils # email
        mdcat # terminal markdown viewer
        mediainfo # metadata
        monolith # web-archive
        moreutilsWithoutParallel # moreutils parallel conflicts with GNU parallel # for vipe & vidir
        neochat # matrix client
        neovide # vim, gui
        netcat # networking
        ngrep # networking
        ngrok
        # nix-info
        nix-prefetch-github # nixos
        nix-prefetch-scripts # nixos
        nixfmt # code formatter, nix
        nixops # cloud, nixos
        # nixos-shell
        nmap # network
        nodePackages.webtorrent-cli
        # nodePackages.json
        nodejs
        nox # search Nix packages
        ntfy # send notifications, on demand and when commands finish
        openssl
        pamixer # audio
        pandoc
        parallel
        patchelf
        pavucontrol # audio
        pciutils # lspci
        playerctl # mpris, cli
        ponymix # audio
        potrace # convert bitmap to vector
        pqiv # image viewer
        protonvpn-cli # vpn
        psmisc
        pulseaudio # for pactl
        pup # html
        pv # pipe viewer
        python3
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
        strace
        sublime3 # text-editor
        surfraw
        swappy # image annotation
        t # twitter
        tdesktop # Telegram
        # telegram-cli
        telnet # network
        tesseract4 # ocr
        tldr # documentation
        tmate # tmux remote sharing
        tmpmail # disposable email
        tree
        units
        unzip
        # urlscan
        usbutils # lsusb
        vim
        wget
        xsel
        xurls
        youtube-viewer
        yt-dlp # youtube
        (zathura.override { useMupdf = true; })
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
          size = 999999;
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
        '';
      };
    };

  services.lowbatt = {
    enable = true;
    notifyCapacity = 40;
    suspendCapacity = 10;
  };

  services.upower.enable = true;

  programs.steam.enable = true;

  # networking.networkmanager.dns = "dnsmasq";
  # networking.wireless.iwd.enable = true;
  services.flatpak.enable = true;
}
