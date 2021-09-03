pkgs: with pkgs; let
  vim = callPackage ./modules/vim { };
in [
  acpi
  apktool
  archivemount
  aria
  atool # archive
  # audd-cli # music recognition cli
  avo.pushover
  babashka # clojure
  bat
  bc # calculator
  binutils
  breeze-gtk # gtk qt
  breeze-qt5 # gtk qt
  cachix # nixos
  cdrtools # cd tools
  chromedriver
  cloc # source code language statistics
  linuxPackages.cpupower # CPU governor
  csvkit # csv
  curl
  cv # progress viewer for running coreutils
  dateutils # dategrep
  dnsutils
  dragon-drop # file drag-and-drop source/sink
  dtrx # unarchiver
  efibootmgr # uefi
  # expect # terminal automation
  expect # tty automation
  fatrace # file access events
  fd # find alternative
  ffmpeg
  file
  firefox
  fpp # path picker
  fswebcam # webcam image capture
  fuseiso # mount iso
  fzf # fuzzy finder
  gcolor2 # color chooser
  geoipWithDatabase
  gh # github
  gist # github
  git-hub # github
  gnome-breeze # gtk
  gnupg
  (google-chrome.override { commandLineArgs = "--force-device-scale-factor=2"; })
  google-cloud-sdk # cloud
  googler # google search cli
  graphicsmagick # image, tools
  gron # flatten JSON
  haskellPackages.aeson-pretty # format json
  hr # horizontal rule
  html2text
  htmlTidy # html
  httpie # http client
  hub # github
  iftop
  imagemagick # some things don't work with graphicsmagick
  imgurbash2 # file-sharing
  imv # image viewer
  inkscape
  inotify-tools # file watcher
  jc # json
  jo # create JSON
  jp # json manipulation
  jq # json
  keybase
  lastpass-cli
  leiningen # clojure
  libguestfs # guestfsmount
  libnotify # notify-send
  libreoffice-fresh
  librsvg # rasterize svg
  lm_sensors
  lsof # system
  lxqt.pavucontrol-qt
  mailutils # email
  mdcat # terminal markdown viewer
  mediainfo # metadata
  miller
  monolith # web-archive
  moreutilsWithoutParallel # moreutils parallel conflicts with GNU parallel # for vipe & vidir
  mtr # traceroute alternative
  mupdf # for mutool
  neochat # matrix client
  neovide # vim, gui
  netcat # networking
  nethogs
  ngrep # networking
  ngrok
  nix-index
  # nix-info
  nix-prefetch-github # nixos
  nix-prefetch-scripts # nixos
  nix-top
  nixfmt # code formatter, nix
  nixops # cloud, nixos
  # nixos-shell
  nixpkgsUnstable.yt-dlp # youtube
  nmap # network
  # nodePackages.json
  nodePackages.webtorrent-cli
  nodejs
  nox # search Nix packages
  ntfy # send notifications, on demand and when commands finish
  nvimpager
  openssl
  p7zip # 7z
  pamixer # audio
  pandoc
  parallel
  patchelf
  pavucontrol # audio
  pciutils # lspci
  pdftk # pdf manipulation
  playerctl # mpris, cli
  ponymix # audio
  potrace # convert bitmap to vector
  pqiv # image viewer
  protonvpn-cli # vpn
  psmisc
  pulseaudio # for pactl
  pup # html
  pv # pipe viewer
  python
  python3
  python3Packages.pipx # install & run Python packages in isolated environments
  rdrview # content extractor
  recode # encoding
  remarshal
  reptyr # reparent tty
  ripgrep
  rlwrap
  rnix-lsp # nix language server
  rsync
  sdcv
  simple-scan # scanning
  skype
  socat
  sqlite
  strace
  sublime3 # text-editor
  surfraw
  swappy # image annotation
  t # twitter
  tdesktop # Telegram
  # telegram-cli
  telnet # network
  tesseract4 # ocr
  tldr # documentation
  tmate # tmux remote sharing
  tmpmail # disposable email
  translate-shell
  trash-cli
  tree
  units
  unzip
  # urlscan
  usbutils # lsusb
  vim
  vlc
  w3m
  wget
  xdg_utils
  xsel
  xurls
  youtube-dl
  youtube-viewer
  poppler-utils # pdf tools
  (zathura.override { useMupdf = true; })
]
