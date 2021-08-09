{ lib, pkgs, ... }:

let
  vim = pkgs.callPackage ./modules/vim { };

  packages = with pkgs; [
    # (pkgs.youtube-viewer.overrideAttrs (oldAttrs: rec { src = /home/avo/gdrive/youtube-viewer; }))
    # avo.wsta # websocket cli
    # chromiumDev
    # csvtotable
    # docx2txt
    # ghi
    # gitAndTools.diff-so-fancy
    # hachoir-subfile
    # haskellPackages.github-backup # BROKEN
    # imagemin-cli
    # impressive # PDF presentations
    # ipfs-deploy
    # jdk11 # collision
    # jwhois
    # kefctl
    # libxls # xls2csv
    # mailutils # home-manager comsatd conflict
    # mpc
    # mpc_cli
    # mpdas
    # mpdris2
    # mpdscribble # MPD scrobbler
    # perlPackages.DBDSQLite # for GNU parallel
    # perlPackages.HTMLParser
    # pfff # source code tool
    # puppeteer-cli # compiles chrome
    # pythonPackages.ipython
    # pythonPackages.jupyter
    # pythonPackages.piep # Python stream editing
    # pythonPackages.scapy
    # record-query
    # renameutils # imv collision
    # speechd
    # texlive.combined.scheme-full # ghostscript collision
    # traceroute
    # wl-recorder # wayland screen recording
    # x_x # Excel + CSV cli viewer
    (aspellWithDicts (dicts: with dicts; [ en en-computers fr ])) # TODO
    (hunspellWithDicts (with hunspellDicts; [ en-us fr-moderne ])) # TODO
    (zathura.override { useMupdf = true; })
    abduco
    acpi
    alsaPlugins
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
    avo.zprint # clojure pretty-printer
    awscli
    babashka
    bashdb # bash debugger
    bat
    bc
    bemenu
    bfs # breadth-first find
    bindfs
    binutils
    bitcoin
    bluetooth_battery
    bluez
    bluez-tools
    boot
    broot # tree file navigator
    cabal2nix
    cachix
    catdoc # Word/Excel/PowerPoint to text
    choose # cut/ awk alternative
    chromedriver
    cifs-utils
    clipman
    cloc # count lines of code
    nixpkgsUnstable.clojure
    clojure-lsp
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
    dragon-drop # drag-and-drop source/sink
    dropbox-cli
    dstat # resource statistics
    dtach # detach from terminals
    dtrx # unarchiver
    dupd # find duplicates
    dvtm # terminal multiplexer
    ed
    efibootmgr
    efivar
    elixir
    enscript # convert to PostScript
    entr # file watcher, run commands when files change
    envchain
    envsubst
    ethtool
    evince # fill PDF forms
    exa # ls alternative
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
    fzf # fuzzy finder
    fzy # fuzzy finder
    gcc
    gcolor2 # color chooser
    geckodriver # Firefox automation
    geoipWithDatabase
    gh # github
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
    googler # google search cli
    gphotos-sync
    graphicsmagick
    graphviz
    grc # syntax highlighter
    gron # flatten JSON
    hachoir
    haskellPackages.apply-refact
    haskellPackages.hlint
    haskellPackages.hnix
    haskellPackages.ShellCheck
    haskellPackages.stylish-haskell
    haskellPackages.xml-to-json
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
    hydroxide # protonmail
    hyperfine # benchmarking
    icdiff # side-by-side highlighted diffs
    iftop # network
    imgur-screenshot # file-sharing
    imgurbash2 # file-sharing
    imv # image viewer
    inkscape
    inotify-tools # file watcher
    inxi
    iotop # network
    ipfs
    iptraf-ng # network
    iw # wifi
    iwd # wifi
    jo # create JSON
    jq
    jre # for Android
    jtc # json
    keybase
    keybase-gui
    kotatogram-desktop # Telegram
    lastfmsubmitd
    lastpass-cli
    leiningen # clojure
    lf # file navigator
    libarchive # bsdtar
    libguestfs # for mounting qcow2 images
    libnotify
    libreoffice-fresh
    lighttable # Clojure IDE
    linuxPackages.perf
    lm_sensors
    lnav # logfile navigator
    lsd # ls alternative
    lshw
    lsof
    lsyncd # sync files with remote
    ltrace
    lumo # standalone ClojureScript environment
    lynx # terminal browser
    mailutils
    mate.caja # file manager
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
    ncdu
    neochat # matrix client
    neomutt
    neovide
    net-snmp # network
    netcat
    nethogs
    netlify-cli
    ngrep
    ngrok
    nix-index
    nix-prefetch-github
    nix-prefetch-scripts
    nix-update
    nixfmt
    nixops
    nmap
    nnn # file browser
    nodejs
    nodePackages.create-react-native-app
    nodePackages.expo-cli
    nodePackages.firebase-tools
    nodePackages.node2nix
    nodePackages.nodemon
    nodePackages.peerflix
    nodePackages.pnpm # nodejs package manager
    nodePackages.webtorrent-cli
    notmuch
    nox # search Nix packages
    nq # queue
    ntfy # send notifications, on demand and when commands finish
    nvimpager
    obex_data_server # bluetooth D-Bus
    obexd
    obexfs # bluetooth filesystem
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
    perl
    perl532Packages.FileMimeInfo
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
    protonmail-bridge # protonmail
    protonvpn-cli
    psmisc
    pup
    pv # pipe viewer
    pwgen
    python3
    python39Packages.internetarchive
    python3Packages.pip
    python3Packages.pipx # install & run Python packages in isolated environments
    pythonPackages.pygments
    qemu
    qutebrowser
    racket
    ranger
    rclone # backups
    rdrview # content extractor
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
    s3cmd
    screen
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
    stress-ng # benchmarking
    sublime3
    surf
    surfraw
    sysbench # benchmarking
    t
    tcpdump
    tcpflow
    tdesktop # Telegram
    telnet
    terraform
    tesseract4 # ocr
    tmate
    tmpmail # disposable email
    tmux # terminal multiplexer
    torbrowser
    tree
    tsocks
    ttyrec
    ungoogled-chromium # or chromium
    unison # file sync
    units
    unoconv
    unrar
    unzip
    urlscan
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
    wayvnc # remote desktop
    wdiff # word diff
    wf-recorder # wayland screen recording
    wget
    wgetpaste
    wine
    wirelesstools
    wireshark
    with-shell # cd inside commands
    wol # wake-on-lan
    wpa_supplicant
    wtype # GUI automation
    xdg_utils
    xh # HTTP client
    xidel
    xlsx2csv
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
    zoxide # cd alternative
  ];

