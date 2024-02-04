pkgs: with pkgs; let
  ffsclient = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/ffs_client" { };
  impbcopy = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/impbcopy" { };
  audd-cli = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/audd-cli" { };
in ([
  # aichat # ChatGPT # TODO error
  # backblaze-b2 # TODO error
  # broot
  # chromium
  # clang # TODO binutils collision
  # curl-impersonate # TODO broken
  # difftastic # syntactic diff # TODO macos build fails
  # heygpt # ChatGPT # TODO broken
  # jwhois # TODO bin/whois conflict
  # lua53Packages.lua-lsp # TODO lua lsp
  # meteor # macos error
  # mlterm
  # mongodb
  # nix-doc # extract nix documentation from source TODO
  # nixops # cloud, nixos # TODO crashing build
  # ntfy # send notifications, on demand and when commands finish
  # nvimpager # TODO broken
  # ocamlPackages.google-drive-ocamlfuse
  # oci-cli
  # open-interpreter # TODO broken on macos
  # pipe-viewer # youtube viewer
  # remmina # Windows remote desktop
  # siege # TODO http load testing
  # tesseract
  # tg # telegram TODO
  # unixtools TODO error
  # unixtools.xxd
  # weechat # TODO
  # whatsapp
  # wireshark # network debugging
  # wkhtmltopdf
  (firefox_decrypt.overrideAttrs (oldAttrs: { makeWrapperArgs = oldAttrs.makeWrapperArgs ++ [ "--prefix" "DYLD_LIBRARY_PATH" ":" (lib.makeLibraryPath [ nss ]) ]; }))
  (hiPrio expect) # terminal automation
  (hiPrio texlive.combined.scheme-full)
  (hunspellWithDicts (with hunspellDicts; [ en-us fr-moderne ]))
  (ruby_3_3.withPackages (ps: with ps; [ pry pry-byebug pry-doc]))
  act # run GitHub actions locally
  android-tools
  ansi2html
  ansifilter
  antiword
  apktool # decompile apks
  archivemount # mount archives
  archiver
  aria # torrents
  ariang # aria2
  asciinema
  asdf-vm # version manager
  aspell
  atool # archive
  autossh
  awscli2
  awslogs
  awsls
  babashka # clojure
  bat # cat with syntax highlighting
  bc # calculator
  beautysh # beautify bash scripts
  black # Python code formatter
  brotab # control browser tabs
  browsh
  btop # top
  bun # JavaScript runtime
  bundix
  cachix # NixOS
  cargo # rust
  cariddi # crawler for URLs and endpoints
  castnow # Chromecast
  catdoc
  catt # Chromecast
  cdrtools # cd tools
  cfonts
  chafa # terminal images
  chatblade # ChatGPT
  choose # human-friendly and fast alternative to cut and awk
  chrome-export
  chromedriver # Chrome
  chruby # ruby version manager TODO
  cht-sh
  cloc # source code language statistics
  cmake
  colordiff # diff
  comma # nix
  crate2nix # Rust
  crudini # edit ini files
  csvkit # CSV
  ctags
  curl
  curlie # Curl HTTPie
  darkhttpd # http server
  dasel
  datamash
  dateutils # dategrep
  deep-translator
  delta # diff
  diffoscopeMinimal # in-depth comparison of files, archives, and directories
  dive # Docker image explorer
  dnscontrol
  dnsutils # dig
  docker-client
  docker-compose
  docopts # shell argument parser
  dogdns # dig alternative
  duf # disk usage
  easyocr
  eksctl # AWS
  enscript
  entr # file watcher
  espeak-ng # speech synthesis
  eternal-terminal # remote shell that automatically reconnects without interrupting the session
  eza
  fastgron # flatten JSON
  fastlane
  fd # find alternative
  fetchmail
  ffmpeg-full
  ffmpegthumbnailer
  ffsclient
  figlet
  file
  flac
  flyctl
  fnm # node version manager
  fontforge
  foreman
  fpp # path picker
  fq # jq for binary formats
  freerdp
  fswatch
  fx
  fzf # fuzzy finder
  gcalcli # google calendar
  gcc
  gcsfuse
  gdrive3
  geckodriver # Firefox
  geoipWithDatabase
  gh # github
  ghorg # GitHub backup
  ghostscript # enscript
  gist # github
  git
  git-extras
  git-lfs # git large files
  git-open
  gitfs # git filesystem
  gnumake
  gnupg
  gnutls
  go
  go-chromecast # chromecast
  gojq # jq alternative
  google-cloud-sdk # cloud
  googler # google search cli
  gotty
  gphotos-sync
  gping
  graphicsmagick # image, tools
  graphviz
  grc # log colorizer
  groff # nroff text formatting
  haskellPackages.aeson-pretty # format json
  helix
  heroku
  hexyl
  hr # horizontal rule
  html-tidy # html
  html2text
  htmlq # extract content from HTML with CSS selectors
  htop
  httpie # http client
  httrack
  hub # github
  hyperfine # benchmark
  iftop
  imagemagick
  imgurbash2 # file-sharing
  inetutils # telnet
  iperf
  ipfs
  ipinfo
  isync # email sync
  jc # json
  jdk
  jless # JSON viewer
  jo # create JSON
  jp # json manipulation
  jq # json
  keybase # TODO error
  kubectl
  kubectx # kubernetes context switch
  kubernetes-helm
  lastpass-cli
  lazydocker # Docker TUI
  lazygit # git
  lesspipe
  lf # TUI file manager
  libarchive # bsdtar
  librsvg # rasterize svg #  lolcat
  libsixel
  linode-cli
  lolcat
  lsof # system
  lua
  lua-language-server
  luajitPackages.lua-lsp
  luajitPackages.luarocks # lua package manager
  mailutils # email
  mblaze # email
  mdcat # tui markdown viewer
  mediainfo # metadata
  mermaid-cli
  miller
  mkcert
  mkchromecast # Chromecast
  monero-cli
  monolith # save web pages
  mopidy
  moreutils # via overlay; moreutils parallel conflicts with GNU parallel # for vipe & vidir
  mosh # ssh
  mpc-cli # mpd
  mpg123
  mtr # traceroute alternative
  mutt
  navi # cheatsheet cli
  ncdu # disk usage
  neo-cowsay
  neovim
  netcat # networking
  ngrep # networking
  ngrok
  niv # Nix dependency management
  nix-index
  nix-info
  nix-prefetch
  nix-prefetch-github # nix
  nix-prefetch-scripts # nix
  nix-top
  nix-tree
  nixfmt # code formatter, nix
  nixos-shell
  nload # network traffic monitor
  nmap # network
  nodejs
  nodePackages.json
  nodePackages.jsonlint
  nodePackages.pnpm # NodeJS package manager
  nodePackages.typescript-language-server
  nodePackages.vercel
  nodePackages.webtorrent-cli
  notmuch
  nox # search Nix packages
  nss # certutil
  num-utils # random, range, etc.
  nushell
  nyx
  ollama # run language models locally
  openai-whisper-cpp
  openjdk # java
  openssl
  ouch # archive
  p7zip # 7z
  pandoc
  parallel
  parinfer-rust
  patchelf
  patchutils
  pdfgrep # grep PDFs
  pdftk # pdf manipulation
  perceptualdiff # image diff
  perl
  pipenv
  piper-tts
  pipreqs
  play-with-mpv # TODO
  poetry
  poppler_utils # PDF tools
  portaudio
  postgresql
  potrace # convert bitmap to vector
  prettyping # ping alternative
  procs
  projectm
  pup # extract content from HTML with CSS selectors
  pv # pipe viewer
  pwgen
  pyenv
  python3
  python3Packages.aria2p
  python3Packages.grip # preview markdown
  python3Packages.pip
  python3Packages.pipx # install & run Python packages in isolated environments
  python3Packages.xmljson
  qemu
  racket
  rbenv # ruby version manager
  rclone
  readability-cli
  recode # encoding
  redis
  remarshal
  ripgrep
  ripgrep-all # grep PDFs etc.
  rlwrap
  rm-improved
  rnix-lsp # nix language server
  rq # TOML, CSV, JSON, YAML, etc.
  rsync
  rubyfmt # Ruby formatter
  rubyPackages.dip
  rubyPackages.kramdown
  rubyPackages.prettier
  rustc # Rust
  scrcpy # Android
  sd
  sdcv
  selenium-server-standalone
  semgrep # TODO fails on mac
  shell_gpt # ChatGPT
  shellclear # secure shell history commands by finding sensitive data
  shfmt # shell script formatter
  shot-scraper # website screenshots
  socat
  solargraph # ruby
  sox
  speedread
  speedtest-cli
  speedtest-rs
  spotdl
  sptlrx # Spotify lyrics
  sqlite
  sshpass # supply password to ssh
  starship # shell prompt
  stderred
  streamlink
  surfraw
  t # twitter
  tcpdump
  termdbms # TUI for viewing and editing database files
  termtosvg
  tesseract4 # ocr
  testdisk
  tidyp
  tig # git
  tldr # documentation
  tmate # tmux remote sharing
  tmpmail # disposable email
  tmux
  tokei # source code language statistics
  translate-shell
  tree
  tree-sitter
  trurl # URL parser
  ttyd
  units
  unrar
  unrtf # convert from RTF
  unzip
  url-parser
  urlscan
  urlwatch # monitor urls for changes
  vhs # generate GIFs
  vimpager # vim pager
  vimv-rs
  visidata # data exploration TUI
  viu # terminal images
  vivid # ls colors
  vultr-cli
  w3m
  wdiff # word diff
  weather
  wego # weather
  wget
  wget2
  woof # single-file web server
  wrk # http benchmarking
  xdg-utils
  xh
  xml2
  xmlstarlet # xml
  xmlto
  xsv # CSV
  xurls
  yai # ChatGPT
  yarn # nodejs
  yarn-bash-completion # TODO
  yj # convert between YAML, TOML, JSON, and HCL
  youtube-dl
  youtube-tui
  youtube-viewer # TODO broken?
  yq-go # yaml parsing
  yt-dlp # youtube
  ytfzf # youtube
  zip
] ++ (pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
  # darwin.ios-deploy
  # darwin.iproute2mac # TODO build error
  # darwin.xcbuild # TODO
  # darwin.xcode-install # TODO
  # darwin.xcode_14
  # fast-cli # TODO npm
  # localtunnel # TODO npm
  # m-cli # TODO errors
  # pagekite # TODO
  # webtorrent_desktop # linux
  # wrk2 # http benchmarking # linux
  # wsc
  # xcbuild
  # xcode TODO
  # xcode-install
  # xcodes
  # xcpretty
  # (procps.overrideAttrs (attrs: { postInstall = attrs.postInstall + "\n" + "rm $out/bin/top $out/share/man/man1/top.1"; }))
  asitop
  coreutils
  darwin.apple_sdk.frameworks.Security
  darwin.ios-deploy
  darwin.iproute2mac
  darwin.openwith
  darwin.trash
  duti # macos file associations
  findutils # gnu find
  gawk
  gnugrep # gnu grep
  gnused # gnu sed
  mas # Mac App Store
  pngpaste
  pstree
  psutils
  reattach-to-user-namespace # Mac tmate
  terminal-notifier # macos
  util-linux
  watch
  watchexec
]) ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
  # (google-chrome.override { commandLineArgs = "--force-device-scale-factor=2"; })
  # (zathura.override { useMupdf = true; })
  # conda # Python environments
  # fast-cli # speed test
  # google-chrome-dev
  # grab-site # web archive # TODO broken
  # ioquake3
  # kepka # telegram
  # meli # email client
  # powertop
  # rdrview # content extractor
  # shrinkpdf # TODO
  # slack
  # thunar thumbnails
  # ungoogled-chromium # browser
  # vlc_qt5
  (firefox-devedition-bin.override { cfg.enableFXCastBridge = true; cfg.speechSynthesisSupport = true; })
  (latest.firefox-nightly-bin.override { cfg.enableFXCastBridge = true; cfg.speechSynthesisSupport = true; cfg.forceWayland = true; })
  acpi
  alot # email client
  alsa-utils
  amazon-ecs-cli
  appimage-run
  audacity
  audd-cli # music recognition cli
  bcompare
  binutils # TODO collision
  bluetooth_battery
  breeze-gtk # GTK QT
  breeze-qt5 # GTK QT
  caprine-bin # Facebook Messenger
  cog # minimal WebKit browser
  commit-mono # font
  crow-translate # translate
  deadbeef # music player GUI
  detox # clean up filenames
  dhcpcd
  dtrx
  efibootmgr # UEFI
  electrum
  emacs
  emote # emoji
  ethtool
  evemu
  evince
  fatrace # file access events
  fbterm # framebuffer terminal
  ff2mpv # Firefox MPV
  fswebcam # webcam image capture
  fuseiso # mount ISO
  gcolor2 # color chooser
  glib.bin # gsettings
  gnome-epub-thumbnailer
  headset # music player
  imv # image viewer
  inkscape
  inotify-tools # file watcher
  iotop
  jamesdsp
  kitty # terminal
  libguestfs # guestfsmount
  libinput
  libnotify # notify-send
  libreoffice-fresh
  libsForQt5.breeze-gtk # GTK
  libsForQt5.kdegraphics-thumbnailers
  linuxPackages.cpupower # CPU governor
  lm_sensors
  lshw
  lxqt.pavucontrol-qt
  macchanger
  mailcheck
  mbidled # TODO
  monitor # task manager
  mupdf
  ncpamixer # ncurses PulseAudio Mixer
  neochat # Matrix client
  neovide # Vim, GUI
  nethogs
  nheko # Matrix client
  nodePackages.peerflix
  ookla-speedtest
  orjail # TOR
  pamixer # audio
  paps # text to PostScript using Pango with UTF-8 support
  pasystray
  pavucontrol # audio
  pciutils # lspci
  pdfsandwich # PDF, OCR
  percollate
  perf-tools
  playerctl # MPRIS
  ponymix # audio
  popcorntime
  pqiv # image viewer
  progress # progress viewer for running coreutils
  protonvpn-cli # VPN
  proxychains # SOCKS5 proxy
  psmisc
  pulseaudio # for pactl
  pulseaudio-dlna
  qutebrowser # browser
  reptyr # reparent tty
  rofi-emoji # emoji
  rustup
  screenkey
  session-desktop
  simple-scan # scanning
  skypeforlinux
  sleuthkit
  songrec # Shazam
  speechd # speech-dispatcher
  spotify
  strace
  sublime4 # text editor
  swappy # image annotation
  sway-launcher-desktop
  swayr
  swaytools # swayinfo
  sysz # systemd
  tdesktop # Telegram
  tidal-hifi
  torsocks
  trash-cli
  uget
  ulauncher
  unoconv
  usbutils # lsusb
  vieb # Vim browser
  vlc # video player
  vopono
  vscode
  waydroid # Android
  wezterm # terminal
  whatsapp-for-linux
  wine
  wirelesstools
  wireplumber
  wl-clipboard-x11
  wlprop
  wlrctl
  wofi # menu
  xdg-user-dirs
  xdragon # file drag-and-drop source/sink
  xscreensaver
  xsel
  ydotool # automation
  ytcast # YouTube
  ytmdesktop # YouTube Music
  zathura
])
