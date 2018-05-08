{ config, lib, pkgs, ... }:

rec {
  imports = [
    ./hardware-configuration.nix

    ./home-manager/nixos

    ./android.nix
    ./audio.nix
    ./bitcoin.nix
    ./clojure
    ./default-apps.nix
    ./docker.nix
    ./dropbox.nix
    ./email
    ./floobits.nix
    ./gist.nix
    ./git.nix
    ./gnupg.nix
    ./google-drive-ocamlfuse.service.nix
    ./gui.nix
    ./haskell
    ./input.nix
    ./ipfs.nix
    ./irc.nix
    ./libvirt.nix
    ./mitmproxy.nix
    ./mopidy.nix
    ./neovim.nix
    ./netrc.nix
    ./networking.nix
    ./nvidia.nix
    ./printing.nix
    ./qutebrowser.service.nix
    ./readline.nix
    ./scripts.nix
    ./shell.nix
    ./tmux.nix
    ./xdg.nix
  ];


  boot.loader.timeout = 1;


  boot.kernelPackages = pkgs.linuxPackages_latest;


  boot.kernel.sysctl =
    { "fs.inotify.max_user_watches" = 100000; } //
    { "vm.swappiness" = 1;
      "vm.vfs_cache_pressure" = 50; };


  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "en_US.UTF-8";


  nix = {
    buildCores = 0;
    gc.automatic = true;
    optimise.automatic = true;
  };

  system.autoUpgrade = { enable = true; channel = "https://nixos.org/channels/nixos-unstable"; };


  hardware.bluetooth.enable = true;


  hardware.opengl = { driSupport = true; driSupport32Bit = true; };


  users.users.avo = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;


  services.xserver = {
    enable = true;

    displayManager.auto = { enable = true; user = "avo"; };
    desktopManager.xterm.enable = false;

    # displayManager.sddm.enable = true;
    # windowManager.sway.enable = true;
    # https://github.com/waymonad/waymonad
  };


  nixpkgs.overlays = import ./overlays.nix;

  nixpkgs.config.allowUnfree = true;
  home-manager.users.avo.nixpkgs.config = nixpkgs.config;


  services.devmon.enable = true;


  home-manager.users.avo
    .home.sessionVariables = with config.home-manager.users.avo; {
      BROWSER                     = "${pkgs.qutebrowser}/bin/qutebrowser-open-in-instance";
      EDITOR                      = "${pkgs.neovim}/bin/nvim";
      PATH                        = lib.concatStringsSep ":" [
                                      "$PATH"
                                      "$HOME/bin"
                                      "$HOME/.local/bin"
                                    ];
      LESSHISTFILE                = "${xdg.cacheHome}/less/history";
      PARALLEL_HOME               = "${xdg.cacheHome}/parallel";
      __GL_SHADER_DISK_CACHE_PATH = "${xdg.cacheHome}/nv";
    };


  systemd.user.services = let makeEmacsDaemon = import ./make-emacs-daemon.nix; in {
    editorEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "editor-scratchpad"; };
    todoEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "todo"; };
    mainEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "main"; };
  };


  home-manager.users.avo
    .programs = import ./programs.nix { inherit config lib; };

  environment.systemPackages =
    let
      # prefer GNU parallel
      moreutilsWithoutParallel = pkgs.stdenv.lib.overrideDerivation
                                   pkgs.moreutils
                                   (attrs: { postInstall = pkgs.moreutils.postInstall + "; rm $out/bin/parallel"; });
      nix-beautify = import ./packages/nix-beautify;
      parallel = pkgs.stdenv.lib.overrideDerivation
                   pkgs.parallel
                   (attrs: { nativeBuildInputs = attrs.nativeBuildInputs ++ [ pkgs.perlPackages.DBDSQLite ];});
      zathura = pkgs.zathura.override { useMupdf = true; };
      emacs = pkgs.stdenv.lib.overrideDerivation
                pkgs.emacs
                (attrs: { nativeBuildInputs = attrs.nativeBuildInputs ++ (with pkgs; [ aspell aspellDicts.en aspellDicts.fr
                                                                                       nodePackages.tern
                                                                                       w3m ]);});

    in with pkgs; [
      # fovea
      # https://github.com/harelba/q
      # https://github.com/noctuid/tdrop
      # https://github.com/rkitover/vimpager
      # imagemin-cli
      # incron
      # perl.rename
      # pfff
      # telegramircd

      # heroku-cli
      # ramda-cli
      # ttystudio
      # vmd
      # x0
      # xml2json

      aria wget
      avo-scripts
      bashdb
      bfs
      cloc
      colordiff icdiff wdiff
      dateutils moreutilsWithoutParallel
      emacs
      et at
      expect
      fdupes
      flac
      gcolor2
      gnumake
      graphviz
      hy racket
      inotify-tools watchman
      jre
      lbdb
      lf tree xfce.thunar fd
      libreoffice-fresh
      lsyncd
      mosh
      ngrok
      nq
      openssl
      optipng
      parallel
      psmisc
      pv
      pythonPackages.ipython pythonPackages.jupyter
      pythonPackages.scapy
      qrencode
      renameutils
      ripgrep
      rsync
      rxvt_unicode-with-plugins
      siege
      sox
      sshuttle
      steam
      surfraw
      sxiv pqiv
      taskwarrior
      tesseract
      tsocks
      unison
      units
      url-parser
      x11_ssh_askpass
      xfontsel
      xurls
    ] ++
    [
      ffmpeg
      gifsicle
      graphicsmagick
      imagemagick
      inkscape
    ] ++
    [
      keybase
      lastpass-cli
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
    [
      pgcli
      sqlite
    ] ++
    [
      mupdf
      poppler_utils
      impressive
    ] ++
    (with xorg; [
      evtest
      gnome3.zenity
      wmutils-core
      xbindkeys
      xcape
      xchainkeys
      xdg_utils
      xev
      xkbevd
    ]) ++
    [
      google-cloud-sdk
      nixops
    ] ++
    [
      t
      tdesktop
      pidgin
    ] ++
    [
      asciinema
      gist
      tmate
      ttyrec
    ] ++
    [
      # haskellPackages.vimus
      # https://github.com/hoyon/mpv-mpris
      google-play-music-desktop-player
      mpc_cli
      mpv
      nodePackages.peerflix
      pianobar
      playerctl
      vimpc
      you-get
    ] ++
    [
      enscript
      ghostscript
      pandoc
      pdftk
      (lowPrio texlive.combined.scheme-full)
    ] ++
    [
      acpi
      lm_sensors
      pciutils
      usbutils
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
      google-chrome-dev
      qutebrowser
      torbrowser
    ] ++
    [
      clerk
      lastfmsubmitd
      mpdas
      # mpris-ctl
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
      stunnel # https://gist.github.com/jeremiahsnapp/6426298
      tcpdump
      tcpflow
      telnet
      wireshark
    ] ++
    [
      fzf
      grc
      highlight
      pythonPackages.pygments
      rlwrap
    ];
}
