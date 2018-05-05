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
    ./neovim.nix
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

  fileSystems."xmonad-config" = {
    device = "/etc/nixos/xmonad-config";
    fsType = "none"; options = [ "bind" ];
    mountPoint = "/home/avo/.config/xmonad";
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
                                      "$HOME/.local/bin"
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

        "user-dirs.dirs".text = lib.generators.toKeyValue {} {
          XDG_DOWNLOAD_DIR = "$HOME/tmp";
          XDG_DESKTOP_DIR  = "$HOME/tmp";
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
        Type         = "forking";
        Restart      = "always";
        ExecStart    = ''
                         ${pkgs.bash}/bin/bash -c '\
                           source ${config.system.build.setEnvironment};\
                           source ~/.nix-profile/etc/profile.d/hm-session-vars.sh;\
                           exec ${pkgs.qutebrowser}/bin/qutebrowser;\
                         '
                       '';
        PIDFile      = "/run/qutebrowser.pid";
        ExecStop     = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
      };
    };
  };

  hardware.opengl.extraPackages = with pkgs; [ vaapiVdpau ];
  environment.variables.LIBVA_DRIVER_NAME = "vdpau";

  environment.systemPackages = with pkgs;
    let
      moreutils = (pkgs.stdenv.lib.overrideDerivation pkgs.moreutils (attrs: rec { postInstall = pkgs.moreutils.postInstall + "; rm $out/bin/parallel"; })); # prefer GNU parallel
      nix-beautify = import ./packages/nix-beautify;
      parallel = (pkgs.stdenv.lib.overrideDerivation pkgs.parallel (attrs: rec { nativeBuildInputs = attrs.nativeBuildInputs ++ [ pkgs.perlPackages.DBDSQLite ];}));
      zathura = pkgs.zathura.override { useMupdf = true; };
      emacs = (pkgs.stdenv.lib.overrideDerivation pkgs.emacs (attrs: rec {
                                                                buildInputs = attrs.buildInputs ++
                                                                            [ aspell aspellDicts.en aspellDicts.fr
                                                                              w3m
                                                                            ]; }));

    in [
      xorg.xmessage
      # fovea
      # incron
      # mpris-ctl
      # pfff

      # https://github.com/noctuid/tdrop
      # https://github.com/rkitover/vimpager
      # https://github.com/harelba/q

      bashdb
      bindfs

      nodePackages.tern

      cloc

      rxvt_unicode-with-plugins

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

      siege

      taskwarrior

      unison

      x11_ssh_askpass

      xfontsel

      aria
      wget

      bitcoin

      moreutils
      renameutils
      # perl.rename
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
      gnumake

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

      emacs

      rsync

      sshuttle
      tsocks

      steam

      sxiv
      pqiv

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
      # https:++github.com/waymonad/waymonad
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
