pkgs: with pkgs; let
  athena-jot = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/athena-jot" { };
  audd-cli = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/audd-cli" { };
  autoraise = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/autoraise" { experimental_focus_first = true; };
  carbonyl = (callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/carbonyl" { }).package;
  chart-stream = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/chart-stream" { };
  cuff = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/cuff" { };
  ffsclient = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/ffs_client" { };
  googler = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/googler" { };
  impbcopy = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/impbcopy" { };
  ipfs-deploy = (callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/ipfs-deploy" { }).package;
  jtbl = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/jtbl" { };
  kefctl = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/kefctl" { };
  mkalias = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/mkalias" { };
  nix-beautify = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/nix-beautify" { };
  pbpaste-html = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/pbpaste-html" { };
  pushover = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/pushover" { };
  scihub = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/scihub.py" { };
  screenshot_tweet = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/screenshot_tweet" { };
  spark = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/spark" { };
  tidal-dl = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/tidal-dl" { };
  we-get = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/we-get" { };
  x_x = callPackage "${builtins.getEnv "HOME"}/drive/nix-packages/x_x" { };
  edn = pkgs.stdenv.mkDerivation rec {
    name = "edn";
    src = pkgs.fetchurl {
      url = "https://gist.githubusercontent.com/andreivolt/6cbd58c9163ad5ac47e032b335898435/raw/convert.clj";
      sha256 = "sha256-3gZ38ICDWDKQamPvYuCL3yLR/l0+DrWe5iJYdu6TLYc=";
    };
    unpackPhase = "true";
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/${name}
      chmod +x $out/bin/${name}
    '';
  };
  anypaste = pkgs.stdenv.mkDerivation rec {
    name = "anypaste";
    src = pkgs.fetchurl {
      url = "https://anypaste.xyz/sh";
      sha256 = "sha256-w0My8b0scQ3/hgGqeBK1X0qKcgjwWgMqwPLgohGUCRI=";
    };
    unpackPhase = "true";
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/${name}
      chmod +x $out/bin/${name}
    '';
  };
  cached-nix-shell = pkgs.callPackage (pkgs.fetchFromGitHub {
    owner = "xzfc";
    repo = "cached-nix-shell";
    rev = "master";
    sha256 = "sha256-sHsUsqGeAZW1OMbeqQdLqb7LgEvhzWM7jq17EU16K0A=";
  }) {};
  json2nix = pkgs.stdenv.mkDerivation rec {
    name = "json2nix";
    src = pkgs.fetchurl {
      url = "https://gist.githubusercontent.com/andreivolt/c0ccee3868def8778fb8fb6436489630/raw/1d47fde8d2f9b3029ed8535518bb32af497edcba/json2nix";
      sha256 = "sha256-IacRsDQTX60H5SoXIcAVAfGdJ41YBATXbMJGD61xb7Y";
    };
    buildInputs = with pkgs; [ python3 ];
    unpackPhase = "true";
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/${name}
      chmod +x $out/bin/${name}
      patchShebangs $out/bin/${name}
    '';
  };
in ([
  # nix-beautify TODO

  tigervnc
  realvnc-vnc-viewer
  nodePackages.node2nix

  json2nix
  edn
  spark
  cached-nix-shell
  anypaste
  autoraise
  ipfs-deploy
  we-get
  nix-zsh-completions

  audible-cli
  aaxtomp3

  scihub
  mpv # video player
  screenshot_tweet
  nixpkgs-fmt # Nix formatter
  gum # TUI widgets
  oauth2l # CLI for interacting with Google API authentication
  highlight # source code highlighting tool
  direnv
  scriptisto
  python3Packages.youtube-transcript-api
  firebase-tools
  # aichat # ChatGPT # TODO error
  # athena-jot
  backblaze-b2
  clojure
  boot
  zprint
  # broot
  # chromium
  # clang # TODO binutils collision
  # curl-impersonate # TODO broken
  # difftastic # syntactic diff # TODO macos build fails
  # heygpt # ChatGPT # TODO broken
  impbcopy
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
  # remmina # Windows remote desktop
  # siege # TODO http load testing
  # tesseract
  # tg # telegram TODO
  # tidal-dl
  # unixtools TODO error
  # unixtools.xxd
  # weechat # TODO
  # whatsapp
  # wireshark # network debugging
  # wkhtmltopdf
  # x_x
  (firefox_decrypt.overrideAttrs (oldAttrs: { makeWrapperArgs = oldAttrs.makeWrapperArgs ++ [ "--prefix" "DYLD_LIBRARY_PATH" ":" (lib.makeLibraryPath [ nss ]) ]; }))
  (hiPrio expect) # terminal automation
  (hiPrio texlive.combined.scheme-full)
  (hunspellWithDicts (with hunspellDicts; [ en-us fr-moderne ]))
  (ruby_3_2.withPackages (ps: with ps; [ pry pry-byebug pry-doc]))
  act # run GitHub actions locally
  android-tools
  shellcheck
  du-dust # disk usage
  elixir
  erlang
  zig
  nixpkgsUnstable.deno
  ansi2html
  ansifilter
  glab # GitLab CLI
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
  bundix # Ruby Nix
  cachix # Nix
  cargo # Rust
  cariddi # crawler for URLs and endpoints
  castnow # Chromecast
  catdoc
  catt # Chromecast
  cdrtools # cd tools
  cfonts # console banner generator
  chafa # terminal images
  chart-stream
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
  universal-ctags
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
  pigz # parallel gzip
  dnscontrol
  dnsutils # dig
  docopts # shell argument parser
  dogdns # dig alternative
  duf # disk usage visualizer
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
  git
  python-launcher
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
  jtbl
  keybase # TODO error
  kubectl
  kubectx # kubernetes context switch
  kubernetes-helm
  lastpass-cli
  lazydocker # Docker TUI
  lazygit # git
  lesspipe
  edir # better vidir
  lf # TUI file manager
  libarchive # bsdtar
  librsvg # rasterize SVG
  rust-script
  libsixel
  linode-cli
  lolcat # console text colorizer animate
  lsof # system
  lua
  lua-language-server
  luajitPackages.luarocks # lua package manager
  mailutils # email
  mblaze # email
  mdcat # TUI markdown viewer
  glow # TUI markdown viewer
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
  # ncdu # disk usage # TODO build crash
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
  nodePackages.json
  nodePackages.jsonlint
  nodePackages.pnpm # NodeJS package manager
  nodePackages.typescript-language-server
  nodePackages.vercel
  nodePackages.webtorrent-cli
  pastel # color converter, color picker
  notmuch
  manix
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
  python3Packages.grip # preview GitHub markdown
  python3Packages.pip
  python3Packages.pip-tools
  nixpkgsUnstable.python3Packages.pipx # install & run Python packages in isolated environments
  python3Packages.xmljson
  qemu
  racket
  rbenv # Ruby version manager
  rclone
  readability-cli # content extractor
  nixpkgsUnstable.python3Packages.trafilatura # content extractor
  recode # encoding
  redis
  remarshal
  ripgrep
  ripgrep-all # grep PDFs etc.
  rlwrap
  rm-improved
  rnix-lsp # Nix language server
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
  speedtest-go
  spotdl
  sptlrx # Spotify lyrics
  sqlite
  sshpass # supply password to ssh
  nodePackages.eslint
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
  tig # Git TUI
  tealdeer # tldr client
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
  youtube-viewer
  yj # convert between YAML, TOML, JSON, and HCL
  yq-go # command-line YAML, JSON, XML, CSV, TOML and properties processor
  yt-dlp # youtube
  ytfzf # youtube
  zip
] ++ (pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
  # (procps.overrideAttrs (attrs: { postInstall = attrs.postInstall + "\n" + "rm $out/bin/top $out/share/man/man1/top.1"; }))
  # darwin.ios-deploy
  # darwin.iproute2mac # TODO build error
  # darwin.xcbuild # TODO
  # darwin.xcode-install # TODO
  # darwin.xcode_14
  # fast-cli # TODO npm
  # localtunnel # TODO npm
  # pagekite # TODO
  # webtorrent_desktop # linux
  # wrk2 # http benchmarking # linux
  # wsc
  # xcbuild
  # xcode TODO
  # xcode-install
  # xcodes
  # xcpretty
  asitop
  coreutils
  darwin.apple_sdk.frameworks.Security
  darwin.apple_sdk.frameworks.SystemConfiguration
  darwin.ios-deploy
  darwin.iproute2mac
  darwin.openwith
  darwin.trash
  dockutil
  duti # macos file associations
  findutils # gnu find
  gawk
  gnugrep # gnu grep
  gnused # gnu sed
  m-cli # TODO errors
  mas # Mac App Store
  mkalias
  pbpaste-html
  pngpaste
  pstree
  psutils
  reattach-to-user-namespace # Mac tmate
  skhd
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
  crow-translate # translate
  cuff
  detox # clean up filenames
  dhcpcd
  docker-client
  docker-compose
  downonspot # Spotify downloader
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
  gcolor2 # color picker
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
  nodejs
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
  sleuthkit # data forensics tool
  songrec # Shazam CLI
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
  watchlog # easy monitoring of live logs
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
