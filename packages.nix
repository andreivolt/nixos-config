{ config, pkgs, ... }:

let
  docker-compose-completions = pkgs.callPackage ./packages/docker-compose-completions.nix {};
  docx2txt = pkgs.callPackage ./packages/docx2txt.nix {};
  libinput-gestures = pkgs.callPackage ./packages/libinput-gestures/default.nix {};
  miller = pkgs.callPackage ./packages/miller.nix {};
  wsta = pkgs.callPackage ./packages/wsta.nix {};

in {
  environment.systemPackages = with pkgs; [
    (lowPrio texlive.combined.scheme-full)
    #chromiumDev
    #csvtotable
    #go_1_6
    #neovim
    #t
    #wsta
    #x_x
    (lowPrio gcc)
    (lowPrio moreutils) # prefer GNU parallel
    acpi
    alacritty
    alsaPlugins
    alsaUtils
    antiword
    aria
    asciinema
    aspell
    aspellDicts.en
    awscli
    binutils
    bitcoin
    boot
    chromium
    clojure
    curl
    dateutils
    direnv
    dnsutils
    docker-machine
    docker_compose docker-compose-completions
    docx2txt
    dosfstools
    dropbox-cli
    dunst
    enscript
    exiv2
    expect
    ffcast
    ffmpeg
    file
    firefox-devedition-bin
    fzf
    gcolor2
    geoipWithDatabase
    (lowPrio ghc)
    ghostscript
    gist
    git
    gitAndTools.hub
    gnumake
    gnupg
    go-pup
    google-cloud-sdk
    google-drive-ocamlfuse
    graphicsmagick
    graphviz
    highlight
    html2text
    httpie
    httping
    hy
    iftop
    imagemagick
    inkscape
    inotify-tools
    iotop
    jdk
    jo
    jq
    kitty
    lastpass-cli
    leiningen
    libevent
    libinput-gestures
    libnotify
    libreoffice-fresh
    libxls
    lighttable
    linuxPackages.perf
    lsof
    mailutils
    maim
    mariadb
    mediainfo
    miller
    mitmproxy
    mongodb
    mongodb-tools
    mpv
    msmtp
    mupdf
    neomutt
    netcat
    nethogs
    ngrep
    nix-prefetch-scripts
    nix-zsh-completions
    nixops
    nmap
    nodejs
    notmuch
    notmuch-addrlookup
    notmuch-mutt
    ntfs3g
    openssl
    pandoc
    parallel perlPackages.DBDSQLite
    patchelf
    pciutils
    pdfgrep
    pdftk
    perlPackages.HTMLParser
    pgcli
    pianobar
    ponymix
    poppler_utils
    postgresql
    psmisc
    pv
    python
    python35Packages.pygments
    recode
    redshift
    remarshal
    ripgrep
    rlwrap
    rofi
    rsync
    ruby
    rxvt_unicode-with-plugins
    setroot
    slop
    socat
    sqlite
    sshuttle
    stack
    strace
    sxhkd
    sxiv
    tcpdump
    tdesktop
    telnet
    tesseract
    tmate
    tmux
    torbrowser
    traceroute
    tree
    tsocks
    ttyrec
    units
    unoconv
    unzip
    urlview
    usbutils
    vaapiVdpau
    vimHugeX
    virt-viewer
    w3m
    watchman
    wdiff
    weechat
    wget
    whois
    wmctrl
    xbindkeys
    xclip
    xdg_utils
    xdotool
    xfce.thunar
    xlsx2csv
    xml2
    xorg.xev
    xorg.xinput
    xorg.xrandr
    xorg.xset
    xrandr-invert-colors
    xsel
    xurls
    yarn
    youtube-dl
    zathura
    zip
  ];
}
