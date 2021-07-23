{ lib, pkgs, ... }:

let
  vim = pkgs.callPackage ./modules/vim.nix { };

  packages = with pkgs; [
    # (pkgs.youtube-viewer.overrideAttrs (oldAttrs: rec { src = /home/avo/gdrive/youtube-viewer; }))
    # alsaPlugins
    # chromiumDev
    # csvtotable
    # docker-compose-zsh-completions
    # docx2txt
    # geoipWithDatabase
    # ghi
    # gitAndTools.diff-so-fancy
    # hachoir-subfile
    # haskellPackages.apply-refact
    # haskellPackages.brittany
    # haskellPackages.github-backup
    # haskellPackages.hindent
    # haskellPackages.hlint
    # haskellPackages.hoogle
    # haskellPackages.stylish-haskell
    # impressive # PDF presentations
    # jwhois
    # libxls # xls2csv
    # mpc
    # mpc_cli
    # mpdas
    # mpdris2
    # mpdscribble # MPD scrobbler
    # nodePackageS.pnpm
    # nodePackages.node2nix
    # perlPackages.DBDSQLite # for GNU parallel
    # perlPackages.HTMLParser
    # pfff # source code tool
    # pnpm
    # pythonPackages.ipython
    # pythonPackages.jupyter
    # pythonPackages.piep
    # pythonPackages.piep # Python stream editing
    # pythonPackages.scapy
    # record-query
    # renameutils # imv collision
    # speechd
    # texlive.combined.scheme-full
    # torbrowser
    # traceroute
    # wsta # websocket cli
    # x_x # Excel + CSV cli viewer
    (aspellWithDicts (dicts: with dicts; [ en en-computers fr ])) # TODO
    (hunspellWithDicts (with hunspellDicts; [ en-us fr-moderne ])) # TODO
    (zathura.override { useMupdf = true; })
    abduco
    acpi
    alsaUtils
    antiword
    archivemount
    aria
    asciinema
    at
    atool # archive
    avo.colorpicker
    avo.pushover
    avo.scripts
    avo.zprint
    awscli
    babashka
    bashdb # bash debugger
    bat
    bc
    bfs # breadth-first find
    bindfs
    binutils
    bitcoin
    bluetooth_battery
    perl532Packages.FileMimeInfo
    boot
    broot # tree file navigator
    cabal2nix
    cachix
    catdoc # Word/Excel/PowerPoint to text
    choose # cut/ awk alternative
    chromedriver
    cifs-utils
    clipman
    cloc
    clojure
    colordiff
    copyq # clipboard manager
    cups
    curl
    curlie
    dateutils
    delta
    discord
    dmenu-wayland
    dnscontrol
    dnsutils
    docker-compose
    docker-machine
    dogdns
    dos2unix
    dropbox-cli
    dstat # resource statistics
    dtach # detach from terminals
    dtrx # unarchiver
    dupd # find duplicates
    dvtm # terminal multiplexer
    ed
    elixir
    enscript # convert to PostScript
    entr # run commands when files change
    envchain
    evince # fill PDF forms
    exa
    exiftool
    exiv2 # image metadata
    expect
    fastlane # automate mobile app releases
    fatrace
    fd
    fdupes # find duplicates
    ffmpeg-full # -full for ffplay
    file
    firefox
    flac
    flac123
    flashfocus # Wayland window animations
    flyctl # fly.io
    foot # Wayland terminal
    forkstat
    fpp # path picker
    freerdp
    fswatch
    fswebcam # webcam photo
    fuse
    fx # JSON processing tool
    fzf
    fzy
    gcc
    gcolor2 # color chooser
    gh
    ghc # Haskell
    ghostscript
    gifsicle
    gist
    git
    git-hub
    git-imerge # Git incremental merge
    gitAndTools.tig
    glava # audio spectrum visualizer
    glib.bin
    glpaper
    gnumake
    gnupg
    go
    goldendict # dictionnary
    google-chrome
    google-cloud-sdk
    google-drive-ocamlfuse
    gphotos-sync
    graphicsmagick
    graphviz
    gron # flatten JSON
    grc # syntax highlighter
    gsettings-desktop-schemas
    hachoir
    haskellPackages.ShellCheck
    heroku
    highlight # cli syntax highlighter
    himalaya # email client
    home-manager
    html2text
    htmlTidy # html
    httpie # http client
    httping # http benchmark
    hub # github
    hy # python lisp
    icdiff # side-by-side highlighted diffs
    iftop
    imv
    inkscape
    inotify-tools
    inxi
    iotop
    ipfs
    iptraf-ng
    iw # wifi
    jdk
    jo # create JSON
    jq
    jre # for Android
    keybase
    kotatogram-desktop # Telegram
    lastfmsubmitd
    lastpass-cli
    lf # file navigator
    libarchive # bsdtar
    libnotify
    libreoffice-fresh
    lighttable # Clojure IDE
    linuxPackages.perf
    llpp # pdf pager
    lm_sensors
    lnav # logfile navigator
    lsd # ls alternative
    lsof
    lsyncd # sync files with remote
    ltrace
    lumo # standalone ClojureScript environment
    mailutils
    matrix-commander # matrix cli
    mediainfo
    megatools
    miller # field processing for CSV
    mitmproxy
    moreutilsWithoutParallel # moreutils parallel conflicts with GNU parallel
    mosh
    mpvc # mpv remote
    msmtp
    mtr # network diagnostics
    multitail
    mupdf
    ncdu
    neochat # matrix client
    neomutt
    neovide
    net-snmp # network
    netcat
    nethogs
    ngrep
    ngrok
    nix-index
    nix-update
    nixfmt
    nixopsUnstable
    nmap
    nodePackages.firebase-tools
    nodePackages.peerflix
    nodePackages.webtorrent-cli
    notmuch
    nox # search Nix packages
    nq # queue
    ntfy # send notifications, on demand and when commands finish
    nvimpager
    obex_data_server # bluetooth D-Bus
    openssl
    optipng
    page
    pamixer
    pandoc
    parallel
    pass
    patchelf
    pavucontrol
    pciutils
    pdfgrep
    pdftk
    pianobar
    pidgin
    play-with-mpv # open browser videos with mpv
    playerctl # mpris cli
    ponymix
    poppler_utils # pdf2text
    pqiv # image viewer
    procmail
    procs # ps alternative
    projectm # music visualizer
    protonvpn-cli
    psmisc
    pup
    puppeteer-cli
    pv # pipe viewer
    pwgen
    python3
    python39Packages.internetarchive
    pythonPackages.pygments
    qemu
    qutebrowser
    racket
    ranger
    recode
    recutils
    remarshal # CBOR/JSON/MessagePack/TOML/YAML converter
    rename
    reptyr # reparent process to new terminal
    ripgrep
    rlwrap
    rmlint # find duplicates
    rsync
    ruby
    sd # find & replace
    sdcv # dictionnary
    shadowsocks-libev # SOCKS5 proxy
    siege # http benchmarking
    skype
    slack
    slop # query a selection and print to stdout
    socat
    sox
    speedtest_cli
    sqlite
    sshfsFuse
    sshuttle # ssh VPN
    stack
    steam
    strace
    sublime3
    surf
    surfraw
    t
    tcpdump
    tcpflow
    tdesktop # Telegram
    telnet
    tesseract
    tmate
    tree
    tsocks
    ttyrec
    ungoogled-chromium # or chromium
    unison # file sync
    units
    unoconv
    unrar
    unzip
    urlview
    urlwatch
    usbutils
    vgrep # grep pager
    vifm
    vim
    virt-viewer
    virtualbox
    vlc
    w3m
    watchman # file watcher
    wayback_machine_downloader
    wdiff # word diff
    wf-recorder
    wget
    wgetpaste
    wine
    wirelesstools
    wireshark
    with-shell # cd inside commands
    wpa_supplicant
    wtype # GUI automation
    xdg_utils
    xh # HTTP client
    xidel
    xlsx2csv
    haskellPackages.xml-to-json
    nix-prefetch-github
    xml2
    xmlindent
    xmlstarlet
    xsel
    xurls
    xxd
    yarn
    yarn2nix
    ydotool
    you-get
    youtube-dl
    youtube-viewer
    ytfzf # YouTube search
    zip
  ];

