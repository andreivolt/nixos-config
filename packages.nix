{ config, pkgs, ... }:

let
  remarshal = pkgs.callPackage /home/avo/proj/nixpkgs/pkgs/development/tools/remarshal/default.nix {};
  neovim = pkgs.neovim.override { vimAlias = true; };
  moreutils = (pkgs.stdenv.lib.overrideDerivation pkgs.moreutils (attrs: rec { postInstall = pkgs.moreutils.postInstall + "; rm $out/bin/parallel"; })); # prefer GNU parallel
  zathura = pkgs.zathura.override { useMupdf = true; };

in
{
  environment.systemPackages = with pkgs; [
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

    gifsicle

    iptraf-ng

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

    weechat
    pidgin
    # https:++github.com/wee-slack/wee-slack
    # telegramircd

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

    dropbox-cli

    ffmpeg

    gcolor2

    gnupg
    keybase
    lastpass-cli
    openssl

    google-drive-ocamlfuse
    graphicsmagick
    imagemagick
    graphviz

    psmisc
    hy
    inkscape

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
    perlPackages.DBDSQLite
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

    t
    tdesktop

    tesseract

    units

    copyq
    xclip
    xsel


    xurls
    surfraw
  ] ++
  [
    cabal2nix
    nix-prefetch-scripts
    nix-repl
    nix-zsh-completions
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
    virt-viewer
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
  (with gitAndTools; [
    # haskellPackages.github-backup
    diff-so-fancy
    git
    git-imerge
    hub
    tig
  ]) ++
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
    chromium
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
    isync # https:++wiki.archlinux.org/index.php/Isync https:++gist.github.com/au/a271c09e8233f19ffb01da7f017c7269 https:++github.com/kzar/davemail
    mailutils
    msmtp
    notmuch
    procmail
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
    boot
    clojure
    leiningen
    lighttable
    lumo
    # https:++github.com/uswitch/ej
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
  ] ++
  (with haskellPackages; [
   apply-refact
   brittany
   ghc
   hindent
   hlint
   hoogle
   stack
   stylish-haskell
   #exe = haskell.lib.justStaticExecutables
  ]);
}
