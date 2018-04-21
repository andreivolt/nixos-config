{ config, pkgs, ... }:

let
  remarshal = pkgs.callPackage /home/avo/proj/nixpkgs/pkgs/development/tools/remarshal/default.nix {};

in
{
  environment.systemPackages = with pkgs; [
    # fovea
    # hachoir-subfile hachoir-urwid hachoir-grep hachoir-metadata
    # haskellPackages.haskell-awk
    # imagemin-cli
    # incron
    # mpris-ctl
    # perl.rename
    # pfff
    # q
    # telegramircd
    bashdb
    bindfs
    blueman
    byzanz
    cabal2nix
    catdoc
    clerk
    cloc
    copyq
    dstat
    ed
    evtest
    exiftool
    fatrace
    fdupes
    flac
    forkstat
    gifsicle
    gitAndTools.diff-so-fancy
    gnome3.zenity
    grc
    haskellPackages.hoogle
    hlint
    icdiff
    impressive
    iptraf-ng
    iw
    keybase
    lastfmsubmitd
    lnav
    lsyncd
    ltrace
    mosh
    mpdas
    mpdris2
    mpdscribble
    multitail
    notify-osd
    optipng
    pamixer
    pass
    pidgin
    ponymix
    procmail
    pythonPackages.ipython
    pythonPackages.jupyter
    pythonPackages.piep
    pythonPackages.scapy
    racket
    recutils
    renameutils
    reptyr
    rofi-pass
    rxvt_unicode-with-plugins urxvt_autocomplete_all_the_things
    sdcv goldendict
    shadowsocks-libev
    siege
    sox
    sshfs
    stow
    sysstat
    taskwarrior
    tcpflow
    termite
    tig
    unison
    vimpc
    weechat
    wmutils-core
    x11_ssh_askpass
    xbindkeys
    xcape
    xfontsel
    xnee
    xorg.xdpyinfo
    xorg.xgamma
    xorg.xkbevd
    xorg.xlsatoms
    xorg.xlsclients
    xorg.xmag
    xorg.xwininfo
    you-get
    zsh-powerlevel9k

    # polipo
    # autojump
    # gron
    # antigen-hs

    (neovim.override { vimAlias = true; })
    (stdenv.lib.overrideDerivation moreutils (attrs: rec { postInstall = moreutils.postInstall + "; rm $out/bin/parallel"; })) # prefer GNU parallel
    acpi lm_sensors pciutils usbutils
    alacritty
    alsaPlugins alsaUtils
    antiword csvtotable docx2txt html2text libxls miller pdfgrep pup remarshal unoconv x_x xidel xlsx2csv xml2 xsv
    aria wget
    asciinema gist tmate ttyrec
    aspell aspellDicts.en aspellDicts.fr
    awscli google-cloud-sdk
    bitcoin
    boot clojure leiningen lighttable lumo
    chromium firefox-devedition-bin google-chrome-dev qutebrowser torbrowser w3m
    colordiff wdiff
    curl httpie wsta
    dateutils
    direnv
    dnsutils geoipWithDatabase nmap traceroute whois
    docker-compose-zsh-completions docker-machine docker_compose nixops
    dropbox-cli
    dunst libnotify ntfy
    enscript ghostscript pandoc pdftk texlive.combined.scheme-full
    exiv2 file mediainfo binutils
    ffcast maim slop
    ffmpeg
    fzf highlight pythonPackages.pygments
    gcolor2
    ghc haskellPackages.brittany haskellPackages.hindent haskellPackages.stylish-haskell stack
    git gitAndTools.hub
    gnome3.adwaita-icon-theme
    gnupg lastpass-cli
    google-drive-ocamlfuse
    google-play-music-desktop-player mpc_cli mpv nodePackages.peerflix pianobar youtube-dl playerctl
    graphicsmagick imagemagick
    graphviz
    htop iotop linuxPackages.perf psmisc
    httping iftop mtr nethogs
    hy
    inkscape
    inotify-tools watchman
    jdk
    jq jo
    lf tree xfce.thunar
    libinput-gestures
    libreoffice-fresh
    lsof strace
    mailutils msmtp notmuch
    mitmproxy ngrep tcpdump wireshark
    mupdf poppler_utils (zathura.override { useMupdf = true; })
    netcat socat telnet
    nix-prefetch-scripts patchelf
    nix-zsh-completions
    nodejs-9_x
    ntfs3g
    openssl
    perlPackages.HTMLParser recode
    expect lr parallel perlPackages.DBDSQLite pv xe nq fd bfs
    et at
    redshift
    ripgrep
    rlwrap
    rofi
    rsync
    setroot seturgent
    sqlite
    sshuttle tsocks
    steam
    sxiv
    t tdesktop
    tesseract
    tmux abduco dvtm
    units
    unzip zip atool dtrx
    virt-viewer
    wirelesstools wpa_supplicant
    wmctrl xdotool
    xclip xsel
    xdg_utils
    xorg.xev
    xrandr-invert-colors
    xurls
    notify-desktop
    surfraw
  ];
}