in {
  imports = let
    home-manager-module =
      let rev = "2c4234cb79684646657f9cfcd4075c3122845670";
      in import "${builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/${rev}.tar.gz"}/nixos";
  in [
    ./hardware-configuration.nix

    home-manager-module
    ./cachix.nix

    ./profiles/gui.nix
    ./profiles/workstation.nix

    # ./modules/weechat-matrix.nix
    ./modules/wayland/overlay.nix
    ./modules/adb.nix
    ./modules/clojure
    ./modules/alacritty/alacritty.nix
    ./modules/clojure/boot
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
    ./modules/moreutils-without-parallel/overlay.nix
    ./modules/locate.nix
    ./modules/lowbatt.nix
    ./modules/map-test-tld-to-localhost.nix
    ./modules/matrix-cli.nix
    ./modules/mpv.nix
    ./modules/pipewire.nix
    ./modules/readline/inputrc.nix
    ./modules/keybase.nix
    ./modules/ripgrep.nix
    ./modules/gnupg.nix
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
    nixpkgsUnstable = self: super: {
      nixpkgsUnstable = let
        nixpkgs-unstable-src = fetchTarball https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.xz;
      in
        # sudo nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
        # nixpkgs-unstable-src = <nixpkgs-unstable>;
        import nixpkgs-unstable-src { config = { allowUnfree = true; }; };
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

    home.sessionPath = [
      "$HOME/gdrive/bin"
      (builtins.toString ./bin)
    ];

    xdg.mimeApps.associations.added = {
      "x-scheme-handler/http" = "google-chrome-stable.desktop";
      "x-scheme-handler/https" = "google-chrome-stable.desktop";
    };
    xdg.mimeApps.associations.removed = {
      "x-scheme-handler/http" = "chromium-browser.desktop";
      "x-scheme-handler/https" = "chromium-browser.desktop";
    };

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
      "x-scheme-handler/tg" = "telegramdesktop.desktop";
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
        l = "ls -1";
        la = "ls -a";
        ll = "ls -l";
        grep = "grep --color";
        vi = "vim";
      };

      plugins = with pkgs; [
        { name = "zsh-nix-shell"; file = "nix-shell.plugin.zsh"; src = zsh-nix-shell; }
        { name = "fast-syntax-highlighting"; file = "fast-syntax-highlighting.plugin.zsh"; src = zsh-fast-syntax-highlighting; }
        { name = "autopair"; file = "autopair.zsh"; src = zsh-autopair; }
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

        # overwrite previous line
        overwrite() { echo -e "\r\033[1A\033[0K$@" }
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
