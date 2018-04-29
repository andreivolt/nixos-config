{ config, pkgs, ... }:

let
  neovim = pkgs.neovim.override { vimAlias = true; };
  moreutils = (pkgs.stdenv.lib.overrideDerivation pkgs.moreutils (attrs: rec { postInstall = pkgs.moreutils.postInstall + "; rm $out/bin/parallel"; })); # prefer GNU parallel
  zathura = pkgs.zathura.override { useMupdf = true; };
  parallel = (pkgs.stdenv.lib.overrideDerivation pkgs.parallel (attrs: rec {
               nativeBuildInputs = attrs.nativeBuildInputs ++ [ pkgs.perlPackages.DBDSQLite ];
             }));
in
{
  environment.systemPackages = with pkgs; [
    xorg.xmessage
    # fovea
    # incron
    # mpris-ctl
    # pfff

    # polipo
    gnumake

    bashdb
    bindfs

    cloc

    ed

    fdupes

    flac
    sox
    optipng
    # imagemin-cli

    lbdb
    lsyncd

    mosh

    ngrok

    pythonPackages.ipython
    pythonPackages.jupyter

    pythonPackages.scapy
    qrencode
    racket

    rxvt_unicode-with-plugins
    urxvt_autocomplete_all_the_things
    alacritty
    termite

    neovim

    moreutils
    renameutils
    # perl.rename

    shadowsocks-libev

    siege

    sshfs

    taskwarrior

    unison


    x11_ssh_askpass

    xfontsel

    aria
    wget

    aspell
    aspellDicts.en
    aspellDicts.fr
    goldendict
    sdcv


    bitcoin

    colordiff
    icdiff
    wdiff

    dateutils

    gcolor2

    gnupg
    keybase
    lastpass-cli
    openssl

    graphviz

    psmisc
    hy

    inotify-tools
    watchman

    direnv

    jdk

    lf
    tree
    xfce.thunar

    libinput-gestures
    libreoffice-fresh

    nodejs-9_x

    ntfs3g

    expect

    lr
    parallel
    pv
    xe
    nq
    fd
    bfs

    et
    at

    redshift
    xrandr-invert-colors

    ripgrep

    rofi

    rsync

    sqlite

    sshuttle
    tsocks

    steam

    sxiv
    # pqiv

    # https:++github.com/wee-slack/wee-slack
    # telegramircd

    tesseract

    units

    copyq
    xclip
    xsel


    xurls
    surfraw
  ] ++
  [
    ffmpeg
    gifsicle
    graphicsmagick
    imagemagick
    inkscape
  ] ++
  [
    cabal2nix
    nix-prefetch-scripts
    nix-repl
    nix-zsh-completions
    nodePackages.node2nix
    patchelf
  ] ++
  [
    mupdf
    poppler_utils
    zathura
    impressive
  ] ++
  (with xorg; [
    xev
    wmutils-core
    xdpyinfo
    evtest
    xkbevd
    xbindkeys
    xcape
    xchainkeys
    gnome3.zenity
    xdg_utils
    # https:++github.com/waymonad/waymonad
  ]) ++
  [
    awscli
    docker-compose-zsh-completions
    docker-machine
    docker_compose
    google-cloud-sdk
    nixops
  ] ++
  [
    t
    tdesktop
    weechat
    pidgin
  ] ++
  [
    # https:++github.com/noctuid/tdrop
    # https:++github.com/rkitover/vimpager
    # https:++github.com/harelba/q
    # haskellPackages.vimus

    # materia-theme
    # numix-gtk-theme
    # adapta-gtk-theme

    # qtstyleplugin-kvantum-qt4
    # qtstyleplugins
    # qtstyleplugin-kvantum
    # QT_QPA_PLATFORMTHEME=gtk2
    gnome3.adwaita-icon-theme
    # breeze-gtk breeze-qt5 qt5ct
    lxappearance
    arc-theme
    arc-icon-theme
    polybar
    setroot
  ] ++
  [
    asciinema
    gist
    tmate
    ttyrec
  ] ++
  [
    google-play-music-desktop-player
    mpc_cli
    mpv
    # https://github.com/hoyon/mpv-mpris
    nodePackages.peerflix
    pianobar
    playerctl
    vimpc
    you-get
    youtube-dl
  ] ++
  [
    enscript
    ghostscript
    pandoc
    pdftk
    texlive.combined.scheme-full
  ] ++
  [
    acpi
    lm_sensors
    pciutils
    usbutils
  ] ++
  [
    seturgent
    wmctrl
    xdotool
    xnee
  ] ++
  [
    alsaPlugins
    alsaUtils
    pamixer
    ponymix
  ] ++
  [
    abduco
    dvtm
    tmux
    reptyr
  ] ++
  [
    httping
    iftop
    nethogs
  ] ++
  [
    curl
    httpie
    wsta
  ] ++
  [
    dstat
    htop
    iotop
    linuxPackages.perf
    sysstat
  ] ++
  [
    firefox-devedition-bin
    google-chrome-dev
    qutebrowser
    torbrowser
    w3m
  ] ++
  [
    clerk
    lastfmsubmitd
    mpdas
    mpdris2
    mpdscribble
    nodePackages.peerflix
    pianobar
    playerctl
    youtube-dl
  ] ++
  [
    binutils
    exiftool
    exiv2
    file
    mediainfo
    # hachoir-subfile
    # hachoir-urwid
    # hachoir-grep
    # hachoir-metadata
  ] ++
  [
    dnsutils
    geoipWithDatabase
    mtr
    nmap
    traceroute
    whois
  ] ++
  [
    byzanz
    ffcast
    maim
    slop
  ] ++
  [
    fatrace
    forkstat
    lsof
    ltrace
    strace
  ] ++
  [
    notify-desktop
    libnotify
    ntfy
  ] ++
  [
    # gron
    # tsvutils
    antiword
    catdoc
    csvtotable
    docx2txt
    html2text
    htmlTidy
    jo
    jq
    libxls
    miller
    pdfgrep
    perlPackages.HTMLParser
    pup
    pythonPackages.piep
    recode
    recutils
    remarshal
    textql
    unoconv
    x_x
    xidel
    xlsx2csv
    xml2
    xsv
    # haskellPackages.haskell-awk
  ] ++
  [
    atool
    dtrx
    unzip
    zip
  ] ++
  [
    mitmproxy
    netcat
    ngrep
    socat
    stunnel # https:++gist.github.com/jeremiahsnapp/6426298
    tcpdump
    tcpflow
    telnet
    wireshark
  ] ++
  [
    # antigen-hs
    # autojump
    # https:++github.com/rupa/z
    # https://github.com/zplug/zplug
    fzf
    grc
    highlight
    lnav
    multitail
    pythonPackages.pygments
    rlwrap
    zsh-powerlevel9k
  ] ++
  [
    iw
    wirelesstools
    wpa_supplicant
  ];
}
