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
    ./libvirt.nix
    ./mitmproxy.nix
    ./mopidy.nix
    ./neovim.nix
    ./netrc.nix
    ./networking.nix
    ./nixos.nix
    ./nvidia.nix
    ./pandora.nix
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


  hardware.opengl = { driSupport = true; driSupport32Bit = true; };


  services.xserver.enable = true;


  services.devmon.enable = true;


  users.users.avo = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;


  home-manager.users.avo
    .home.sessionVariables = with config.home-manager.users.avo; {
      BROWSER       = "${pkgs.qutebrowser}/bin/qutebrowser-open-in-instance";
      EDITOR        = "${pkgs.neovim}/bin/nvim";
      PATH          = lib.concatStringsSep ":" [
                        "$PATH"
                        "$HOME/bin"
                        "$HOME/.local/bin"
                      ];
      LESSHISTFILE  = "${xdg.cacheHome}/less/history";
      PARALLEL_HOME = "${xdg.cacheHome}/parallel";
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
      ghi
      gnumake
      graphviz
      hy racket
      impressive
      inotify-tools watchman
      jre
      lbdb
      lf tree fd
      libreoffice-fresh
      mosh
      ngrok
      nq
      openssl
      optipng
      parallel
      pqiv
      psmisc
      pv
      pythonPackages.ipython pythonPackages.jupyter
      pythonPackages.scapy
      qrencode
      rsync
      rxvt_unicode-with-plugins
      siege
      sox
      sshuttle
      steam
      surfraw
      tesseract
      tsocks
      unison
      units
      url-parser
      x11_ssh_askpass
      xfce.thunar
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
      tmate
      ttyrec
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
      httping
      iftop
      nethogs
    ] ++
    [
      htop
      iotop
      linuxPackages.perf
      sysstat
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
      dnsutils
      geoipWithDatabase
      nmap
      traceroute
      whois
    ] ++
    [
      byzanz
      ffcast xorg.xwininfo
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
      curl
      httpie
      netcat
      ngrep
      socat
      stunnel # https://gist.github.com/jeremiahsnapp/6426298
      tcpdump
      tcpflow
      telnet
      wireshark
      wsta
    ] ++
    [
      fzf
      grc
      highlight
      pythonPackages.pygments
      rlwrap
    ];
}
