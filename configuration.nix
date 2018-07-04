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

    ./programs/alacritty.nix
    ./programs/android.nix
    ./programs/aws-cli.nix
    ./programs/bitcoin.nix
    ./programs/clojure
    ./programs/curl.nix
    ./programs/docker
    ./programs/dropbox.nix
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
    # ./programs/mitmproxy.nix
    ./programs/mopidy.nix
    ./programs/mpv.nix
    ./programs/neovim.nix
    ./programs/nodejs.nix
    ./programs/pandora.nix
    ./programs/parallel.nix
    ./programs/pianobar.nix
    ./programs/qutebrowser.nix
    ./programs/readline.nix
    ./programs/ripgrep.nix
    ./programs/ssh.nix
    ./programs/sxiv.nix
    ./programs/t.nix
    ./programs/tmux.nix
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

  system.nixos.stateVersion = "18.09";

  services.wakeonlan.interfaces = [ { interface = "enp0s31f6"; method = "magicpacket"; } ];

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays =
    let path = ./overlays; in with builtins;
    map (n: import (path + ("/" + n)))
        (filter (n: match ".*\\.nix" n != null || pathExists (path + ("/" + n + "/default.nix")))
                (attrNames (readDir path)));

  home-manager.users.avo = {
    nixpkgs.config = config.nixpkgs.config;

    manual.manpages.enable = false;

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
    # ej
    # gron
    # oni
    # mkcast
    #stack2nix
    (lowPrio texlive.combined.scheme-full)
    abduco
    acpi
    aria
    at
    atool
    avo-scripts
    binutils
    csvtotable
    dateutils
    dnsutils
    docx2txt
    dtrx
    dvtm
    et
    exiftool exiv2 mediainfo
    expect
    fatrace
    fdupes
    ffmpeg
    file
    flac
    forkstat
    gcolor2
    gifsicle
    gnumake
    google-chrome-dev
    google-cloud-sdk
    google-play-music-desktop-player
    graphicsmagick imagemagick
    graphviz
    html2text
    htmlTidy
    htop
    httpie
    icdiff
    iftop
    impressive
    inkscape
    inotify-tools watchman
    iotop
    jo
    jq
    jre
    keybase
    lastpass-cli
    libnotify
    libreoffice
    libxls
    linuxPackages.perf
    lm_sensors
    lsof
    ltrace
    maim slop
    miller
    moreutilsWithoutParallel
    mosh
    netcat
    nethogs
    ngrep
    ngrok
    nix-beautify
    nix-prefetch-scripts
    nix-repl
    nix-zsh-completions
    nixops
    nmap
    nox
    nq
    ntfy
    openssl
    pandoc
    pciutils
    pdfgrep
    pdftk
    perlPackages.HTMLParser
    poppler_utils
    pqiv
    psmisc
    pup
    pv
    qutebrowser qutebrowser-scripts
    racket
    recode
    remarshal
    reptyr
    rlwrap
    rsync
    socat
    sound-theme-freedesktop
    sshuttle
    strace
    surfraw
    tcpdump
    tcpflow
    telnet
    tmate
    tmux
    torbrowser
    traceroute
    tree
    tsocks
    units
    unoconv
    urlp
    usbutils
    whois
    wireshark
    wsta
    x_x
    xfce.thunar
    xlsx2csv
    xml2
    xorg.xev
    xsv
    xurls
    youtube-dl
  ];
}
