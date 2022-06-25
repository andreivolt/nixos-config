pkgs: with pkgs; let
  # vim = callPackage ./modules/vim { };
in [
  # TODO: Linux
  # emote # emoji
  # vieb # vim browser
  # trash-cli
  # archivemount # mount archives
  # binutils # strings etc.
  # linuxPackages.cpupower # CPU governor
  # shrinkpdf # TODO
  # neochat # matrix client
  # neovide # vim, gui
  # reptyr # reparent tty
  # # kepka # telegram
  # sublime4 # text-editor
  # swappy # image annotation
  # nheko # Matrix client
  # lshw
  # simple-scan # scanning
  # ioquake3
  # xdragon # file drag-and-drop source/sink
  # imv # image viewer
  # qutebrowser
  # deadbeef # music player GUI
  # dhcpcd
  # fswebcam # webcam image capture
  # zathura
  # acpi
  # dtrx # unarchiver
  # bluetooth_battery
  # # vlc_qt5
  # wine
  # cog # webkit browser
  # # (zathura.override { useMupdf = true; })
  # wkhtmltopdf
  # libreoffice-fresh
  # (google-chrome.override { commandLineArgs = "--force-device-scale-factor=2"; })
  # nload # network traffic monitor
  # inotify-tools # file watcher
  # libsForQt5.breeze-gtk # gtk
  # progress # progress viewer for running coreutils
  # wirelesstools
  # xsel
  # tdesktop # Telegram
  # lxqt.pavucontrol-qt
  # waydroid # android
  # fbterm # framebuffer terminal
  # glib.bin # gsettings
  # strace
  # firefox
  # breeze-gtk # gtk qt
  # pqiv # image viewer
  # breeze-qt5 # gtk qt
  # google-chrome-dev
  # mbsync # email sync
  # fatrace # file access events
  # mpc
  # libguestfs # guestfsmount
  # proxychains # SOCKS5 proxy
  # lm_sensors
  # appimage-run
  # rofi-emoji # emoji
  # efibootmgr # uefi
  # meli # email client
  # dip
  # pdfsandwich # pdf, ocr
  # freerdp
  # mopidy
  # usbutils # lsusb
  # alsamixer
  # pulseaudio # for pactl
  # nvimpager
  # nethogs
  # paps # text to PostScript using Pango with UTF-8 support
  # rdrview # content extractor
  # lt
  # wofi # menu
  # ethtool
  # alot # email client
  # grab-site
  # alsautils
  # skypeforlinux
  # playerctl # mpris, cli
  # psmisc
  # pciutils # lspci
  # protonvpn-cli # vpn
  # mailcheck
  # pamixer # audio
  # pavucontrol # audio
  # ponymix # audio
  # fuseiso # mount iso
  # ntfy # send notifications, on demand and when commands finish
  # expect # terminal automation # TODO: bin/weather conflict
  # crow-translate # translate
  # TODO
  # unixtools TODO error
  # avo.pushover
  # audd-cli # music recognition cli
  ngrok
  # vim
  # pythonPackages.pip
  # python3Packages.pip

  libnotify # notify-send

  # jwhois # TODO bin/whois conflict
  # pry # TODO: ruby conflict
  (hiPrio texlive.combined.scheme-full)
  (hunspellWithDicts (with hunspellDicts; [ en-us fr-moderne ]))
  apktool # decompile apks
  aria # torrents
  atool # archive
  comma # nix
  babashka # clojure
  fzy # fuzzy finder
  asciinema
  bat # cat with syntax highlighting
  bc # calculator
  cachix # nixos
  catt # chromecast
  cdrtools # cd tools
  chromedriver
  emacs
  exa # ls
  entr # file watcher
  ctags
  cht-sh
  cloc # source code language statistics
  csvkit # csv
  curl
  dateutils # dategrep
  dnsutils # dig
  dogdns
  fd # find alternative
  ffmpeg
  delta # diff
  file
  flac
  fpp # path picker
  fzf # fuzzy finder
  gcolor2 # color chooser
  geoipWithDatabase
  gh # github
  ghostscript # enscript
  gist # github
  git-extras
  git-hub # github
  git-open
  gnumake
  gnupg
  go
  google-cloud-sdk # cloud
  googler # google search cli
  htop
  gitfs
  graphicsmagick # image, tools
  gron # flatten JSON
  haskellPackages.aeson-pretty # format json
  heroku
  hr # horizontal rule
  html-tidy # html
  html2text
  httpie # http client
  hub # github
  iftop
  imagemagick # some things don't work with graphicsmagick
  imgurbash2 # file-sharing
  inetutils # telnet
  inkscape
  git
  jc # json
  ipfs
  jdk
  jo # create JSON
  jp # json manipulation
  jq # json
  keybase
  lastpass-cli
  leiningen # clojure
  librsvg # rasterize svg
  lsd # ls alternative
  lsof # system
  mailutils # email
  mblaze # email
  mdcat # tui markdown viewer
  mediainfo # metadata
  miller
  monolith # web-archive
  moreutils # via overlay; moreutils parallel conflicts with GNU parallel # for vipe & vidir
  mpc_cli # mpd
  luajitPackages.luarocks # lua package manager
  foreman
  mtr # traceroute alternative
  libarchive # bsdtar
  fnm # node version manager
  python39Packages.pipx
  mupdf # for mutool
  mutt
  netcat # networking
  ngrep # networking
  nix-index
  nix-info
  nix-prefetch-github # nix
  nix-prefetch-scripts # nix
  nix-top
  nixfmt # code formatter, nix
  nixops # cloud, nixos # TODO crashing build
  nixos-shell
  nixpkgsUnstable.telegram-cli
  nixpkgsUnstable.yt-dlp # youtube
  nmap # network
  nodejs
  nodePackages.json
  nodePackages.webtorrent-cli
  notmuch
  nox # search Nix packages
  openssl
  cargo # rust
  openjdk # java
  colordiff # diff
  cmake
  awscli2
  aspell
  asdf # version manager
  neovim-nightly
  rbenv # ruby version manager
  p7zip # 7z
  pandoc
  perl
  parallel
  patchelf
  patchutils
  pdftk # pdf manipulation
  perceptualdiff # image diff
  poppler_utils # pdf tools
  potrace # convert bitmap to vector
  pup # html
  pv # pipe viewer
  python
  python3
  python3Packages.pipx # install & run Python packages in isolated environments
  rclone
  recode # encoding
  remarshal
  ripgrep
  rlwrap
  rnix-lsp # nix language server
  rsync
  ruby
  sdcv
  socat
  sox
  speedtest-cli
  sqlite
  surfraw
  t # twitter
  tcpdump
  tesseract4 # ocr
  tig # git
  tldr # documentation
  tmate # tmux remote sharing
  tmpmail # disposable email
  translate-shell
  tree
  tree-sitter
  units
  lazygit # git
  meteor
  lua
  unzip
  urlscan
  urlwatch # monitor urls for changes
  viu
  w3m
  wget
  xdg_utils
  xmlstarlet # xml
  xml2
  xurls
  yarn # nodejs
  youtube-dl
  youtube-viewer
  ytfzf # youtube
  kitty
  kubectl
  mkcert
  tmux
  tesseract
  siege
  wdiff # word diff
  xmlto
  mosh # ssh

  rubyPackages.kramdown
  rubyPackages.prettier
  rubyPackages.pry
  rubyPackages.pry-byebug
  rubyPackages.pry-doc

  wrk # http benchmarking
  yq # yaml parsing
  vscode
  redis
  yj

  chruby # ruby version manager TODO
  eksctl
  browsh

  # lua53Packages.lua-lsp # TODO lua lsp
  luajitPackages.lua-lsp

  postgresql_14
  navi # cheatsheet
  pwgen
  scrcpy # android

  weechat # TODO
  nss # TODO
  play-with-mpv # TODO
  rustc # rust
  weather

  tidyp
  selenium-server-standalone
]
