{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    #gron
    (neovim.override { vimAlias = true; })
    (stdenv.lib.overrideDerivation moreutils (attrs: rec { postInstall = moreutils.postInstall + "; rm $out/bin/parallel"; })) # prefer GNU parallel
    acpi lm_sensors pciutils usbutils
    alacritty
    alsaPlugins alsaUtils
    antiword csvtotable docx2txt html2text libxls pdfgrep remarshal unoconv x_x xlsx2csv
    aria wget
    asciinema gist tmate ttyrec
    aspell aspellDicts.en aspellDicts.fr
    awscli google-cloud-sdk
    bitcoin
    boot clojure leiningen lighttable lumo
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
    firefox-devedition-bin google-chrome-dev torbrowser w3m
    fzf highlight pythonPackages.pygments
    gcolor2
    ghc haskellPackages.brittany haskellPackages.hindent haskellPackages.stylish-haskell stack
    git gitAndTools.hub
    gnome3.adwaita-icon-theme
    gnupg lastpass-cli
    google-drive-ocamlfuse
    google-play-music-desktop-player mpc_cli nodePackages.peerflix pianobar youtube-dl
    graphicsmagick imagemagick
    graphviz
    htop iotop linuxPackages.perf psmisc
    httping iftop nethogs
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
    miller pup xml2
    mitmproxy ngrep tcpdump wireshark
    mpv vaapiVdpau
    mupdf poppler_utils (zathura.override { useMupdf = true; })
    netcat socat telnet
    nix-prefetch-scripts patchelf
    nix-zsh-completions
    nodejs-9_x
    ntfs3g
    openssl
    perlPackages.HTMLParser recode
    pv parallel perlPackages.DBDSQLite expect wdiff
    redshift
    ripgrep
    rlwrap
    rofi
    rsync
    setroot seturgent xorg.xset
    sqlite
    sshuttle tsocks
    steam
    sxiv
    t tdesktop
    tesseract
    tmux
    units
    unzip zip
    virt-viewer
    wirelesstools wpa_supplicant
    wmctrl xdotool
    xclip xsel
    xdg_utils
    xorg.xev xorg.xinput
    xorg.xrandr xrandr-invert-colors
    xurls
  ];
}
