{ config, lib, pkgs, ... }:

rec {
  imports = [
    ./hardware-configuration.nix

    ./home-manager/nixos

    ./hardware

    ./gui
    ./netrc.nix
    ./networking
    ./shell.nix

    # ./programs/ramda.nix
    ./programs/alacritty.nix
    ./programs/android.nix
    ./programs/aws-cli.nix
    ./programs/bitcoin.nix
    ./programs/clojure
    ./programs/curl.nix
    ./programs/docker
    ./programs/dropbox.nix
    ./programs/editor-scratchpad.nix
    ./programs/editor.nix
    ./programs/emacs.nix
    ./programs/email
    ./programs/floobits.nix
    ./programs/fzf.nix
    ./programs/ghi.nix
    ./programs/gist.nix
    ./programs/git.nix
    ./programs/gnupg.nix
    ./programs/google-drive.nix
    ./programs/grep.nix
    ./programs/haskell
    ./programs/htop.nix
    ./programs/httpie.nix
    ./programs/hub.nix
    ./programs/ipfs.nix
    ./programs/irc.nix
    ./programs/less.nix
    ./programs/libvirt.nix
    ./programs/mitmproxy.nix
    ./programs/mopidy.nix
    ./programs/mpv.nix
    ./programs/neovim.nix
    ./programs/netflix.nix
    ./programs/nodejs.nix
    ./programs/pandora.nix
    ./programs/parallel.nix
    ./programs/pianobar.nix
    ./programs/qutebrowser.nix
    ./programs/readline.nix
    ./programs/ripgrep.nix
    ./programs/slack.nix
    ./programs/ssh.nix
    ./programs/sxiv.nix
    ./programs/t.nix
    ./programs/tmux.nix
    ./programs/todos.nix
    ./programs/zathura.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernel.sysctl =
    { "fs.inotify.max_user_watches" = 100000; } //
    { "vm.swappiness" = 1; "vm.vfs_cache_pressure" = 50; };

  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.avo = { isNormalUser = true; extraGroups = [ "wheel" ]; };
  security.sudo.wheelNeedsPassword = false;

  nix = {
    buildCores = 0;
    gc.automatic = true; optimise.automatic = true;
  };

  system.autoUpgrade = { enable = true; channel = "https://nixos.org/channels/nixos-unstable"; };

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays =
    let path = ./overlays; in with builtins;
    map (n: import (path + ("/" + n)))
        (filter (n: match ".*\\.nix" n != null || pathExists (path + ("/" + n + "/default.nix")))
                (attrNames (readDir path)));

  home-manager.users.avo = {
    nixpkgs.config = config.nixpkgs.config;

    home.sessionVariables = with config.home-manager.users.avo; {
      BROWSER = "${pkgs.qutebrowser}/bin/qutebrowser-open-in-instance";
      EDITOR  = "${pkgs.neovim}/bin/nvim";
      PATH    = lib.concatStringsSep ":" [ "$PATH" "$HOME/.local/bin" ];
    };

    xdg.enable = true;

    xdg.configFile."user-dirs.dirs".text = lib.generators.toKeyValue {} {
      XDG_DOWNLOAD_DIR = "$HOME/tmp";
      XDG_DESKTOP_DIR  = "$HOME/tmp";
    };

    xdg.configFile."mimeapps.list".text =
      let browser = "qutebrowser"; editor = "emacs"; in lib.generators.toINI {} {
        "Default Applications" = {
          "application/pdf"                                                         = "zathura.desktop";
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"       = "calc.desktop";
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "libreoffice-writer.desktop";
          "application/xhtml+xml"                                                   = "${browser}.desktop";
          "application/xml"                                                         = "${editor}.desktop";
          "text/html"                                                               = "${browser}.desktop";
          "text/plain"                                                              = "${editor}.desktop";
          "x-scheme-handler/ftp"                                                    = "${browser}.desktop";
          "x-scheme-handler/http"                                                   = "${browser}.desktop";
          "x-scheme-handler/https"                                                  = "${browser}.desktop";
        };
      };
  };

  services.devmon.enable = true;

  fileSystems."scripts" = {
    device = "/etc/nixos/scripts";
    fsType = "none"; options = [ "bind" ];
    mountPoint = "/home/avo/.local/bin";
  };

  environment.systemPackages = with pkgs; [
    # fovea
    # hachoir-subfile hachoir-urwid hachoir-grep hachoir-metadata
    # https://github.com/harelba/q
    # https://github.com/noctuid/tdrop
    # https://github.com/rkitover/vimpager
    # imagemin-cli
    # incron
    # pfff
    # telegramircd

    # heroku-cli
    # ramda-cli
    # ttystudio
    # vmd
    # x0
    # xml2json

    acpi
    aria
    asciinema ttyrec
    at
    atool dtrx
    avo-scripts
    bfs
    binutils
    byzanz
    dateutils
    et
    exiftool exiv2 mediainfo
    expect
    fdupes
    ffmpeg
    file
    flac
    gcolor2
    gifsicle
    gnumake
    google-cloud-sdk
    graphicsmagick imagemagick
    graphviz
    hy
    icdiff
    impressive
    inkscape
    inotify-tools watchman
    jre
    keybase
    lastpass-cli
    lbdb
    lf
    libnotify
    libreoffice-fresh
    lm_sensors
    maim slop
    moreutilsWithoutParallel
    mosh
    ngrok
    nixops
    nq
    ntfy
    openssl
    optipng
    pciutils usbutils
    pqiv
    psmisc
    pv
    pythonPackages.ipython
    pythonPackages.jupyter
    pythonPackages.scapy
    racket
    rlwrap
    rsync
    rxvt_unicode-with-plugins
    sox
    sshuttle
    surfraw
    tdesktop
    tesseract
    tmate
    tree
    tsocks
    units
    url-parser
    xfce.thunar
    xurls
  ] ++
  [
    cabal2nix
    nix-beautify
    nix-prefetch-scripts
    nix-repl
    nix-zsh-completions
    nodePackages.node2nix
    nox
    stack2nix
  ] ++
  (with xorg; [
    xbindkeys
    xcape
    xchainkeys
    xev
  ]) ++
  [
    # haskellPackages.vimus
    # https://github.com/hoyon/mpv-mpris
    # mpris-ctl
    clerk
    google-play-music-desktop-player
    mpc_cli
    mpdris2
    mpv
    nodePackages.peerflix
    pianobar
    playerctl
    vimpc
    you-get
    youtube-dl
  ] ++
  [
    pandoc
    pdftk
    poppler_utils
    (lowPrio texlive.combined.scheme-full)
  ] ++
  [
    abduco
    dvtm
    tmux
    reptyr
  ] ++
  [
    htop
    iftop
    iotop
    linuxPackages.perf
    nethogs
  ] ++
  [
    google-chrome-dev
    qutebrowser qutebrowser-scripts
    torbrowser
  ] ++
  [
    fatrace
    forkstat
    lsof
    ltrace
    strace
  ] ++
  [
    # gron
    # haskellPackages.haskell-awk
    # tsvutils
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
  ] ++
  [
    dnsutils
    geoipWithDatabase
    httpie
    httping
    netcat
    ngrep
    nmap
    socat
    stunnel # https://gist.github.com/jeremiahsnapp/6426298
    tcpdump
    tcpflow
    telnet
    traceroute
    whois
    wireshark
    wsta
  ];
}
