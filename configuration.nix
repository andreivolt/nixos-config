{ lib, pkgs, ... }:

rec {
  imports = let
    home-manager-module =
      let
        rev = "604561ba9ac45ee30385670b18f15731c541287b"; # latest
        sha256 = "01mj8kqk8gv5v64dmbhx5mk0sz22cs2i0jybnlicv7318xzndzxk";
      in import "${fetchTarball {
        inherit sha256;
        url = "https://github.com/nix-community/home-manager/archive/${rev}.tar.gz";}
      }/nixos";
  in [
    ./hardware-configuration.nix

    home-manager-module
    ./cachix.nix

    # ./modules/weechat-matrix.nix
    ./modules/wayland/overlay.nix
    ./modules/tmux.nix
    ./modules/adb.nix
    ./modules/clojure
    ./modules/alacritty/alacritty.nix
    ./modules/clojure/boot
    ./modules/aria2.nix
    ./modules/cloudflare-dns.nix
    ./modules/clojure/rebel-readline.nix
    ./modules/command-not-found.nix
    ./modules/curl.nix
    ./modules/gtk.nix
    ./modules/weechat.nix
    ./modules/docker.nix
    ./modules/libvirt.nix
    ./modules/firefox-wayland.nix
    ./modules/fonts.nix
    ./modules/fzf.nix
    ./modules/git.nix
    ./modules/gnome-keyring.nix
    ./modules/scanning.nix
    ./modules/grep.nix
    ./modules/hardware-video-acceleration.nix
    ./modules/git-hub.nix
    ./modules/hardware-video-acceleration/mpv.nix
    ./modules/hidpi/console.nix
    ./modules/hidpi/gnome.nix # TODO: dconf needed?
    ./modules/hosts-blocking.nix
    ./modules/insync.nix
    ./modules/ipfs.nix
    ./modules/kdeconnect.nix
    ./modules/less.nix
    ./modules/moreutils-without-parallel/overlay.nix
    ./modules/locate.nix
    ./modules/lowbatt.nix
    ./modules/map-test-tld-to-localhost.nix
    ./modules/matrix-cli.nix
    ./modules/mpv.nix
    ./modules/pipewire.nix
    ./modules/readline/inputrc.nix
    ./modules/keybase.nix
    ./modules/ripgrep.nix
    ./modules/gnupg.nix
    ./modules/spotify.nix
    ./modules/sway/sway.nix
    ./modules/tor.nix
    ./modules/zsh/fzf.nix
    ./modules/zsh/vi.nix
  ];

  hardware.bluetooth.enable = true;
  hardware.opengl.enable = true;

  networking.enableIPv6 = false;
  networking.hostName = builtins.getEnv "HOSTNAME";
  networking.networkmanager.enable = true;

  services.upower.enable = true;

  services.sshd.enable = true;

  virtualisation.virtualbox.host.enable = true;

  services.avahi.enable = true;
  services.avahi.nssmdns = true;

  # services.udisks2.enable = true;

  # environment.systemPackages = [ pkgs.xdg_utils ];
  # # printing
  # users.users.avo.extraGroups = [ "lp" ];

  documentation.man.generateCaches = true;

  environment.etc."mailcap".text = "*/*; xdg-open '%s'";

  programs.xwayland.enable = true;

  security.sudo.wheelNeedsPassword = false;

  services.devmon.enable = true; # automount removable devices

  system.stateVersion = "19.09";

  nix = {
    gc.automatic = true;
    optimise.automatic = true;
    nixPath = [
      "/home/avo/gdrive/nixos-config"
      "nixpkgs=/home/avo/gdrive/nixpkgs"
      "nixos-config=/home/avo/nixos-config/configuration.nix"
    ];
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = let
    nixpkgsUnstable = self: super: {
      nixpkgsUnstable =
        let nixpkgs-unstable-src = fetchTarball https://nixos.org/channels/nixpkgs-unstable/nixexprs.tar.xz;
        in import nixpkgs-unstable-src { config = nixpkgs.config; };
    };
  in [
    nixpkgsUnstable
    (import ./packages)
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "Europe/Paris";

  console.keyMap = "fr";

  users.users.avo = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
  };

  home-manager.users.avo = { pkgs, ... }: let
    vim = pkgs.callPackage ./modules/vim { };
  in rec {
    home.packages = with pkgs; [
      # (pkgs.youtube-viewer.overrideAttrs (oldAttrs: rec { src = /home/avo/gdrive/youtube-viewer; }))
      # anbox # android
      # avo.wsta # websocket cli
      # cargo2nix # rust
      # chromiumDev
      # csvtotable
      # docx2txt
      # espeak-classic # tts
      # firefox # TODO: xdg desktop associations
      # ghi
      # gitAndTools.diff-so-fancy
      # hachoir-subfile
      # haskellPackages.github-backup # BROKEN
      # home-manager
      # imagemin-cli
      # impressive # PDF presentations
      # ipfs-deploy
      # jdk11 # collision
      # jwhois
      # kefctl
      # libxls # xls2csv
      # mach # python nix # nix-env -if https://github.com/DavHau/mach-nix/tarball/3.3.0 -A mach-nix
      # mailutils # home-manager comsatd conflict
      # mpc
      # mpc_cli
      # mpdas
      # mpdris2
      # mpdscribble # MPD scrobbler
      # perlPackages.DBDSQLite # for GNU parallel
      # perlPackages.HTMLParser
      # pfff # source code tool
      # pip2nix # nix-env -f pip2nix/release.nix -iA pip2nix.python39
      # puppeteer-cli # compiles chrome
      # pythonPackages.ipython
      # pythonPackages.jupyter
      # pythonPackages.piep # Python stream editing
      # pythonPackages.scapy
      # record-query
      # renameutils # imv collision
      # speechd
      # texlive.combined.scheme-full # ghostscript collision
      # traceroute
      # ungoogled-chromium # or chromium # TODO: xdg desktop associations
      # vgo2nix # go
      # wl-recorder # wayland screen recording
      # x_x # Excel + CSV cli viewer
      (aspellWithDicts (dicts: with dicts; [ en en-computers fr ])) # TODO
      (hunspellWithDicts (with hunspellDicts; [ en-us fr-moderne ])) # TODO
      (zathura.override { useMupdf = true; })
      abduco
      acpi
      adb-sync
      alsaPlugins
      alsaUtils
      android-file-transfer # androd mtp
      antiword
      apktool
      (lowPrio mandoc)
      archivemount
      aria
      asciinema
      at
      atool # archive
      avo.pushover
      avo.zprint # clojure pretty-printer
      awscli
      babashka
      bashdb # bash debugger
      bat
      bc
      bemenu
      bfs # breadth-first find
      bindfs
      binutils
      bitcoin
      bluetooth_battery
      bluez
      bluez-tools
      boot
      breeze-gtk # gtk qt
      breeze-qt5 # gtk qt
      broot # tree file navigator
      cabal2nix
      cachix
      catdoc # Word/Excel/PowerPoint to text
      choose # cut/ awk alternative
      chromedriver
      cifs-utils
      clipman
      cloc # count lines of code
      clojure-lsp
      colordiff
      copyq # clipboard manager
      cups
      curl
      curlie
      dateutils
      delta
      desktop_file_utils
      discord
      dmenu-wayland
      dnscontrol
      dnsutils
      docker-compose
      docker-machine
      dogdns
      dos2unix
      dragon-drop # file drag-and-drop source/sink
      podman # containers
      dropbox-cli # filesharing, backup
      dstat # resource statistics
      dtach # terminal, detach
      dtrx # unarchiver
      dupd # file-management, duplicates
      dvtm # terminal-multiplexer
      ed # text-editor
      efibootmgr # system
      efivar # system
      elixir # proglang
      enscript # convert to PostScript
      entr # file-watcher
      envchain # security
      envsubst
      eternal-terminal # ssh
      ethtool
      evince # fill PDF forms
      exa # ls alternative
      exiftool
      exiv2 # image metadata
      expect
      fastlane # automate mobile app releases
      fatrace # file access events
      fd
      fdupes # find duplicates
      ffmpeg-full # -full for ffplay
      file
      flac
      flac123
      flashfocus # Wayland window animations
      flyctl # fly.io
      foot # Wayland terminal
      forkstat
      fpp # path picker
      freerdp # RDP client
      fswatch
      fswebcam # webcam photo
      fuse
      fx # JSON processing tool
      fzf # fuzzy finder
      fzy # fuzzy finder
      gcc
      gcolor2 # color chooser
      geckodriver # Firefox automation
      genymotion # android
      geoipWithDatabase
      ghc # Haskell
      ghostscript
      gifsicle
      gist # github
      crudini # manipulate ini files
      git-hub # github
      git-imerge # Git incremental merge
      gitAndTools.tig
      gitFull # for gitk
      glava # audio spectrum visualizer
      glib.bin
      glpaper
      gnirehtet # android reverse tethering
      gnome-breeze # gtk
      gnumake
      gnupg
      go # proglang
      goldendict # dictionnary
      google-chrome # browser
      google-cloud-sdk # cloud
      google-drive-ocamlfuse # filesharing, backup, filesystem
      googler # google search cli
      gphotos-sync # photos
      graphicsmagick # image, tools
      graphviz
      grc # syntax highlighter
      gron # flatten JSON
      hachoir
      haskellPackages.apply-refact
      haskellPackages.hlint
      haskellPackages.hnix
      haskellPackages.ShellCheck
      haskellPackages.stylish-haskell
      haskellPackages.xml-to-json
      heroku
      # highlight # cli syntax highlighter
      himalaya # email client
      hr # horizontal rule
      html2text
      htmlTidy # html
      httpie # http client
      httping # http benchmark
      hub # github
      hugs # haskell
      hy # python lisp
      hydroxide # protonmail
      hyperfine # benchmarking
      icdiff # side-by-side highlighted diffs
      iftop # network
      imgur-screenshot # file-sharing
      imgurbash2 # file-sharing
      imv # image viewer
      inkscape
      inotify-tools # file watcher
      inxi
      iotop # network
      ipfs
      iptraf-ng # network
      iw # wifi
      iwd # wifi
      jo # create JSON
      jq
      jre # for Android
      jtc # json
      keybase
      keybase-gui
      kotatogram-desktop # Telegram
      lastfmsubmitd
      lastpass-cli
      leiningen # clojure
      lf # file navigator
      lftp
      libarchive # bsdtar
      libguestfs # for mounting qcow2 images
      libnotify
      libreoffice-fresh
      libsForQt5.qtstyleplugin-kvantum # qt theme engine
      libxml2 # xmllint
      lighttable # Clojure IDE
      linuxPackages.perf
      lm_sensors
      lnav # logfile navigator
      lsd # ls alternative
      lshw
      lsof
      lsyncd # sync files with remote
      ltrace
      lumo # standalone ClojureScript environment
      lxqt.pavucontrol-qt
      lynx # terminal browser
      mailutils
      mate.caja # file manager
      matrix-commander # matrix cli
      # (hiPrio mandoc)
      maven
      mediainfo
      megatools
      miller # field processing for CSV
      mimeo # mime opener
      mimic # tts
      mitmproxy
      moreutilsWithoutParallel # moreutils parallel conflicts with GNU parallel
      mosh
      mpvc # mpv remote
      msmtp
      mtr # network diagnostics
      multitail
      ncdu
      neochat # matrix client
      neomutt
      neovide
      net-snmp # network
      netcat
      nethogs
      netlify-cli
      ngrep
      ngrok
      nix-index
      nix-prefetch-github
      nix-prefetch-scripts
      nix-update
      nixfmt
      nixops
      nixpkgsUnstable.arcan.espeak # tts
      nixpkgsUnstable.clojure
      nixpkgsUnstable.gh # github
      # nixpkgsUnstable.google-chrome-dev
      nixpkgsUnstable.youtube-viewer
      nmap
      nnn # file browser
      nodejs
      nodePackages.create-react-native-app
      nodePackages.expo-cli
      nodePackages.firebase-tools
      nodePackages.node2nix
      nodePackages.nodemon
      nodePackages.peerflix
      nodePackages.pnpm # nodejs package manager
      nodePackages.webtorrent-cli
      notmuch # email indexer
      nox # search Nix packages
      nq # queue
      ntfy # send notifications, on demand and when commands finish
      csvkit # csv
      grab-site # web-archive
      htop # system
      linode-cli # cloud
      photon # web-archive
      pscircle # system
      websocat # network
      xwayland # xorg wayland
      yq # json jq yaml
      nvimpager
      obex_data_server # bluetooth D-Bus
      obexd
      obexfs # bluetooth filesystem
      openssl
      optipng
      page
      pamixer
      pandoc
      parallel
      pass
      patchelf
      pavucontrol
      pciutils
      pdfgrep
      pdftk
      perl
      perl532Packages.FileMimeInfo
      perl532Packages.XMLTwig # xml_grep
      perl532Packages.XMLXPath # xpath tool
      pianobar
      pidgin
      play-with-mpv # open browser videos with mpv
      playerctl # mpris cli
      ponymix
      poppler_utils # pdf2text
      pqiv # image viewer
      procmail
      procs # ps alternative
      projectm # music visualizer
      protonmail-bridge # protonmail
      protonvpn-cli
      psmisc
      pup
      pv # pipe viewer
      pwgen
      python3
      python39Packages.internetarchive
      python3Packages.pip
      python3Packages.pipx # install & run Python packages in isolated environments
      pythonPackages.pygments
      qemu
      qt5ct # qt config
      qutebrowser
      racket
      ranger
      rclone # backups
      rdrview # content extractor
      recode
      recutils
      remarshal # CBOR/JSON/MessagePack/TOML/YAML converter
      remmina # RDP client
      rename
      reptyr # reparent process to new terminal
      ripgrep
      ripmime # email attachments
      rlwrap
      rmlint # find duplicates
      rsync
      ruby
      s3cmd
      screen
      sd # find & replace
      sdcv # dictionnary
      shadowsocks-libev # SOCKS5 proxy
      siege # http benchmarking
      skype
      slack
      slop # query a selection and print to stdout
      socat
      sox
      speech-tools # tts
      speedtest_cli
      sqlite
      sshfsFuse
      sshuttle # ssh VPN
      stack
      steam
      strace
      stress-ng # benchmarking
      sublime3
      surf
      surfraw
      sysbench # benchmarking
      t
      tcpdump # network
      tcpflow # network
      tdesktop # Telegram
      telnet # network
      terraform # ops
      tesseract4 # ocr
      tmate # tmux remote sharing
      tmpmail # disposable email
      tmux # terminal multiplexer
      torbrowser
      tree
      tsocks
      ttyrec
      unionfs-fuse
      unison # file sync
      units
      unoconv
      unrar
      unzip
      urlscan
      urlview
      urlwatch
      usbutils
      vgrep # grep pager
      vifm
      vim
      virt-viewer
      virtualbox
      vlc
      w3m
      watchman # file watcher
      wayback_machine_downloader
      wayvnc # remote desktop
      wdiff # word diff
      wf-recorder # wayland screen recording
      wget
      wgetpaste
      wine
      wirelesstools
      wireshark
      with-shell # cd inside commands
      wol # wake-on-lan
      wpa_supplicant
      wtype # GUI automation
      xdg_utils
      xh # HTTP client
      xidel
      xlsx2csv
      xml2
      xmlformat
      rman
      xmlindent
      xmlstarlet
      xmlto # xml converter
      xsel
      xurls
      xxd
      yarn
      yarn2nix
      ydotool
      you-get
      youtube-dl
      ytfzf # YouTube search
      zip
      zoxide # cd alternative
    ];

    home.sessionVariables = {
      EDITOR = "${vim}/bin/vim";
      PAGER = "${pkgs.nvimpager}/bin/nvimpager";
      BROWSER = "${pkgs.google-chrome}/bin/google-chrome-stable";
    };

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
    };

    home.sessionPath = [
      "$HOME/gdrive/bin"
      (builtins.toString ./bin)
    ];

    xdg.enable = true;

    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = {
      "application/pdf" = "zathura.desktop";
      "image/jpeg" = "imv.desktop";
      "image/png" = "imv.desktop";
      "text/html" = "google-chrome-stable.desktop";
      "text/plain" = "neovide.desktop";
      "video/mp4" = "mpv.desktop";
      "x-scheme-handler/http" = "google-chrome-stable.desktop";
      "x-scheme-handler/https" = "google-chrome-stable.desktop";
      "x-scheme-handler/tg" = "telegramdesktop.desktop";
    };

    programs.zsh = {
      enable = true;

      enableCompletion = true;

      enableSyntaxHighlighting = true;

      defaultKeymap = "viins";

      # enableInteractiveComments = true;

      history = rec {
        size = 99999;
        save = size;
        share = true;
        ignoreSpace = true;
        ignoreDups = true;
        extended = true;
        path = ".cache/zsh_history";
      };

      shellGlobalAliases = {
        H = "| head";
        T = "| tail";
        C = "| wc -l";
        G = "| grep";
        L = "| ${home.sessionVariables.PAGER}";
        NE = "2>/dev/null";
        NUL = "&>/dev/null";
      };

      shellAliases = {
        ls = "ls --human-readable --classify";
        l = "ls -1";
        la = "ls -a";
        ll = "ls -l";
        grep = "grep --color";
        vi = "vim";
      };

      plugins = with pkgs; [
        { name = "zsh-nix-shell"; file = "nix-shell.plugin.zsh"; src = zsh-nix-shell; }
        { name = "fast-syntax-highlighting"; file = "fast-syntax-highlighting.plugin.zsh"; src = zsh-fast-syntax-highlighting; }
        # {
        #   name = "zsh-nix-shell";
        #   file = "nix-shell.plugin.zsh";
        #   src = fetchFromGitHub {
        #     owner = "chisui";
        #     repo = "zsh-nix-shell";
        #     rev = "v0.2.0";
        #     sha256 = "1gfyrgn23zpwv1vj37gf28hf5z0ka0w5qm6286a7qixwv7ijnrx9";
        #   };
        # }
        # {
        #   name = "fast-syntax-highlighting";
        #   file = "fast-syntax-highlighting.plugin.zsh";
        #   src = fetchFromGitHub {
        #     owner = "zdharma";
        #     repo = "fast-syntax-highlighting";
        #     rev = "5ed7c0fa0be5e456a131a2378af10b5c03131a7e";
        #     sha256 = "0g3vzaixwjl9rjxc8waq1458kqjg8hsgsaz3ln6a1jm8cd7qca50";
        #   };
        # }
        {
          name = "autopair";
          file = "autopair.zsh";
          src = fetchFromGitHub {
            owner = "hlissner";
            repo = "zsh-autopair";
            rev = "8c1b2b85ba40b9afecc87990c884fe5cf9ac56d1";
            sha256 = "0aa87r82w431445n4n6brfyzh3bnrcf5s3lhih1493yc5mzjnjh3";
          };
        }
      ];
      initExtra = ''
        # trigger completion on globbing
        setopt glob_complete
        # remove extraneous spaces from saved commands
        setopt hist_reduce_blanks
        # show menu when completing
        zstyle ':completion:*' menu select
        # automatically update PATH
        zstyle ':completion:*' rehash true

        source ${./modules/zsh/prompt.zsh}
        source ${./modules/zsh/terminal-title.zsh}

        acd() {
          local tmp=$(mktemp -d)
          archivemount "$*" $tmp
          cd $tmp
        }

        ancestors() {
          pstree -p --show-parents --arguments $$ --unicode \
          | highlight yellow '(?<=,)[0-9]*'
        }

        highlight() {
          rg \
            --passthru \
            --colors "match:fg:$1" --color always \
            --pcre2 "$2"
        }

        bcat() {
          local f=$(mktemp).html
          cat /dev/stdin > $f
          $BROWSER $f
        }

        # overwrite previous line
        overwrite() {
          echo -e "\r\033[1A\033[0K$@"
        }

        html-man() {
          local x=$(mktemp).html
          man $@ \
          | rman -f html > $x \
          && BROWSER $x
        }
      '';
    };
  };

  services.lowbatt = {
    enable = true;
    notifyCapacity = 40;
    suspendCapacity = 10;
  };


  security.chromiumSuidSandbox.enable = true;
  programs.chromium = {
    # homepageLocation = "https://www.google.com";
    # defaultSearchProviderSuggestURL = "https://encrypted.google.com/complete/search?output=chrome&q={searchTerms}";
    # defaultSearchProviderSearchURL = "https://encrypted.google.com/search?q={searchTerms}&{google:RLZ}{google:originalQueryForSuggestion}{google:assistedQueryStats}{google:searchFieldtrialParameter}{google:searchClient}{google:sourceId}{google:instantExtendedEnabledParameter}ie={inputEncoding}";
    enable = true;
    extensions = [
      "adelhekhakakocomdfejiipdnaadiiib" # Text Mode
      "bkegjcmidjgnmjbeninfbhoaelblpgic" # Plain Text Linker
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
      "dhdgffkkebhmkfjojejmpbldmpobfkfo" # Tampermonkey
      "dneaehbmnbhcippjikoajpoabadpodje" # Old Reddit Redirect
      "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
      "fpnmgdkabkmnadcjpehmlllkndpkmiak" # Wayback Machine
      "gneobebnilffgkejpfhlgkmpkipgbcno" # Death To _blank
      "hahklcmnfgffdlchjigehabfbiigleji" # Play with MPV
      "hdokiejnpimakedhajhdlcegeplioahd" # LastPass: Free Password Manager
      "hkgfoiooedgoejojocmhlaklaeopbecg" # Picture-in-Picture Extension (by Google)
      "igiofjhpmpihnifddepnpngfjhkfenbp" # AutoPagerize
      "jchobbjgibcahbheicfocecmhocglkco" # Neat URL
      "jeogkiiogjbmhklcnbgkdcjoioegiknm" # Slack
      "mgijmajocgfcbeboacabfgobmjgjcoja" # Google Dictionary (by Google)
      "mmcgnaachjapbbchcpjihhgjhpfcnoan" # Open New Tab After Current Tab
      "ncppfjladdkdaemaghochfikpmghbcpc" # Open-as-Popup
      "nffaoalbilbmmfgbnbgppjihopabppdk" # Video Speed Controller
      "nlnkcinjjeoojlhdiedbbolilahmnldj" # Tab Sorter
      "pgdnlhfefecpicbbihgmbmffkjpaplco" # uBlock Origin Extra
      "pkedcjkdefgpdelpbcmbmeomcjbeemfm" # Chrome Media Router
      "padekgcemlokbadohgkifijomclgjgif" # Proxy SwitchyOmega
      "jlkpnekpomdbobkdokohimfcbgcpldfp" # QuickBlock
      "lpcaedmchfhocbbapmcbpinfpgnhiddi" # Google Keep Chrome Extension
      "fihnjjcciajhdojfnbdddfaoknhalnja" # I don't care about cookies
      "iipjdmnoigaobkamfhnojmglcdbnfaaf" # Clutter Free - Prevent duplicate tabs
      "gkmndgjgpolmikgnipipfekglbbgjcel" # AutoHideDownloadsBar
      # "hfjbmagddngcpeloejdejnfgbamkjaeg" # Vimium C - All by Keyboard
    ];
    extraOpts = {
      # "BrowserSignin" = 0;
      "WelcomePageOnOSUpgradeEnabled" = false;
      # "SyncDisabled" = true;
      # "PasswordManagerEnabled" = false;
      "SpellcheckEnabled" = true;
      "SpellcheckLanguage" = [
        "fr-FR"
        "en-US"
        "ro"
      ];
      # "JavascriptEnabled" = false;
      # "ManagedBookmarks" = [
      #   { name = "example.com"; url = "https://example.com"; }
      # ];
    };
  };
}
