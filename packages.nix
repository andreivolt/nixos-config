pkgs: with pkgs; let
  # vim = callPackage ./modules/vim { };
  # TODO
  # impbcopy = stdenv.mkDerivation rec {
  #   pname = "impbcopy";
  #   buildInputs = with darwin.apple_sdk.frameworks; [ Foundation AppKit ];
  #   NIX_LDFLAGS = "-framework Foundation -framework AppKit";
  #   src = /Users/avo/Documents/impbcopy;
  #   buildPhase = ''
  #     gcc -Wall -g -O3 -ObjC -framework Foundation -framework AppKit -o impbcopy impbcopy.m
  #     find
  #   '';
  # };

  url-parser = buildGoPackage rec {
    pname = "url-parser";
    version = "2017-07-17";
    rev = "823ca65eb0bd1c80c3499645cd04250ce5997092";

    goPackagePath = "github.com/herloct/${pname}";

    src = fetchgit {
      inherit rev;
      url = "https://${goPackagePath}";
      sha256 = "1w4664j4yycxrp237g9909clazaj2bys3x9q71ffpwxk91zjkmyw";
    };

    # TODO: add metadata https://nixos.org/nixpkgs/manual/#sec-standard-meta-attributes
    meta = {
    };
  };
in ([
  act # GitHub actions simulator
  ansi2html
  apktool # decompile apks
  archiver
  aria # torrents
  asciinema
  asdf-vm # version manager
  aspell
  atool # archive
  # audd-cli # music recognition cli
  autossh
  # avo.pushover
  awscli2
  babashka # clojure
  bat # cat with syntax highlighting
  bc # calculator
  brotab # control browser tabs
  browsh
  bun # JavaScript runtime
  cachix # nixos
  cargo # rust
  castnow # chromecast
  catt # chromecast
  cdrtools # cd tools
  chafa # terminal images
  chromedriver
  chruby # ruby version manager TODO
  cht-sh
  cloc # source code language statistics
  cmake
  colordiff # diff
  comma # nix
  # crow-translate # translate
  csvkit # csv
  ctags
  curl
  darkhttpd # http server
  dasel
  dateutils # dategrep
  delta # diff
  # difftastic # syntactic diff # TODO macos build fails
  dnsutils # dig
  docker-client
  dogdns
  eksctl
  # electrum TODO error
  emacs
  entr # file watcher
  exa # ls
  # expect # terminal automation # TODO: bin/weather conflict
  fd # find alternative
  file
  flac
  fnm # node version manager
  fontforge
  foreman
  fpp # path picker
  fzf # fuzzy finder
  fzy # fuzzy finder
  gcalcli # google calendar
  gcolor2 # color chooser
  geoipWithDatabase
  gh # github
  ghostscript # enscript
  gist # github
  git
  git-extras
  git-hub # github
  git-open
  gitfs # git filesystem
  gnumake
  gnupg
  go
  go-chromecast # chromecast
  gojq # jq alternative
  google-cloud-sdk # cloud
  googler # google search cli
  graphicsmagick # image, tools
  graphviz
  grc # log colorizer
  groff # nroff text formatting
  gron # flatten JSON
  haskellPackages.aeson-pretty # format json
  heroku
  hr # horizontal rule
  html-tidy # html
  html2text
  htmlq # extract content from HTML with CSS selectors
  htop
  httpie # http client
  hub # github
  (hunspellWithDicts (with hunspellDicts; [ en-us fr-moderne ]))
  iftop
  imagemagick # some things don't work with graphicsmagick
  imgurbash2 # file-sharing
  inetutils # telnet
  inkscape
  ipfs
  ipinfo
  jc # json
  jdk
  jless # JSON viewer
  jo # create JSON
  jp # json manipulation
  jq # json
  # jwhois # TODO bin/whois conflict
  # keybase # TODO error
  kitty
  kubectl
  kubectx # kubernetes context switch
  kubernetes-helm
  lastpass-cli
  lazydocker # Docker TUI
  lazygit # git
  leiningen # clojure
  libarchive # bsdtar
  librsvg # rasterize svg
  lsd # ls alternative
  lsof # system
  lua
  # lua53Packages.lua-lsp # TODO lua lsp
  luajitPackages.lua-lsp
  luajitPackages.luarocks # lua package manager
  mailutils # email
  mblaze # email
  mdcat # tui markdown viewer
  mediainfo # metadata
  meteor
  miller
  mkcert
  mkchromecast # chromecast
  monolith # web-archive
  moreutils # via overlay; moreutils parallel conflicts with GNU parallel # for vipe & vidir
  mosh # ssh
  mpc_cli # mpd
  mtr # traceroute alternative
  mupdf # for mutool
  mutt
  navi # cheatsheet
  navi # cheatsheet cli
  ncdu # disk usage
  neovim
  # neovim-nightly TODO
  netcat # networking
  ngrep # networking
  ngrok
  nix-doc # extract nix documentation from source
  nix-index
  nix-info
  nix-prefetch
  nix-prefetch-github # nix
  nix-prefetch-scripts # nix
  nix-top
  nixfmt # code formatter, nix
  # nixops # cloud, nixos # TODO crashing build
  nixos-shell
  nixpkgsUnstable.telegram-cli
  nixpkgsUnstable.yt-dlp # youtube
  nmap # network
  nodePackages.json
  nodePackages.pnpm # NodeJS package manager
  nodePackages.vercel
  nodePackages.webtorrent-cli
  nodejs
  notmuch
  nox # search Nix packages
  nss # TODO
  # ntfy # send notifications, on demand and when commands finish
  num-utils # random, range, etc.
  openjdk # java
  openssl
  p7zip # 7z
  pandoc
  parallel
  patchelf
  patchutils
  pdfgrep # grep PDFs
  pdftk # pdf manipulation
  perceptualdiff # image diff
  perl
  pipe-viewer # youtube viewer
  play-with-mpv # TODO
  poppler_utils # pdf tools
  postgresql_14
  potrace # convert bitmap to vector
  prettyping # ping alternative
  # pry # TODO: ruby conflict
  pup # extract content from HTML with CSS selectors
  pv # pipe viewer
  pwgen
  python
  python3
  # python3Packages.pip
  python3Packages.pipx # install & run Python packages in isolated environments
  # pythonPackages.pip
  qemu
  rbenv # ruby version manager
  rclone
  recode # encoding
  redis
  remarshal
  ripgrep
  ripgrep-all # grep PDFs etc.
  rlwrap
  rnix-lsp # nix language server
  rq # TOML, CSV, JSON, YAML, etc.
  rsync
  ruby
  rubyPackages.kramdown
  rubyPackages.prettier
  rubyPackages.pry
  rubyPackages.pry-byebug
  rubyPackages.pry-doc
  rustc # rust
  scrcpy # android
  sdcv
  selenium-server-standalone
  # semgrep # TODO not on mac
  shfmt # shell script formatter
  siege
  socat
  solargraph # ruby
  sox
  speedtest-cli
  sqlite
  starship # shell prompt
  stderred
  surfraw
  sysz # systemd
  t # twitter
  tcpdump
  terminal-notifier
  tesseract
  tesseract4 # ocr
  (hiPrio texlive.combined.scheme-full)
  # tg # telegram TODO
  tidyp
  tig # git
  tldr # documentation
  tmate # tmux remote sharing
  tmpmail # disposable email
  tmux
  translate-shell
  tree
  tree-sitter
  units
  # unixtools TODO error
  unrar
  unzip
  url-parser
  urlscan
  urlwatch # monitor urls for changes
  # vim
  vimpager # vim pager
  viu # terminal images
  vivid # ls colors
  vscode
  w3m
  wdiff # word diff
  weather
  # weechat # TODO
  wget
  wireshark # network debugging
  wrk # http benchmarking
  xdg-utils
  xml2
  xmlstarlet # xml
  xmlto
  xurls
  yarn # nodejs
  yarn-bash-completion # TODO
  yj
  youtube-dl
  youtube-viewer
  yq # yaml parsing
  ytfzf # youtube
  zip
  zsh-better-npm-completion # TODO
  zsh-fast-syntax-highlighting # TODO
]
++
pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
  reattach-to-user-namespace # mac tmate
  pngpaste
  # m-cli # TODO errors
]
++
pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
  acpi
  alot # email client
  alsamixer
  alsautils
  appimage-run
  archivemount # mount archives
  binutils # strings etc.
  bluetooth_battery
  breeze-gtk # gtk qt
  breeze-qt5 # gtk qt
  cog # webkit browser
  deadbeef # music player GUI
  dhcpcd
  dip
  efibootmgr # uefi
  emote # emoji
  ethtool
  fatrace # file access events
  fbterm # framebuffer terminal
  ffmpeg
  firefox
  freerdp
  fswebcam # webcam image capture
  fuseiso # mount iso
  glib.bin # gsettings
  google-chrome-dev
  (google-chrome.override { commandLineArgs = "--force-device-scale-factor=2"; })
  grab-site
  imv # image viewer
  inotify-tools # file watcher
  ioquake3
  # kepka # telegram
  libguestfs # guestfsmount
  libnotify # notify-send
  libreoffice-fresh
  libsForQt5.breeze-gtk # gtk
  linuxPackages.cpupower # CPU governor
  lm_sensors
  lshw
  lt
  lxqt.pavucontrol-qt
  mailcheck
  mbsync # email sync
  meli # email client
  mopidy
  mpc
  neochat # matrix client
  neovide # vim, gui
  nethogs
  nheko # Matrix client
  nload # network traffic monitor
  nvimpager
  pamixer # audio
  paps # text to PostScript using Pango with UTF-8 support
  pavucontrol # audio
  pciutils # lspci
  pdfsandwich # pdf, ocr
  playerctl # mpris, cli
  ponymix # audio
  pqiv # image viewer
  progress # progress viewer for running coreutils
  protonvpn-cli # vpn
  proxychains # SOCKS5 proxy
  psmisc
  pulseaudio # for pactl
  qutebrowser
  rdrview # content extractor
  reptyr # reparent tty
  rofi-emoji # emoji
  shrinkpdf # TODO
  simple-scan # scanning
  skypeforlinux
  strace
  sublime4 # text-editor
  swappy # image annotation
  tdesktop # Telegram
  trash-cli
  usbutils # lsusb
  vieb # vim browser
  # vlc_qt5
  waydroid # android
  wine
  wirelesstools
  wkhtmltopdf
  wofi # menu
  xdragon # file drag-and-drop source/sink
  xsel
  zathura
  # (zathura.override { useMupdf = true; })
])
