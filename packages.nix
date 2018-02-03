{ config, pkgs, ... }:

let
  docker-compose-completions = pkgs.callPackage ./packages/docker-compose-completions.nix {};

  docx2txt = pkgs.callPackage ./packages/docx2txt.nix {};

  miller = pkgs.callPackage ./packages/miller.nix {};

in {
  environment.systemPackages = with pkgs; [
    #bitcoin
    #csvtotable
    #x_x
    (lowPrio moreutils) # prefer GNU parallel
    (lowPrio texlive.combined.scheme-full)
    antiword
    androidsdk
    aria
    jdk
    awscli
    azure-cli
    binutils
    boot
    cups
    curl
    dateutils
    direnv
    dnsutils
    docker-machine
    docker_compose docker-compose-completions
    docx2txt
    dosfstools
    emacs
    enscript
    exiv2
    expect
    ffcast
    ffmpeg
    file
    fzf
    gcc
    geoipWithDatabase
    ghc
    ghostscript
    gist
    git
    gitAndTools.hub
    gnumake
    go-pup
    go_1_6
    google-cloud-sdk
    graphicsmagick
    graphviz
    highlight
    html2text
    httpie
    iftop
    imagemagick
    inotify-tools
    iotop
    jo
    jq
    lastpass-cli
    leiningen
    libxls
    #linuxPackages.perf
    lsof
    mailutils
    mariadb
    mediainfo
    miller
    mongodb
    mongodb-tools
    msmtp
    mutt
    netcat
    nethogs
    netpbm
    ngrep
    nix-prefetch-scripts
    nix-zsh-completions
    nmap
    nodejs-8_x
    notmuch
    notmuch-addrlookup
    notmuch-mutt
    ntfs3g
    ocrad
    offlineimap
    openssl
    pandoc
    parallel perlPackages.DBDSQLite
    pdfgrep
    pdftk
    perlPackages.HTMLParser
    pgcli
    poppler_utils
    postgresql
    psmisc
    pv
    python
    python27Packages.goobook
    python27Packages.setuptools
    python35Packages.pygments
    recode
    remarshal
    ripgrep
    rlwrap
    rsync
    ruby
    rxvt_unicode-with-plugins
    socat
    sqlite
    strace
    t
    tcpdump
    telnet
    tesseract
    tmate
    tmux
    torsocks
    traceroute
    tree
    tsocks
    units
    unoconv
    unzip
    urlview
    usbutils
    vimHugeX
    w3m
    wdiff
    weechat
    wget
    whois
    xdg_utils
    xlsx2csv
    xml2
    xurls
    yarn
    youtube-dl
    zip
    stack
    neomutt
    gradle
    watchman
    fira-code
    redis
    hack-font
    profont
    steam-run
    steam
    camingo-code
    google-drive-ocamlfuse
    asciinema
    ttyrec
    tdesktop
    st
    httping
  ];
}
