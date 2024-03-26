pkgs: with pkgs; let
  anypaste = callPackage ./pkgs/anypaste { };
  athena-jot = callPackage ./pkgs/athena-jot { };
  audd-cli = callPackage ./pkgs/audd-cli { };
  autoraise = callPackage ./pkgs/autoraise { experimental_focus_first = true; };
  cached-nix-shell = callPackage ./pkgs/cached-nix-shell { };
  carbonyl = (callPackage ./pkgs/carbonyl { }).package;
  chart-stream = callPackage ./pkgs/chart-stream { };
  cuff = callPackage ./pkgs/cuff { };
  edn = callPackage ./pkgs/edn { };
  ffsclient = callPackage ./pkgs/ffs_client { };
  googler = callPackage ./pkgs/googler { };
  gpt-cli = callPackage ./pkgs/gpt-cli { inherit (python3Packages) anthropic attrs black google-generativeai openai pydantic prompt-toolkit poetry-core orjson pytest pyyaml rich tiktoken tokenizers typing-extensions; };
  impbcopy = callPackage ./pkgs/impbcopy { };
  ipfs-deploy = (callPackage ./pkgs/ipfs-deploy { }).package;
  json2nix = callPackage ./pkgs/json2nix { };
  jtab = callPackage ./pkgs/jtab { };
  jtbl = callPackage ./pkgs/jtbl { inherit (python3Packages) buildPythonApplication tabulate; };
  kefctl = callPackage ./pkgs/kefctl { inherit perl; };
  mkalias = callPackage ./pkgs/mkalias { };
  nix-beautify = callPackage ./pkgs/nix-beautify { };
  nixos-repl = callPackage ./pkgs/nixos-repl { };
  pbpaste-html = callPackage ./pkgs/pbpaste-html { };
  pushover-cli = callPackage ./pkgs/pushover-cli { };
  scihub = callPackage ./pkgs/scihub.py { inherit (python3Packages) beautifulsoup4 buildPythonPackage pysocks requests retrying; };
  screenshot_tweet = callPackage ./pkgs/screenshot_tweet { inherit (python3Packages) buildPythonApplication playwright; };
  spark = callPackage ./pkgs/spark { };
  strip-tags = callPackage ./pkgs/strip-tags { inherit (python3Packages) buildPythonApplication pytestCheckHook setuptools pythonOlder; };
  textract = callPackage ./pkgs/textract { inherit (nixpkgsUnstable.python3Packages) argcomplete beautifulsoup4 buildPythonPackage chardet docx2txt extract-msg fetchPypi lark pdfminer-six python-pptx rtfde six speechrecognition xlrd; };
  tidal-dl = callPackage ./pkgs/tidal-dl { inherit (python3Packages) buildPythonApplication buildPythonPackage colorama fetchPypi lib mutagen prettytable pycrypto pydub requests; };
  ttok = callPackage ./pkgs/ttok { inherit (python3Packages) click tiktoken buildPythonPackage; };
  twscrape = callPackage ./pkgs/twscrape { inherit (python3Packages) aiosqlite buildPythonPackage fake-useragent hatchling httpx loguru; };
  we-get = callPackage ./pkgs/we-get { inherit (python3Packages) beautifulsoup4 buildPythonPackage colorama docopt poetry-core prompt_toolkit pygments; };
  x_x = callPackage ./pkgs/x_x { inherit (python3Packages) buildPythonPackage click six xlrd; };
  yt-fts = callPackage ./pkgs/yt-fts { inherit (nixpkgsUnstable.python3Packages) beautifulsoup4 buildPythonPackage chromadb click openai pip requests rich; };
