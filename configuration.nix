{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ./home-manager/nixos

    ./android.nix
    ./clojure.nix
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

    home = {
      sessionVariables = {
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

      file = {
        ".gist".text = (import ./credentials.nix).gist_token;
      };
    };

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

        "mimeapps.list".text = lib.generators.toINI {} {
           "Default Applications" = {
             "x-scheme-handler/http"                                                   = "qutebrowser.desktop";
             "x-scheme-handler/https"                                                  = "qutebrowser.desktop";
             "x-scheme-handler/ftp"                                                    = "qutebrowser.desktop";
             "text/html"                                                               = "qutebrowser.desktop";
             "application/xhtml+xml"                                                   = "qutebrowser.desktop";
             "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "libreoffice-writer.desktop";
             "application/pdf"                                                         = "zathura.desktop";
             "text/plain"                                                              = "emacs.desktop";
             "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"       = "calc.desktop";
             "application/xml"                                                         = "emacs.desktop";
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
    editorEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "scratchpad"; };
    todoEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "todo"; };
    mainEmacsDaemon = makeEmacsDaemon { inherit config pkgs; name = "main"; };
  };
} // {

  hardware.opengl.extraPackages = with pkgs; [ vaapiVdpau ];
  environment.variables.LIBVA_DRIVER_NAME = "vdpau";
} // {

  hardware.pulseaudio = { enable = true; package = pkgs.pulseaudioFull; };
  environment.systemPackages = with pkgs; [
    alsaPlugins
    alsaUtils
    pamixer
    ponymix
 ];
} // {
  environment.systemPackages = with pkgs;
    let
      neovim = pkgs.neovim.override { vimAlias = true; };
      moreutils = (pkgs.stdenv.lib.overrideDerivation pkgs.moreutils (attrs: rec { postInstall = pkgs.moreutils.postInstall + "; rm $out/bin/parallel"; })); # prefer GNU parallel
      zathura = pkgs.zathura.override { useMupdf = true; };
      parallel = (pkgs.stdenv.lib.overrideDerivation pkgs.parallel (attrs: rec {
                   nativeBuildInputs = attrs.nativeBuildInputs ++ [ pkgs.perlPackages.DBDSQLite ];
                 }));
    in [
      xorg.xmessage
      # fovea
      # incron
      # mpris-ctl
      # pfff

      # https:++github.com/noctuid/tdrop
      # https:++github.com/rkitover/vimpager
      # https:++github.com/harelba/q

      # polipo
      gnumake

      bashdb
      bindfs

      nodePackages.tern

      cloc

      fdupes

      pgcli
      sqlite

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

      rxvt_unicode-with-plugins
      urxvt_autocomplete_all_the_things
      termite

      emacs
      neovim

      (lowPrio moreutils)
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

      gnupg
      keybase
      lastpass-cli
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

      ntfs3g

      expect

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

      # https:++github.com/wee-slack/wee-slack
      # telegramircd

      tesseract

      units

      xurls
      surfraw
    ] ++
    [
      ffmpeg
      gifsicle
      graphicsmagick
      imagemagick
      inkscape
    ] ++
    [
      cabal2nix
      nix-prefetch-scripts
      nix-repl
      nix-zsh-completions
      nodePackages.node2nix
      patchelf
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

      avo-scripts
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
      stunnel # https:++gist.github.com/jeremiahsnapp/6426298
      tcpdump
      tcpflow
      telnet
      wireshark
    ] ++
    [
      fzf
      grc
      highlight
      multitail
      pythonPackages.pygments
      rlwrap
    ];
}
