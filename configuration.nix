{ config, lib, pkgs, ... }:

{
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
    ./grep.nix
    ./gui
    ./haskell
    ./input.nix
    ./ipfs.nix
    ./irc.nix
    ./less.nix
    ./libvirt.nix
    ./mitmproxy.nix
    ./mopidy.nix
    ./neovim.nix
    ./netrc.nix
    ./networking.nix
    ./nixos.nix
    ./nvidia.nix
    ./pandora.nix
    ./parallel.nix
    ./printing.nix
    ./qutebrowser.service.nix
    ./readline.nix
    ./ripgrep.nix
    ./scripts.nix
    ./shell.nix
    ./sxiv.nix
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


  hardware.bluetooth.enable = true;


  hardware.opengl.driSupport = true;


  services.xserver.enable = true;


  services.devmon.enable = true;


  users.users.avo = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;


  home-manager.users.avo
    .home.sessionVariables = with config.home-manager.users.avo; {
      BROWSER = "${pkgs.qutebrowser}/bin/qutebrowser-open-in-instance";
      EDITOR  = "${pkgs.neovim}/bin/nvim";
      PATH    = lib.concatStringsSep ":" [ "$PATH" "$HOME/.local/bin" ];
    };


  systemd.user.services = let makeEmacsDaemon = import ./make-emacs-daemon.nix; in {
    editorEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "editor-scratchpad"; };
    todoEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "todo"; };
    mainEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "main"; };
    mainEmacsClient =  {
      enable = true;
      serviceConfig = {
        Type      = "forking";
        Restart   = "always";
        ExecStart  = ''
                      ${pkgs.emacs}/bin/emacsclient \
                        --socket-name main
                    '';
        PIDFile      = "/run/main-emacs-client.pid";
        ExecStop     = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      };
    };
  };


  home-manager.users.avo
    .programs = import ./programs.nix { inherit config lib; };

  environment.systemPackages =
    let
      # prefer GNU parallel
      moreutilsWithoutParallel = pkgs.stdenv.lib.overrideDerivation
                                   pkgs.moreutils
                                   (attrs: { postInstall = attrs.postInstall + "; rm $out/bin/parallel"; });
      nix-beautify = import ./packages/nix-beautify;
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
      # pfff
      # telegramircd

      # heroku-cli
      # ramda-cli
      # ttystudio
      # vmd
      # x0
      # xml2json

      aria
      asciinema ttyrec
      at
      avo-scripts
      bashdb
      bfs
      cloc
      dateutils
      emacs
      et
      expect
      fdupes
      flac
      gcolor2
      ghi
      gnumake
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
      libreoffice-fresh
      moreutilsWithoutParallel
      mosh
      ngrok
      nq
      openssl
      optipng
      pgcli
      pqiv
      psmisc
      pv
      pythonPackages.ipython
      pythonPackages.jupyter
      pythonPackages.scapy
      qrencode
      racket
      rsync
      rxvt_unicode-with-plugins
      sox
      sqlite
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
      byzanz
      ffmpeg
      gifsicle
      maim
      slop
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
      evtest
      gnome3.zenity
      wmutils-core
      xbindkeys
      xcape
      xchainkeys
      xev
    ]) ++
    [
      google-cloud-sdk
      nixops
    ] ++
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
      enscript
      ghostscript
      pandoc
      pdftk
      poppler_utils
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
      fatrace
      forkstat
      lsof
      ltrace
      strace
    ] ++
    [
      libnotify
      ntfy
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
      atool
      dtrx
      unzip
      zip
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
    ] ++
    [
      grc
      highlight
      pythonPackages.pygments
      rlwrap
    ];
}