in
[
  # heygpt # TODO
  # mongodb # TODO
  # ntfy # TODO
  (firefox_decrypt.overrideAttrs (oldAttrs: { makeWrapperArgs = oldAttrs.makeWrapperArgs ++ [ "--prefix" "DYLD_LIBRARY_PATH" ":" (lib.makeLibraryPath [ nss ]) ]; }))
  (hiPrio expect)
  (hiPrio texlive.combined.scheme-full)
  (hunspellWithDicts (with hunspellDicts; [ en-us fr-moderne ]))
  (nvimpager.overrideAttrs (oldAttrs: { doCheck = false; meta = oldAttrs.meta // { broken = false; }; }))
  (python3Packages.litellm.overrideAttrs (oldAttrs: { propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ (with python3Packages; [ appdirs backoff fastapi jinja2 setuptools tokenizers tomli tomli-w uvicorn ]); }))
  (python3Packages.pdfplumber.override { pandas-stubs = python3Packages.pandas-stubs.overrideAttrs (oldAttrs: { doCheck = false; doInstallCheck = false; }); })
  (ruby_3_2.withPackages (ps: with ps; [ pry pry-byebug pry-doc ]))
  aaxtomp3
  act
  android-tools
  ansi2html
  ansifilter
  antiword
  anypaste
  apktool
  archivemount
  archiver
  aria
  ariang
  asciinema
  asdf-vm
  aspell
  ast-grep
  athena-jot
  atool
  audible-cli
  autoraise
  autossh
  awscli2
  awslogs
  awsls
  babashka
  backblaze-b2
  bat
  bc
  beautysh
  black
  boot
  broot
  brotab
  browsh
  btop
  bun
  bundix
  cached-nix-shell
  cachix
  cargo
  cariddi
  castnow
  catdoc
  catt
  cdrtools
  cfonts
  chafa
  chart-stream
  chatblade
  choose
  chrome-export
  chromedriver
  chruby
  cht-sh
  clang
  cloc
  clojure
  cmake
  colordiff
  comma
  crate2nix
  crudini
  csvkit
  curl
  curlie
  darkhttpd
  dasel
  datamash
  dateutils
  deep-translator
  delta
  diffoscopeMinimal
  difftastic
  direnv
  dive
  dnscontrol
  dnsutils
  docopts
  dogdns
  du-dust
  duckdb
  duf
  easyocr
  edir
  edn
  eksctl
  elixir
  enscript
  entr
  erlang
  espeak-ng
  eternal-terminal
  eza
  fastgron
  fastlane
  fd
  fetchmail
  ffmpeg-full
  ffmpegthumbnailer
  ffsclient
  file
  firebase-tools
  flac
  flyctl
  fnm
  fontforge
  foreman
  fpp
  fq
  freerdp
  fswatch
  fx
  fzf
  gcalcli
  gcsfuse
  gdrive3
  geckodriver
  geoipWithDatabase
  gh
  ghorg
  ghostscript
  git
  git-extras
  git-lfs
  git-open
  gitfs
  glab
  glow
  gnumake
  gnupg
  gnutls
  go
  go-chromecast
  gojq
  google-cloud-sdk
  googler
  gotty
  gphotos-sync
  gping
  gpt-cli
  graphicsmagick
  graphviz
  grc
  groff
  gum
  haskellPackages.aeson-pretty
  helix
  heroku
  hexyl
  highlight
  hr
  html-tidy
  html2text
  htmlq
  htop
  httpie
  httrack
  humanfriendly
  hyperfine
  iftop
  imagemagick
  img2pdf
  imgurbash2
  impbcopy
  inetutils
  iperf
  ipfs
  ipfs-deploy
  ipinfo
  isync
  janet jpm
  jc
  jdk
  jless
  jo
  jp
  jq
  json2nix
  jtab
  jtbl
  keybase
  kubectl
  kubectx
  kubernetes-helm
  lastpass-cli
  lazydocker
  lazygit
  leiningen
  lesspipe
  lf
  libarchive
  librsvg
  libsixel
  linode-cli
  llm
  lolcat
  lsof
  lua
  lua-language-server
  luajitPackages.luarocks
  mailutils
  manix
  mblaze
  mdcat
  mediainfo
  mermaid-cli
  miller
  mkcert
  mkchromecast
  moar
  monero-cli
  monolith
  mopidy
  moreutils
  mosh
  mpc-cli
  mpg123
  mpv
  mtr
  mutt
  navi
  neo-cowsay
  neovim
  netcat
  ngrep
  ngrok
  niv
  nix-beautify
  nix-index
  nix-info
  nix-init
  nix-prefetch
  nix-prefetch-github
  nix-prefetch-scripts
  nix-top
  nix-tree
  nix-zsh-completions
  nixfmt
  nixops_unstable
  nixos-shell
  nixpkgs-fmt
  nixpkgsUnstable.aichat
  nixpkgsUnstable.deno
  nixpkgsUnstable.mplayer
  nixpkgsUnstable.ncdu
  nixpkgsUnstable.nix-doc
  nixpkgsUnstable.python3Packages.html2image
  nixpkgsUnstable.python3Packages.htmldate
  nixpkgsUnstable.python3Packages.pipx
  nixpkgsUnstable.python3Packages.trafilatura
  nixpkgsUnstable.tg
  nload
  nmap
  nodePackages.diff2html-cli
  nodePackages.eslint
  nodePackages.json
  nodePackages.jsonlint
  nodePackages.localtunnel
  nodePackages.node2nix
  nodePackages.pnpm
  nodePackages.serve
  nodePackages.typescript-language-server
  nodePackages.vercel
  nodePackages.webtorrent-cli
  notmuch
  nox
  nss
  num-utils
  nushell
  nyx
  oauth2l
  oci-cli
  ollama
  open-interpreter
  openai-whisper-cpp
  openjdk
  openssl
  ouch
  p7zip
  pandoc
  parallel
  parinfer-rust
  pastel
  patchelf
  patchutils
  pdfgrep
  pdftk
  perceptualdiff
  perl
  pigz
  pipenv
  piper-tts
  pipreqs
  play-with-mpv # TODO
  poetry
  poppler_utils
  portaudio
  postgresql
  potrace
  prettyping
  procs
  projectm
  pushover-cli
  pv
  pwgen
  pyenv
  python-launcher
  python3Packages.argcomplete # TODO
  python3Packages.aria2p
  python3Packages.distro
  python3Packages.docx2txt
  python3Packages.grip
  python3Packages.markdown-it-py
  python3Packages.num2words
  python3Packages.openai
  python3Packages.pip-tools
  python3Packages.pygments
  python3Packages.tabulate
  python3Packages.xmljson
  python3Packages.youtube-transcript-api
  qemu
  racket
  rbenv
  rclone
  readability-cli
  realvnc-vnc-viewer
  recode
  redis
  remarshal
  remmina
  ripgrep
  ripgrep-all
  rlwrap
  rm-improved
  rnix-lsp
  rq
  rsync
  rubocop
  rubyfmt
  rubyPackages.dip
  rubyPackages.kramdown
  rubyPackages.prettier
  rust-script
  rustc
  scc
  scihub
  scrcpy
  screenshot_tweet
  scriptisto
  sd
  sdcv
  selenium-server-standalone
  semgrep
  shell_gpt
  shellcheck
  shellclear
  shfmt
  shot-scraper
  socat
  solargraph
  sox
  spark
  speedread
  speedtest-go
  spotdl
  sptlrx
  sqlite
  sqlite-utils
  sshpass
  stderred
  streamlink
  strip-tags
  surfraw
  t
  tcpdump
  tealdeer
  termdbms
  terminal-colors
  termtosvg
  tesseract4
  testdisk
  textract
  tidal-dl
  tidyp
  tig
  tigervnc
  tmate
  tmpmail
  tmux
  tokei
  translate-shell
  tree
  tree-sitter
  trufflehog
  trurl
  ttok
  ttyd
  twscrape
  units
  universal-ctags
  unixtools.xxd
  unrar
  unrtf
  unzip
  url-parser
  urlencode
  urlscan
  urlwatch
  vhs
  viddy
  vimpager
  vimv-rs
  visidata
  viu
  vivid
  vultr-cli
  w3m
  wdiff
  we-get
  weather
  webtorrent_desktop
  weechat
  wego
  wget
  wget2
  wireshark
  woof
  wrk
  x_x
  xcbuild
  xdg-utils
  xh
  xml2
  xmlstarlet
  xmlto
  xsv
  xurls
  yai
  yarn
  yarn-bash-completion # TODO
  yj
  youtube-viewer
  yq-go
  yt-dlp
  yt-fts
  ytfzf
  zig
  zip
  zprint
] ++ (lib.optionals stdenv.hostPlatform.isDarwin [
  # pagekite # TODO
  # wsc
  # xcode TODO
  asitop
  coreutils
  darwin.apple_sdk.frameworks.Security
  darwin.apple_sdk.frameworks.SystemConfiguration
  darwin.ios-deploy
  darwin.iproute2mac
  darwin.openwith
  darwin.trash
  dockutil
  duti
  findutils
  gawk
  gnugrep
  gnused
  m-cli # TODO
  mas
  mkalias
  pbpaste-html
  pngpaste
  pstree
  psutils
  reattach-to-user-namespace
  skhd
  terminal-notifier
  util-linux
  watch
  watchexec
  xcode-install
  xcodes
  xcpretty
]) ++ lib.optionals stdenv.hostPlatform.isLinux [
  # (zathura.override { useMupdf = true; })
  # conda
  # ioquake3
  # kepka
  # meli
  # powertop
  # rdrview
  # shrinkpdf
  # slack
  # thunar thumbnails
  # vlc_qt5
  (firefox-devedition-bin.override { cfg.enableFXCastBridge = true; cfg.speechSynthesisSupport = true; })
  (latest.firefox-nightly-bin.override { cfg.enableFXCastBridge = true; cfg.speechSynthesisSupport = true; cfg.forceWayland = true; })
  acpi
  alot
  alsa-utils
  amazon-ecs-cli
  appimage-run
  audacity
  audd-cli
  bcompare
  binutils
  bluetooth_battery
  breeze-gtk
  breeze-qt5
  caprine-bin
  chromium
  cog
  crow-translate
  cuff
  detox
  dhcpcd
  docker-client
  docker-compose
  downonspot
  dtrx
  efibootmgr
  electrum
  emacs
  emote
  ethtool
  evemu
  evince
  fast-cli
  fatrace
  fbterm
  ff2mpv
  fswebcam
  fuseiso
  gcolor2
  glib.bin
  gnome-epub-thumbnailer
  google-chrome
  google-chrome-dev
  google-drive-ocamlfuse
  headset
  imv
  inkscape
  inotify-tools
  iotop
  jamesdsp
  kitty
  libguestfs
  libinput
  libnotify
  libreoffice-fresh
  libsForQt5.breeze-gtk
  libsForQt5.kdegraphics-thumbnailers
  linuxPackages.cpupower
  lm_sensors
  lshw
  lxqt.pavucontrol-qt
  macchanger
  mailcheck
  mbidled
  meteor
  mlterm
  monitor
  mplayer
  mupdf
  ncpamixer
  neochat
  neovide
  nethogs
  nheko
  nixos-repl
  nodejs
  nodePackages.peerflix
  ocrmypdf
  ookla-speedtest
  openai-whisper
  orjail
  pamixer
  paps
  pasystray
  pavucontrol
  pciutils
  pdfsandwich
  percollate
  perf-tools
  playerctl
  ponymix
  popcorntime
  pqiv
  progress
  protonvpn-cli
  proxychains
  psmisc
  pulseaudio
  pulseaudio-dlna
  qutebrowser
  reptyr
  rofi-emoji
  rustup
  screenkey
  session-desktop
  siege
  simple-scan
  skypeforlinux
  sleuthkit
  songrec
  speechd
  spotify
  strace
  sublime4
  swappy
  sway-launcher-desktop
  swayr
  swaytools
  sysz
  tdesktop
  tidal-hifi
  torsocks
  trash-cli
  uget
  ulauncher
  ungoogled-chromium
  unoconv
  usbutils
  vieb
  vlc
  vopono
  vscode
  watchlog
  waydroid
  wezterm
  whatsapp-for-linux
  whisper-ctranslate2
  wine
  wirelesstools
  wireplumber
  wl-clipboard-x11
  wlprop
  wlrctl
  wofi
  wrk2
  xdg-user-dirs
  xdragon
  xscreensaver
  xsel
  ydotool
  ytcast
  ytmdesktop
  zathura
]
