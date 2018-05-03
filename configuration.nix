{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ./home-manager/nixos

    ./android.nix
    ./audio.nix
    ./clojure.nix
    ./default-apps.nix
    ./docker.nix
    ./email.nix
    ./git.nix
    ./google-drive-ocamlfuse-service.nix
    ./gui.nix
    ./haskell.nix
    ./input.nix
    ./ipfs.nix
    ./irc.nix
    ./libvirt.nix
    ./networking.nix
    ./printing.nix
    ./shell.nix
    ./tmux.nix
  ];

  boot.loader.timeout = 1;

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 100000;
    "kernel.core_pattern" = "|/run/current-system/sw/bin/false"; # disable core dumps
    "vm.swappiness" = 1;
    "vm.vfs_cache_pressure" = 50;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "en_US.UTF-8";

  system.autoUpgrade = { enable = true; channel = "https://nixos.org/channels/nixos-unstable"; };

  nix = {
    buildCores = 0;
    gc.automatic = true;
    optimise.automatic = true;
  };

  nixpkgs = {
    overlays = import ./overlays.nix;
    config.allowUnfree = true;
  };

  hardware = {
    bluetooth.enable = true;
    opengl = { driSupport = true; driSupport32Bit = true; };
  };


  services = {
    devmon.enable = true;

    mopidy = {
      enable = true;
      extensionPackages = with pkgs; [ mopidy-gmusic ];
      configuration = lib.generators.toINI {} {
        gmusic = {
          deviceid = "0123456789abcdef";
          username = "andreivolt";
          password = (import ./credentials.nix).andreivolt_google_password;
          bitrate = 320;
        };
      };
    };

    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];

      displayManager.auto = { enable = true; user = "avo"; };
      desktopManager.xterm.enable = false;
      # displayManager.sddm.enable = true;
      # windowManager.sway.enable = true;
    };
  };

  users.users.avo = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
  security.sudo.wheelNeedsPassword = false;

  home-manager.users.avo = rec {
    services.dropbox.enable = true;

    home.sessionVariables = {
      BROWSER                     = "${pkgs.qutebrowser}/bin/qutebrowser-open-in-instance";
      EDITOR                      = "${pkgs.neovim}/bin/nvim";
      PATH                        = lib.concatStringsSep ":" [
                                      "$PATH"
                                      "$HOME/bin"
                                      "${xdg.cacheHome}/npm/packages/bin"
                                    ];
      GNUPGHOME                   = "${xdg.configHome}/gnupg";
      LESSHISTFILE                = "${xdg.cacheHome}/less/history";
      PARALLEL_HOME               = "${xdg.cacheHome}/parallel";
      __GL_SHADER_DISK_CACHE_PATH = "${xdg.cacheHome}/nv";
    };

    home.file.".gist".text = (import ./credentials.nix).gist_token;

    xdg = {
      enable = true;

      configHome = "${config.users.users.avo.home}/.config";
      dataHome   = "${config.users.users.avo.home}/.local/share";
      cacheHome  = "${config.users.users.avo.home}/.cache";

      configFile = {
        "bitcoin/bitcoin.conf".text = lib.generators.toKeyValue {} {
          prune = 550;
        };

        "mitmproxy/config.yaml".text = lib.generators.toYAML {} {
           CA_DIR = "${xdg.configHome}/mitmproxy/certs";
        };

        "youtube-dl.conf".text = ''
           --output %(title)s.%(ext)s
        '';

        "user-dirs.dirs".text = lib.generators.toKeyValue {} {
          XDG_DOWNLOAD_DIR = "$HOME/tmp";
          XDG_DESKTOP_DIR  = "$HOME/tmp";
        };

        "gtk-3.0/settings.ini".text = lib.generators.toINI {} {
          "Settings" = {
            gtk-recent-files-limit = 0;
          };
        };

      };
    };

    nixpkgs.config = {
      allowUnfree = true;
    };

    programs = (import ./programs.nix { inherit config lib; });
  };

  systemd.user.services = let makeEmacsDaemon = import ./make-emacs-daemon.nix; in {
    editorEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "editor-scratchpad"; };
    todoEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "todo"; };
    mainEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "main"; };
    browser = {
      enable = true;
      wantedBy = [ "graphical.target" ];
      serviceConfig = {
        Type      = "forking";
        Restart   = "always";
        ExecStart = "${pkgs.qutebrowser}/bin/qutebrowser";
        ExecStop  = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        GuessMainPID = true;
      };
      environment.QT_PLUGIN_PATH = "/home/avo/.nix-profile/lib/qt4/plugins:/home/avo/.nix-profile/lib/kde4/plugins:/nix/var/nix/profiles/default/lib/qt4/plugins:/nix/var/nix/profiles/default/lib/kde4/plugins:/run/current-system/sw/lib/qt4/plugins:/run/current-system/sw/lib/kde4/plugins:/etc/profiles/per-user/avo/lib/qt4/plugins:/etc/profiles/per-user/avo/lib/kde4/plugins";
    };
  };

  hardware.opengl.extraPackages = with pkgs; [ vaapiVdpau ];
  environment.variables.LIBVA_DRIVER_NAME = "vdpau";

  environment.systemPackages = with pkgs;
    let
      moreutils = (pkgs.stdenv.lib.overrideDerivation pkgs.moreutils (attrs: rec { postInstall = pkgs.moreutils.postInstall + "; rm $out/bin/parallel"; })); # prefer GNU parallel
      neovim = pkgs.neovim.override { vimAlias = true; };
      nix-beautify = import ./packages/nix-beautify;
      parallel = (pkgs.stdenv.lib.overrideDerivation pkgs.parallel (attrs: rec { nativeBuildInputs = attrs.nativeBuildInputs ++ [ pkgs.perlPackages.DBDSQLite ];}));
      zathura = pkgs.zathura.override { useMupdf = true; };
    in [
      xorg.xmessage
      # fovea
      # incron
      # mpris-ctl
      # pfff

      # https://github.com/noctuid/tdrop
      # https://github.com/rkitover/vimpager
      # https://github.com/harelba/q

      # polipo
      gnumake

      bashdb
      bindfs

      nodePackages.tern

      cloc

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

      moreutils
      renameutils
      # perl.rename

      shadowsocks-libev

      siege

      taskwarrior

      unison

      x11_ssh_askpass

      xfontsel

      aria
      wget

      aspell
      aspellDicts.en
      aspellDicts.fr

      bitcoin

      colordiff
      icdiff
      wdiff

      dateutils

      gcolor2

      openssl

      graphviz

      psmisc
      hy

      inotify-tools
      watchman

      jre

      lf
      tree
      xfce.thunar

      libreoffice-fresh

      expect

      url-parser

      lr
      parallel
      pv
      xe
      nq
      fd
      bfs

      et
      at

      ripgrep

      rsync

      sshuttle
      tsocks

      steam

      sxiv
      # pqiv

      # https://github.com/wee-slack/wee-slack
      # telegramircd

      tesseract

      units

      xurls
      surfraw

      avo-scripts
    ] ++
    [
      ffmpeg
      gifsicle
      graphicsmagick
      imagemagick
      inkscape
    ] ++
    [
      gnupg
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
      # https:++github.com/waymonad/waymonad
    ]) ++
    [
      emacs
      neovim
    ] ++
    [
      rxvt_unicode-with-plugins
      urxvt_autocomplete_all_the_things
    ] ++
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
