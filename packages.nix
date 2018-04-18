{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # (chromium.override {} enableWideVine = true; })
    #csvtotable
    #x_x
    (stdenv.lib.overrideDerivation moreutils (attrs: rec { postFixup = "rm $out/bin/parallel"; })) # prefer GNU parallel
    acpi lm_sensors pciutils usbutils
    alacritty
    alsaPlugins alsaUtils
    antiword docx2txt html2text libxls pdfgrep remarshal unoconv xlsx2csv
    aria wget
    asciinema gist tmate ttyrec
    aspell aspellDicts.en aspellDicts.fr
    awscli google-cloud-sdk
    bitcoin
    boot clojure leiningen lighttable lumo
    chromium firefox-devedition-bin torbrowser w3m
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
    fzf highlight
    gcolor2
    ghc haskellPackages.brittany haskellPackages.hindent haskellPackages.stylish-haskell stack
    git gitAndTools.hub
    gnome3.adwaita-icon-theme
    gnupg
    go
    google-drive-ocamlfuse
    graphicsmagick imagemagick
    graphviz
    htop iotop linuxPackages.perf psmisc
    httping iftop nethogs
    hy
    inkscape
    inotify-tools watchman
    jdk
    jq jo
    lastpass-cli
    lf tree xfce.thunar
    libinput-gestures
    libreoffice-fresh
    lsof strace
    mailutils msmtp notmuch
    miller pup xml2
    mitmproxy ngrep tcpdump wireshark
    mpv vaapiVdpau
    mupdf poppler_utils (zathura.override { useMupdf = true; })
    neovim
    netcat socat telnet
    nix-prefetch-scripts patchelf
    nix-zsh-completions
    nodejs-9_x yarn
    ntfs3g
    openssl
    perlPackages.HTMLParser recode
    pianobar youtube-dl
    pv parallel perlPackages.DBDSQLite expect wdiff
    pythonPackages.pygments
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
