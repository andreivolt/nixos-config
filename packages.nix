{ config, pkgs, ... }:

let
  docker-compose-zsh-completions = pkgs.callPackage ./packages/docker-compose-zsh-completions.nix {};
  docx2txt = pkgs.callPackage ./packages/docx2txt.nix {};
  libinput-gestures = pkgs.callPackage ./packages/libinput-gestures/default.nix {};
  wsta = pkgs.callPackage ./packages/wsta.nix {};
  lumo = pkgs.callPackage /home/avo/proj/nixpkgs/pkgs/development/interpreters/clojure/lumo.nix {};

in {
  environment.systemPackages = with pkgs; [
    #chromiumBeta
    #csvtotable
    #wsta
    #x_x
    (lowPrio gcc)
    (lowPrio ghc)
    (lowPrio moreutils) # prefer GNU parallel
    (lowPrio texlive.combined.scheme-full)
    acpi
    alacritty
    alsaPlugins
    alsaUtils
    antiword
    aria
    asciinema
    aspell aspellDicts.en aspellDicts.fr
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
    docker_compose docker-compose-zsh-completions
    docx2txt
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
    ghostscript
    gist
    git
    gitAndTools.hub
    gnome3.gtk
    gnumake
    gnupg
    go
    google-cloud-sdk
    google-drive-ocamlfuse
    graphicsmagick
    graphviz
    haskellPackages.hindent
    haskellPackages.xmobar
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
    libinput-gestures
    libnotify
    libreoffice-fresh
    libxls
    lighttable
    linuxPackages.perf
    lm_sensors
    lsof
    lumo
    mailutils
    maim
    mediainfo
    miller
    mitmproxy
    mpv
    msmtp
    mupdf
    neovim
    netcat
    nethogs
    ngrep
    nix-prefetch-scripts
    nix-zsh-completions
    nixfmt
    nixops
    nmap
    nodejs-8_x yarn
    notmuch
    ntfs3g
    openssl
    pandoc
    parallel perlPackages.DBDSQLite
    patchelf
    pciutils
    pdfgrep
    pdftk
    perlPackages.HTMLParser
    pianobar
    ponymix
    poppler_utils
    psmisc
    pup
    pv
    python
    pythonPackages.pygments
    ranger
    recode
    redshift
    remarshal
    ripgrep
    rlwrap
    rofi
    rsync
    rxvt_unicode-with-plugins
    setroot
    slop
    socat
    speechd
    sqlite
    sshuttle
    strace
    svox
    sxhkd
    sxiv
    t
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
    wget
    whois
    wirelesstools wpa_supplicant
    wireshark
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
    xorg.xmodmap
    xorg.xrandr
    xorg.xset
    xrandr-invert-colors
    xsel
    xurls
    youtube-dl
    zathura
    zip
  ];
}