in {
  imports = [
    ./hardware-configuration.nix

    (let rev = "0423a7b40cd29aec0bb02fa30f61ffe60f5dfc19";
    in import "${builtins.fetchTarball "https://github.com/rycee/home-manager/archive/${rev}.tar.gz"}/nixos")

    ./profiles/gui.nix
    ./profiles/workstation.nix

    # ./modules/weechat-matrix.nix
    ./modules/adb.nix
    ./modules/alacritty/alacritty.nix
    ./modules/aria2.nix
    ./modules/cloudflare-dns.nix
    ./modules/clojure/rebel-readline.nix
    ./modules/command-not-found.nix
    ./modules/curl.nix
    ./modules/gtk.nix
    ./modules/weechat.nix
    ./modules/docker.nix
    ./modules/libvirt.nix
    ./modules/firefox-wayland.nix
    ./modules/fonts.nix
    ./modules/fzf.nix
    ./modules/git.nix
    ./modules/gnome-keyring.nix
    ./modules/grep.nix
    ./modules/hardware-video-acceleration.nix
    ./modules/hardware-video-acceleration/mpv.nix
    ./modules/hidpi/console.nix
    ./modules/hidpi/gnome.nix
    ./modules/hosts-blocking.nix
    ./modules/insync.nix
    ./modules/ipfs.nix
    ./modules/kdeconnect.nix
    ./modules/less.nix
    ./modules/locate.nix
    ./modules/lowbatt.nix
    ./modules/map-test-tld-to-localhost.nix
    ./modules/matrix-cli.nix
    ./modules/mpv.nix
    ./modules/npm-global-packages.nix
    ./modules/pipewire.nix
    ./modules/readline/inputrc.nix
    ./modules/ripgrep.nix
    ./modules/spotify.nix
    ./modules/sway/sway.nix
    ./modules/tor.nix
    ./modules/zsh/fzf.nix
    ./modules/zsh/vi.nix
  ];

  system.autoUpgrade = {
    enable = true;
    channel = "https://nixos.org/channels/nixos-unstable";
  };

  system.stateVersion = "19.09";

  nix = {
    gc.automatic = true;
    optimise.automatic = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = let
    waylandOverlay =
      let url =
        let rev = "fd3be17ace1aa22ed6b1d0bd01a979deb098cbbd";
        in "https://github.com/colemickens/nixpkgs-wayland/archive/${rev}.tar.gz";
      in import (builtins.fetchTarball url);
  in with pkgs; [
    waylandOverlay
    (import ./packages)
    (self: super: {
      moreutilsWithoutParallel = lib.overrideDerivation super.moreutils (attrs: {
        postInstall = attrs.postInstall + "\n"
          + "rm $out/bin/parallel $out/share/man/man1/parallel.1";
      });
    })
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Paris";

  console.keyMap = "fr";

  users.users.avo = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
  };

  home-manager.users.avo = { pkgs, ... }: rec {
    home.packages = packages;

    home.sessionVariables = {
      EDITOR = "${vim}/bin/vim";
      PAGER = "${pkgs.page}/bin/page";
      BROWSER = "${pkgs.google-chrome}/bin/google-chrome-stable";
    };

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = {
      "application/pdf" = "mupdf.desktop";
      "image/jpeg" = "imv.desktop";
      "image/png" = "imv.desktop";
      "text/html" = "google-chrome-stable.desktop";
      "text/plain" = "neovide.desktop";
      "video/mp4" = "mpv.desktop";
      "x-scheme-handler/http" = "google-chrome-stable.desktop";
      "x-scheme-handler/https" = "google-chrome-stable.desktop";
      "x-scheme-handler/tg" = "telegramdesktop.desktop";
    };

    programs.zsh = {
      enable = true;

      enableCompletion = true;

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
          src = pkgs.fetchFromGitHub {
            owner = "chisui";
            repo = "zsh-nix-shell";
            rev = "v0.2.0";
            sha256 = "1gfyrgn23zpwv1vj37gf28hf5z0ka0w5qm6286a7qixwv7ijnrx9";
          };
        }
        {
          name = "fast-syntax-highlighting";
          file = "fast-syntax-highlighting.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "zdharma";
            repo = "fast-syntax-highlighting";
            rev = "5ed7c0fa0be5e456a131a2378af10b5c03131a7e";
            sha256 = "0g3vzaixwjl9rjxc8waq1458kqjg8hsgsaz3ln6a1jm8cd7qca50";
          };
        }
        {
          name = "autopair";
          file = "autopair.zsh";
          src = pkgs.fetchFromGitHub {
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

        source ${./modules/zsh/prompt.zsh}
        source ${./modules/zsh/terminal-title.zsh}

        acd() {
          local tmp=$(mktemp -d)
          archivemount "$*" $tmp
          cd $tmp
        }
      '';
    };
  };

  services.lowbatt = {
    enable = true;
    notifyCapacity = 40;
    suspendCapacity = 10;
  };

  services.upower.enable = true;

  services.sshd.enable = true;

  virtualisation.virtualbox.host.enable = true;

  # services.udisks2.enable = true;
}
